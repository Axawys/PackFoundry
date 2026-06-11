import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/tool_status.dart';

class ToolchainService {
  static const _appImageToolBaseUrl =
      'https://github.com/AppImage/AppImageKit/releases/download/continuous';

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
