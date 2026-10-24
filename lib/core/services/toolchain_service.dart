import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/tool_status.dart';
import 'flutter_locator.dart';

/// Reports progress of a single install step. [fraction] is 0-1, or null when
/// the running tool does not expose measurable progress.
typedef ToolProgressCallback = void Function(double? fraction, String detail);

class ToolchainService {
  static const _appImageToolBaseUrl =
      'https://github.com/AppImage/AppImageKit/releases/download/continuous';
  static const _androidCommandLineToolsUrl =
      'https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip';
  static const _cancelledMessage = 'Installation was cancelled.';
  static final _gitPhasePattern = RegExp(
    r'(Counting objects|Compressing objects|Receiving objects|Resolving deltas|Updating files):\s+(\d+)%',
  );
  static final _percentPattern = RegExp(r'(\d+(?:\.\d+)?)\s*%');
  static final _curlMeterPattern = RegExp(
    r'^(\d{1,3})\s+[\d.]+[kMG]?\s+\d{1,3}\s+[\d.]+[kMG]?\s',
  );

  Process? _activeProcess;
  HttpClient? _activeHttpClient;
  var _cancelRequested = false;

  bool get isCancelRequested => _cancelRequested;

  /// Clears a previous cancellation so a new installation can start.
  void beginInstall() {
    _cancelRequested = false;
  }

  /// Stops the running download or process of the current installation.
  /// Privileged package manager runs are left alone because pkexec children
  /// cannot be signalled by the user and an interrupted transaction is unsafe.
  Future<void> cancelActiveInstall() async {
    _cancelRequested = true;
    _activeProcess?.kill(ProcessSignal.sigterm);
    _activeHttpClient?.close(force: true);
  }

  File get managedFlutterExecutable => FlutterLocator().managedExecutable;

  Directory get managedAndroidSdkDirectory => Directory(
    _joinPath(_userDataDirectory().path, 'pack_foundry/android-sdk'),
  );

  File get managedSdkManager => File(
    _joinPath(
      managedAndroidSdkDirectory.path,
      'cmdline-tools/latest/bin/sdkmanager',
    ),
  );

  Future<ToolAvailability> commandAvailability(
    String executable,
    List<String> arguments,
  ) async {
    try {
      final result = await Process.run(
        executable,
        arguments,
        runInShell: true,
      ).timeout(const Duration(seconds: 4));
      return result.exitCode == 0
          ? ToolAvailability.installed
          : ToolAvailability.missing;
    } on Object {
      return ToolAvailability.missing;
    }
  }

  /// Checks the same executable builds will use, so the toolchain tab never
  /// reports Flutter as installed while builds cannot start it.
  Future<ToolAvailability> flutterAvailability() async {
    final flutter = FlutterLocator().find();
    if (flutter == null) {
      return ToolAvailability.missing;
    }
    return commandAvailability(flutter.path, ['--version']);
  }

  Future<ToolAvailability> appImageToolAvailability() async {
    final systemStatus = await commandAvailability('appimagetool', [
      '--version',
    ]);
    if (systemStatus == ToolAvailability.installed) {
      return systemStatus;
    }
    final cachedTool = _cachedAppImageToolFile();
    return cachedTool.existsSync()
        ? ToolAvailability.installed
        : ToolAvailability.missing;
  }

  Future<ToolAvailability> androidSdkAvailability() async {
    final sdkRoot =
        Platform.environment['ANDROID_HOME'] ??
        Platform.environment['ANDROID_SDK_ROOT'];
    if (sdkRoot != null && sdkRoot.isNotEmpty) {
      final platformsDirectory = Directory(_joinPath(sdkRoot, 'platforms'));
      if (platformsDirectory.existsSync()) {
        return ToolAvailability.installed;
      }
    }

    final systemStatus = await commandAvailability('sdkmanager', ['--version']);
    if (systemStatus == ToolAvailability.installed) {
      return systemStatus;
    }
    final managedPlatforms = Directory(
      _joinPath(managedAndroidSdkDirectory.path, 'platforms'),
    );
    if (managedSdkManager.existsSync() && managedPlatforms.existsSync()) {
      return commandAvailability(managedSdkManager.path, ['--version']);
    }
    return ToolAvailability.missing;
  }

