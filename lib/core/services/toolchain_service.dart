import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/tool_status.dart';

class ToolchainService {
  static const _appImageToolBaseUrl =
      'https://github.com/AppImage/AppImageKit/releases/download/continuous';
  static const _androidCommandLineToolsUrl =
      'https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip';

  File get managedFlutterExecutable => File(
    _joinPath(
      _joinPath(_userDataDirectory().path, 'pack_foundry/flutter/bin'),
      'flutter',
    ),
  );

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

  Future<ToolAvailability> flutterAvailability() async {
    final systemStatus = await commandAvailability('flutter', ['--version']);
    if (systemStatus == ToolAvailability.installed) {
      return systemStatus;
    }
    if (!managedFlutterExecutable.existsSync()) {
      return ToolAvailability.missing;
    }
    return commandAvailability(managedFlutterExecutable.path, ['--version']);
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
      final result = await Process.run(
        pkexec.path,
        [...manager.installArguments, ...packages],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (result.exitCode == 0) {
        return ToolInstallResult.success(
          'Installed packages: ${packages.join(', ')}.',
        );
      }
      return ToolInstallResult.failure(_shortProcessOutput(result));
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

  Future<ToolInstallResult> installAppImageTool() async {
    try {
      final destination = _cachedAppImageToolFile();
      await destination.parent.create(recursive: true);
      await _downloadFile(
        Uri.parse(
          '$_appImageToolBaseUrl/appimagetool-${_appImageArchitecture()}.AppImage',
        ),
        destination,
      );
      await _makeExecutable(destination);
      return ToolInstallResult.success(
        'Downloaded appimagetool to ${destination.path}.',
      );
    } on Object catch (error) {
      return ToolInstallResult.failure(error.toString());
    }
  }

  Future<ToolInstallResult> installFlutterSdk() async {
    try {
      final flutterExecutable = managedFlutterExecutable;
      if (flutterExecutable.existsSync()) {
        final upgradeResult = await Process.run(
          'git',
          ['-C', flutterExecutable.parent.parent.path, 'pull', '--ff-only'],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        if (upgradeResult.exitCode != 0) {
          return ToolInstallResult.failure(_shortProcessOutput(upgradeResult));
        }
      } else {
        await flutterExecutable.parent.parent.parent.create(recursive: true);
        final cloneResult = await Process.run(
          'git',
          [
            'clone',
            '--depth',
            '1',
            '--branch',
            'stable',
            'https://github.com/flutter/flutter.git',
            flutterExecutable.parent.parent.path,
          ],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        if (cloneResult.exitCode != 0) {
          return ToolInstallResult.failure(_shortProcessOutput(cloneResult));
        }
      }

      final doctorResult = await Process.run(
        flutterExecutable.path,
        ['--version'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (doctorResult.exitCode != 0) {
        return ToolInstallResult.failure(_shortProcessOutput(doctorResult));
      }
      return ToolInstallResult.success(
        'Flutter SDK is ready at ${flutterExecutable.parent.parent.path}.',
      );
    } on Object catch (error) {
      return ToolInstallResult.failure(error.toString());
    }
  }

  Future<ToolInstallResult> installAndroidSdk() async {
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
        await _downloadFile(Uri.parse(_androidCommandLineToolsUrl), zipFile);
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

      final licenseResult = await _acceptAndroidLicenses(sdkManager, sdkRoot);
      if (!licenseResult.success) {
        return licenseResult;
      }

      final installResult =
          await _runSdkManagerWithYes(sdkManager, sdkRoot, const [
            'cmdline-tools;latest',
            'platform-tools',
            'platforms;android-35',
            'build-tools;35.0.0',
          ]);
      if (!installResult.success) {
        return installResult;
      }

      return ToolInstallResult.success(
        'Android SDK is ready at ${sdkRoot.path}.',
      );
    } on Object catch (error) {
      return ToolInstallResult.failure(error.toString());
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

  Future<void> _downloadFile(Uri uri, File destination) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Download failed with HTTP ${response.statusCode}: $uri',
        );
      }

      final sink = destination.openWrite();
      await response.pipe(sink);
      await sink.close();
    } finally {
      client.close(force: true);
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
    List<String> arguments,
  ) async {
    final process = await Process.start(sdkManager.path, [
      '--sdk_root=${sdkRoot.path}',
      ...arguments,
    ], runInShell: true);
    for (var index = 0; index < 80; index++) {
      process.stdin.writeln('y');
    }
    await process.stdin.close();
    final stdout = await utf8.decodeStream(process.stdout);
    final stderr = await utf8.decodeStream(process.stderr);
    final exitCode = await process.exitCode;
    if (exitCode == 0) {
      return ToolInstallResult.success(
        'sdkmanager ${arguments.join(' ')} completed.',
      );
    }
    return ToolInstallResult.failure(
      _shortTextOutput(stdout: stdout, stderr: stderr, exitCode: exitCode),
    );
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

  String _shortTextOutput({
    required String stdout,
    required String stderr,
    required int exitCode,
  }) {
    final output = [
      stdout.trim(),
      stderr.trim(),
    ].where((part) => part.isNotEmpty).join('\n');
    if (output.isEmpty) {
      return 'Process exited with code $exitCode.';
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