  Future<ToolInstallResult> installSystemPackages({
    required Map<String, List<String>> packagesByManager,
    ToolProgressCallback? onProgress,
  }) async {
    final manager = await _detectPackageManager();
    if (manager == null) {
      return const ToolInstallResult.failure(
        'Could not find a supported package manager.',
      );
    }

    final packages = packagesByManager[manager.executable];
    if (packages == null || packages.isEmpty) {
      return ToolInstallResult.failure(
        'No install recipe is available for ${manager.executable}.',
      );
    }

    final pkexec = await _findExecutable('pkexec');
    if (pkexec == null) {
      return const ToolInstallResult.failure(
        'pkexec was not found. Install polkit or run package installation manually.',
      );
    }

    try {
      onProgress?.call(null, 'Waiting for administrator authorization.');
      final result = await _runStreamed(
        pkexec.path,
        [...manager.installArguments, ...packages],
        trackForCancel: false,
        onLine: (line) => onProgress?.call(null, line),
      );
      if (result.exitCode == 0) {
        return ToolInstallResult.success(
          'Installed packages: ${packages.join(', ')}.',
        );
      }
      return ToolInstallResult.failure(result.shortOutput);
    } on ProcessException catch (error) {
      return ToolInstallResult.failure(error.message);
    }
  }

  Future<ToolInstallResult> enableDockerService() async {
    final systemctl = await _findExecutable('systemctl');
    if (systemctl == null) {
      return const ToolInstallResult.success(
        'systemctl was not found; skipping Docker service activation.',
      );
    }
    final pkexec = await _findExecutable('pkexec');
    if (pkexec == null) {
      return const ToolInstallResult.failure(
        'pkexec was not found. Docker was installed, but the service could not be enabled automatically.',
      );
    }

    final result = await Process.run(
      pkexec.path,
      [systemctl.path, 'enable', '--now', 'docker'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode == 0) {
      return const ToolInstallResult.success('Docker service is enabled.');
    }
    return ToolInstallResult.failure(_shortProcessOutput(result));
  }

  Future<ToolInstallResult> addCurrentUserToDockerGroup() async {
    final user = Platform.environment['USER'];
    if (user == null || user.isEmpty) {
      return const ToolInstallResult.success(
        'Could not detect current user; skipping docker group setup.',
      );
    }
    final groupsResult = await Process.run(
      'id',
      ['-nG', user],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (groupsResult.exitCode == 0 &&
        groupsResult.stdout
            .toString()
            .split(RegExp(r'\s+'))
            .contains('docker')) {
      return const ToolInstallResult.success(
        'Current user is already in docker group.',
      );
    }

    final pkexec = await _findExecutable('pkexec');
    if (pkexec == null) {
      return const ToolInstallResult.failure(
        'pkexec was not found. Docker is installed, but user group setup could not be completed.',
      );
    }
    final result = await Process.run(
      pkexec.path,
      ['usermod', '-aG', 'docker', user],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode == 0) {
      return const ToolInstallResult.success(
        'Current user was added to docker group. Log out and log back in before using Docker without sudo.',
      );
    }
    return ToolInstallResult.failure(_shortProcessOutput(result));
  }

  Future<ToolInstallResult> installAppImageTool({
    ToolProgressCallback? onProgress,
  }) async {
    final destination = _cachedAppImageToolFile();
    try {
      await destination.parent.create(recursive: true);
      await _downloadFile(
        Uri.parse(
          '$_appImageToolBaseUrl/appimagetool-${_appImageArchitecture()}.AppImage',
        ),
        destination,
        onProgress: onProgress,
      );
      await _makeExecutable(destination);
      return ToolInstallResult.success(
        'Downloaded appimagetool to ${destination.path}.',
      );
    } on Object catch (error) {
      if (destination.existsSync()) {
        await destination.delete();
      }
      return ToolInstallResult.failure(
        _cancelRequested ? _cancelledMessage : error.toString(),
      );
    }
  }

  Future<ToolInstallResult> installFlutterSdk({
    ToolProgressCallback? onProgress,
  }) async {
    try {
      final flutterExecutable = managedFlutterExecutable;
      final sdkDirectory = flutterExecutable.parent.parent;
      if (flutterExecutable.existsSync()) {
        onProgress?.call(null, 'Updating Flutter SDK.');
        final upgradeResult = await _runStreamed('git', [
          '-C',
          sdkDirectory.path,
          'pull',
          '--ff-only',
          '--progress',
        ], onLine: (line) => onProgress?.call(null, line));
        if (_cancelRequested) {
          return const ToolInstallResult.failure(_cancelledMessage);
        }
        if (upgradeResult.exitCode != 0) {
          return ToolInstallResult.failure(upgradeResult.shortOutput);
        }
      } else {
        // A directory without the flutter executable is a leftover from an
        // interrupted clone; git refuses to clone into it.
        if (sdkDirectory.existsSync()) {
          await sdkDirectory.delete(recursive: true);
        }
        await sdkDirectory.parent.create(recursive: true);
        onProgress?.call(0, 'Cloning Flutter SDK (stable).');
        final cloneResult = await _runStreamed(
          'git',
          [
            'clone',
            '--progress',
            '--depth',
            '1',
            '--branch',
            'stable',
            'https://github.com/flutter/flutter.git',
            sdkDirectory.path,
          ],
          onLine: (line) {
            final fraction = _gitCloneFraction(line);
            if (fraction != null) {
              onProgress?.call(fraction, line);
            }
          },
        );
        if (_cancelRequested || cloneResult.exitCode != 0) {
          if (sdkDirectory.existsSync()) {
            await sdkDirectory.delete(recursive: true);
          }
          return ToolInstallResult.failure(
            _cancelRequested ? _cancelledMessage : cloneResult.shortOutput,
          );
        }
      }

      // The first run downloads the Dart SDK and builds the flutter tool.
      onProgress?.call(0.7, 'Downloading Dart SDK and building Flutter tool.');
      final versionResult = await _runStreamed(
        flutterExecutable.path,
        ['--version'],
        onLine: (line) {
          final percent = _downloadPercent(line);
          if (percent != null) {
            onProgress?.call(0.7 + (percent / 100).clamp(0.0, 1.0) * 0.2, line);
          } else {
            onProgress?.call(null, line);
          }
        },
      );
      if (_cancelRequested) {
        return const ToolInstallResult.failure(_cancelledMessage);
      }
      if (versionResult.exitCode != 0) {
        return ToolInstallResult.failure(versionResult.shortOutput);
      }
      onProgress?.call(1, 'Flutter SDK is ready.');
      return ToolInstallResult.success(
        'Flutter SDK is ready at ${sdkDirectory.path}.',
      );
    } on Object catch (error) {
      return ToolInstallResult.failure(
        _cancelRequested ? _cancelledMessage : error.toString(),
      );
    }
  }

  /// Reads a download percentage from a progress line: either an explicit
  /// "45%" or the first column of curl's default progress meter, which the
  /// flutter tool uses for the Dart SDK download.
  double? _downloadPercent(String line) {
    final explicit = _percentPattern.firstMatch(line);
    if (explicit != null) {
      return double.tryParse(explicit.group(1)!);
    }
    final curlMeter = _curlMeterPattern.firstMatch(line);
    if (curlMeter != null) {
      return double.tryParse(curlMeter.group(1)!);
    }
    return null;
  }

  /// Maps git clone phases onto the clone part (0-0.7) of the Flutter step.
  double? _gitCloneFraction(String line) {
    final match = _gitPhasePattern.firstMatch(line);
    if (match == null) {
      return null;
    }
    final percent = int.parse(match.group(2)!) / 100;
    final (start, end) = switch (match.group(1)) {
      'Counting objects' => (0.0, 0.01),
      'Compressing objects' => (0.01, 0.03),
      'Receiving objects' => (0.03, 0.55),
      'Resolving deltas' => (0.55, 0.62),
      _ => (0.62, 0.7),
    };
    return start + (end - start) * percent;
  }

  Future<ToolInstallResult> installAndroidSdk({
    ToolProgressCallback? onProgress,
  }) async {
    Directory? tempDirectory;
    try {
      final sdkRoot = managedAndroidSdkDirectory;
      final sdkManager = managedSdkManager;
      if (!sdkManager.existsSync()) {
        tempDirectory = await Directory.systemTemp.createTemp(
          'pack_foundry_android_tools_',
        );
        final zipFile = File(
          _joinPath(tempDirectory.path, 'cmdline-tools.zip'),
        );
        await _downloadFile(
          Uri.parse(_androidCommandLineToolsUrl),
          zipFile,
          onProgress: (fraction, detail) => onProgress?.call(
            fraction == null ? null : fraction * 0.25,
            'Android command line tools: $detail',
          ),
        );
        final unzip = await _findExecutable('unzip');
        if (unzip == null) {
          return const ToolInstallResult.failure(
            'unzip was not found. Install unzip and try again.',
          );
        }
        final extractDirectory = Directory(
          _joinPath(tempDirectory.path, 'extract'),
        );
        await extractDirectory.create(recursive: true);
        onProgress?.call(0.25, 'Extracting Android command line tools.');
        final unzipResult = await Process.run(
          unzip.path,
          ['-q', zipFile.path, '-d', extractDirectory.path],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        if (unzipResult.exitCode != 0) {
          return ToolInstallResult.failure(_shortProcessOutput(unzipResult));
        }

        final latestDirectory = Directory(
          _joinPath(sdkRoot.path, 'cmdline-tools/latest'),
        );
        if (latestDirectory.existsSync()) {
          await latestDirectory.delete(recursive: true);
        }
        await latestDirectory.parent.create(recursive: true);
        final extractedTools = Directory(
          _joinPath(extractDirectory.path, 'cmdline-tools'),
        );
        await _copyDirectory(extractedTools, latestDirectory);
      }

      if (_cancelRequested) {
        return const ToolInstallResult.failure(_cancelledMessage);
      }
      onProgress?.call(0.3, 'Accepting Android SDK licenses.');
      final licenseResult = await _acceptAndroidLicenses(sdkManager, sdkRoot);
      if (!licenseResult.success) {
        return licenseResult;
      }

      const packages = [
        'cmdline-tools;latest',
        'platform-tools',
        'platforms;android-35',
        'build-tools;35.0.0',
      ];
      onProgress?.call(0.32, 'Installing Android SDK packages.');
      final downloads = <String>{};
      final installResult = await _runSdkManagerWithYes(
        sdkManager,
        sdkRoot,
        packages,
        onLine: (line) {
          // sdkmanager prints "[====   ] 45% Downloading x.zip..." per package.
          final downloading = RegExp(r'Downloading (\S+)').firstMatch(line);
          if (downloading != null) {
            downloads.add(downloading.group(1)!);
          }
          final match = _percentPattern.firstMatch(line);
          if (match == null) {
            onProgress?.call(null, line);
            return;
          }
          final percent = (double.tryParse(match.group(1)!) ?? 0) / 100;
          final finished = downloads.isEmpty ? 0 : downloads.length - 1;
          final packagesFraction = ((finished + percent) / packages.length)
              .clamp(0.0, 1.0);
          onProgress?.call(0.32 + packagesFraction * 0.68, line);
        },
      );
      if (!installResult.success) {
        return installResult;
      }
      onProgress?.call(1, 'Android SDK is ready.');

      return ToolInstallResult.success(
        'Android SDK is ready at ${sdkRoot.path}.',
      );
    } on Object catch (error) {
      return ToolInstallResult.failure(
        _cancelRequested ? _cancelledMessage : error.toString(),
      );
    } finally {
      if (tempDirectory != null && tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    }
  }

  Future<bool> anyCommandAvailable(List<CommandCheck> checks) async {
    for (final check in checks) {
      final status = await commandAvailability(
        check.executable,
        check.arguments,
      );
      if (status == ToolAvailability.installed) {
        return true;
      }
    }
    return false;
  }

  Future<bool> allCommandsAvailable(List<CommandCheck> checks) async {
    for (final check in checks) {
      final status = await commandAvailability(
        check.executable,
        check.arguments,
      );
      if (status != ToolAvailability.installed) {
        return false;
      }
    }
    return true;
  }

  Future<_PackageManager?> _detectPackageManager() async {
    for (final manager in _packageManagers) {
      if (await _findExecutable(manager.executable) != null) {
        return manager;
      }
    }
    return null;
  }

  Future<File?> _findExecutable(String executableName) async {
    final pathVariable = Platform.environment['PATH'];
    if (pathVariable == null || pathVariable.isEmpty) {
      return null;
    }

    for (final directory in pathVariable.split(':')) {
      final candidate = File(_joinPath(directory, executableName));
      if (candidate.existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  Future<void> _downloadFile(
    Uri uri,
    File destination, {
    ToolProgressCallback? onProgress,
  }) async {
    final client = HttpClient();
    _activeHttpClient = client;
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Download failed with HTTP ${response.statusCode}: $uri',
        );
      }

      final total = response.contentLength;
      var received = 0;
      var lastReport = DateTime.fromMillisecondsSinceEpoch(0);
      final sink = destination.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          final now = DateTime.now();
          if (onProgress != null &&
              now.difference(lastReport) >= const Duration(milliseconds: 200)) {
            lastReport = now;
            final size = total > 0
                ? '${_formatBytes(received)} / ${_formatBytes(total)}'
                : _formatBytes(received);
            onProgress(total > 0 ? received / total : null, size);
          }
        }
      } finally {
        await sink.close();
      }
      if (_cancelRequested) {
        throw const HttpException(_cancelledMessage);
      }
      onProgress?.call(1, _formatBytes(received));
    } finally {
      if (identical(_activeHttpClient, client)) {
        _activeHttpClient = null;
      }
      client.close(force: true);
    }
  }

  String _formatBytes(int bytes) {
    const megabyte = 1024 * 1024;
    if (bytes >= megabyte) {
      return '${(bytes / megabyte).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  /// Runs a process and reports each output line as it arrives. Progress bars
  /// redraw with carriage returns, so both \r and \n end a line.
  Future<_StreamedResult> _runStreamed(
    String executable,
    List<String> arguments, {
    void Function(String line)? onLine,
    List<String> stdinLines = const [],
    bool trackForCancel = true,
  }) async {
    final process = await Process.start(executable, arguments);
    if (trackForCancel) {
      _activeProcess = process;
    }
    try {
      for (final line in stdinLines) {
        process.stdin.writeln(line);
      }
      await process.stdin.close();

      final tail = <String>[];
      void handle(String line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          return;
        }
        tail.add(trimmed);
        if (tail.length > 40) {
          tail.removeAt(0);
        }
        onLine?.call(trimmed);
      }

      await Future.wait([
        _splitLines(process.stdout).forEach(handle),
        _splitLines(process.stderr).forEach(handle),
      ]);
      final exitCode = await process.exitCode;
      return _StreamedResult(exitCode, tail);
    } finally {
      if (identical(_activeProcess, process)) {
        _activeProcess = null;
      }
    }
  }

  Stream<String> _splitLines(Stream<List<int>> stream) async* {
    var buffer = '';
    await for (final chunk in stream.transform(
      const Utf8Decoder(allowMalformed: true),
    )) {
      buffer += chunk;
      final parts = buffer.split(RegExp(r'[\r\n]'));
      buffer = parts.removeLast();
      yield* Stream.fromIterable(parts);
    }
    if (buffer.isNotEmpty) {
      yield buffer;
    }
  }

  Future<void> _makeExecutable(File file) async {
    if (!Platform.isLinux && !Platform.isMacOS) {
      return;
    }
    await Process.run('chmod', ['755', file.path]);
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      final relativePath = entity.path.substring(source.path.length + 1);
      final newPath = _joinPath(destination.path, relativePath);
      if (entity is Directory) {
        await Directory(newPath).create(recursive: true);
      } else if (entity is File) {
        await File(newPath).parent.create(recursive: true);
        await entity.copy(newPath);
      } else if (entity is Link) {
        await Link(newPath).create(await entity.target(), recursive: true);
      }
    }
  }

  File _cachedAppImageToolFile() {
    return File(
      _joinPath(
        _joinPath(_userCacheDirectory().path, 'pack_foundry/tools'),
        'appimagetool-${_appImageArchitecture()}.AppImage',
      ),
    );
  }

  Directory _userCacheDirectory() {
    final xdgCacheHome = Platform.environment['XDG_CACHE_HOME'];
    if (xdgCacheHome != null && xdgCacheHome.isNotEmpty) {
      return Directory(xdgCacheHome);
    }

    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return Directory(_joinPath(home, '.cache'));
    }

    return Directory.systemTemp;
  }

  Directory _userDataDirectory() {
    final xdgDataHome = Platform.environment['XDG_DATA_HOME'];
    if (xdgDataHome != null && xdgDataHome.isNotEmpty) {
      return Directory(xdgDataHome);
    }

    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return Directory(_joinPath(home, '.local/share'));
    }

    return Directory.systemTemp;
  }

  Future<ToolInstallResult> _acceptAndroidLicenses(
    File sdkManager,
    Directory sdkRoot,
  ) async {
    return _runSdkManagerWithYes(sdkManager, sdkRoot, const ['--licenses']);
  }

  Future<ToolInstallResult> _runSdkManagerWithYes(
    File sdkManager,
    Directory sdkRoot,
    List<String> arguments, {
    void Function(String line)? onLine,
  }) async {
    final result = await _runStreamed(
      sdkManager.path,
      ['--sdk_root=${sdkRoot.path}', ...arguments],
      stdinLines: List.filled(80, 'y'),
      onLine: onLine,
    );
    if (_cancelRequested) {
      return const ToolInstallResult.failure(_cancelledMessage);
    }
    if (result.exitCode == 0) {
      return ToolInstallResult.success(
        'sdkmanager ${arguments.join(' ')} completed.',
      );
    }
    return ToolInstallResult.failure(result.shortOutput);
  }

  String _appImageArchitecture() {
    try {
      final architecture = Process.runSync('uname', [
        '-m',
      ]).stdout.toString().trim();
      return switch (architecture) {
        'aarch64' => 'aarch64',
        'arm64' => 'aarch64',
        _ => 'x86_64',
      };
    } on Object {
      return 'x86_64';
    }
  }

  String _shortProcessOutput(ProcessResult result) {
    final output = [
      result.stdout.toString().trim(),
      result.stderr.toString().trim(),
    ].where((part) => part.isNotEmpty).join('\n');

    if (output.isEmpty) {
      return 'Process exited with code ${result.exitCode}.';
    }

    const maxLength = 700;
    if (output.length <= maxLength) {
      return output;
    }

    return output.substring(output.length - maxLength);
  }

  String _joinPath(String first, String second) {
    if (second.isEmpty) {
      return first;
    }
    final normalizedSecond = second.replaceAll('/', Platform.pathSeparator);
    if (first.endsWith(Platform.pathSeparator)) {
      return '$first$normalizedSecond';
    }
    return '$first${Platform.pathSeparator}$normalizedSecond';
  }
}

class CommandCheck {
  const CommandCheck(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
}

class _StreamedResult {
  const _StreamedResult(this.exitCode, this.outputTail);

  final int exitCode;
  final List<String> outputTail;

  String get shortOutput {
    if (outputTail.isEmpty) {
      return 'Process exited with code $exitCode.';
    }
    final output = outputTail.join('\n');
    const maxLength = 700;
    if (output.length <= maxLength) {
      return output;
    }
    return output.substring(output.length - maxLength);
  }
}

class ToolInstallResult {
  const ToolInstallResult.success(this.message) : success = true;

  const ToolInstallResult.failure(this.message) : success = false;

  final bool success;
  final String message;
}

class _PackageManager {
  const _PackageManager({
    required this.executable,
    required this.installArguments,
  });

  final String executable;
  final List<String> installArguments;
}

const _packageManagers = [
  _PackageManager(
    executable: 'dnf',
    installArguments: ['dnf', 'install', '-y'],
  ),
  _PackageManager(
    executable: 'apt-get',
    installArguments: ['apt-get', 'install', '-y'],
  ),
  _PackageManager(
    executable: 'zypper',
    installArguments: ['zypper', '--non-interactive', 'install'],
  ),
  _PackageManager(
    executable: 'pacman',
    installArguments: ['pacman', '-S', '--needed', '--noconfirm'],
  ),
];
