import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/build_configuration.dart';
import '../models/build_log_entry.dart';
import '../models/build_target.dart';

class BuildService {
  Stream<BuildEvent> build(BuildConfiguration configuration) async* {
    final selectedTargets = configuration.targets
        .where((target) => target.selected)
        .toList();

    if (selectedTargets.isEmpty) {
      yield const BuildEvent.log(
        BuildLogEntry(
          title: 'No targets selected',
          detail: 'Select at least one installer target before building.',
          state: BuildLogState.warning,
        ),
      );
      return;
    }

    final projectDirectory = Directory(configuration.projectPath);
    final pubspecFile = File(
      _joinPath(configuration.projectPath, 'pubspec.yaml'),
    );
    if (!projectDirectory.existsSync() || !pubspecFile.existsSync()) {
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Invalid Flutter project',
          detail: '${configuration.projectPath} does not contain pubspec.yaml.',
          state: BuildLogState.warning,
        ),
      );
      return;
    }

    final outputDirectory = Directory(
      configuration.outputPath ??
          _joinPath(configuration.projectPath, 'build/pack_foundry'),
    );
    final linuxTargets = selectedTargets
        .where((target) => target.platform == 'Linux')
        .toList();

    try {
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Analyzing project',
          detail: configuration.projectPath,
          state: BuildLogState.running,
        ),
      );

      await outputDirectory.create(recursive: true);
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Output folder is ready',
          detail: outputDirectory.path,
          state: BuildLogState.success,
        ),
      );

      for (final target in selectedTargets.where(
        (target) => target.platform != 'Linux',
      )) {
        yield BuildEvent.log(
          BuildLogEntry(
            title: '${target.platform} ${target.artifact} skipped',
            detail:
                'This prototype currently builds Linux targets on Linux hosts.',
            state: BuildLogState.warning,
          ),
        );
      }

      if (linuxTargets.isEmpty) {
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'No Linux targets selected',
            detail:
                'Select AppImage, deb, rpm or tar.gz to build on this host.',
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      yield const BuildEvent.progress(10);
      yield BuildEvent.log(
        const BuildLogEntry(
          title: 'Cleaning Linux build cache',
          detail:
              'Removing build/linux to avoid stale CMakeCache paths from moved projects or containers.',
          state: BuildLogState.running,
        ),
      );
      await _deleteLinuxBuildCache(projectDirectory);

      yield const BuildEvent.progress(15);
      yield const BuildEvent.log(
        BuildLogEntry(
          title: 'Running Flutter release build',
          detail: 'flutter build linux --release',
          state: BuildLogState.running,
        ),
      );

      final buildResult = await _runFlutterBuild(configuration.projectPath);
      if (buildResult.exitCode != 0) {
        yield BuildEvent.log(
          BuildLogEntry(
            title: 'Flutter build failed',
            detail: _shortProcessOutput(buildResult),
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      yield const BuildEvent.progress(55);
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Flutter build completed',
          detail: _shortProcessOutput(buildResult),
          state: BuildLogState.success,
        ),
      );

      final bundleDirectory = await _findLinuxBundle(projectDirectory);
      if (bundleDirectory == null) {
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'Linux bundle not found',
            detail:
                'Expected build/linux/<arch>/release/bundle after Flutter build.',
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      yield* _exportLinuxTargets(
        targets: linuxTargets,
        bundleDirectory: bundleDirectory,
        outputDirectory: outputDirectory,
        appName: configuration.appName,
      );

      yield const BuildEvent.progress(100);
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Build completed',
          detail: 'Artifacts were written to ${outputDirectory.path}.',
          state: BuildLogState.success,
        ),
      );
    } on ProcessException catch (error) {
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Could not run Flutter',
          detail: '${error.message}. Make sure flutter is available in PATH.',
          state: BuildLogState.warning,
        ),
      );
    } on FileSystemException catch (error) {
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'File system error',
          detail: error.message,
          state: BuildLogState.warning,
        ),
      );
    }
  }

  Stream<BuildEvent> _exportLinuxTargets({
    required List<BuildTarget> targets,
    required Directory bundleDirectory,
    required Directory outputDirectory,
    required String appName,
  }) async* {
    final appSlug = _slugify(appName);
    for (var index = 0; index < targets.length; index++) {
      final target = targets[index];
      final artifactSlug = _slugify(target.artifact);

      if (target.artifact == 'tar.gz bundle') {
        final archivePath = _joinPath(
          outputDirectory.path,
          '$appSlug-linux.tar.gz',
        );
        final archiveResult = await Process.run(
          'tar',
          [
            '-czf',
            archivePath,
            '-C',
            bundleDirectory.parent.path,
            _basename(bundleDirectory.path),
          ],
          runInShell: true,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );

        if (archiveResult.exitCode == 0) {
          yield BuildEvent.log(
            BuildLogEntry(
              title: 'Created Linux tar.gz',
              detail: archivePath,
              state: BuildLogState.success,
            ),
          );
        } else {
          yield BuildEvent.log(
            BuildLogEntry(
              title: 'tar.gz packaging failed',
              detail: _shortProcessOutput(archiveResult),
              state: BuildLogState.warning,
            ),
          );
        }
      } else {
        final fallbackDirectory = Directory(
          _joinPath(
            outputDirectory.path,
            '$appSlug-linux-$artifactSlug-bundle',
          ),
        );
        await _copyDirectory(bundleDirectory, fallbackDirectory);
        yield BuildEvent.log(
          BuildLogEntry(
            title: '${target.artifact} packager is not wired yet',
            detail:
                'Copied the release bundle fallback to ${fallbackDirectory.path}.',
            state: BuildLogState.warning,
          ),
        );
      }

      yield BuildEvent.progress(
        55 + (((index + 1) / targets.length) * 40).round(),
      );
    }
  }

  Future<ProcessResult> _runFlutterBuild(String projectPath) async {
    final candidates = [
      'flutter',
      if (File('/home/axawys/development/flutter/bin/flutter').existsSync())
        '/home/axawys/development/flutter/bin/flutter',
    ];

    ProcessException? lastError;
    for (final executable in candidates) {
      try {
        return await Process.run(
          executable,
          ['build', 'linux', '--release'],
          workingDirectory: projectPath,
          runInShell: true,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
      } on ProcessException catch (error) {
        lastError = error;
      }
    }

    throw lastError ??
        const ProcessException('flutter', [
          'build',
          'linux',
          '--release',
        ], 'Flutter executable was not found.');
  }

  Future<void> _deleteLinuxBuildCache(Directory projectDirectory) async {
    final linuxBuildDirectory = Directory(
      _joinPath(projectDirectory.path, 'build/linux'),
    );
    if (linuxBuildDirectory.existsSync()) {
      await linuxBuildDirectory.delete(recursive: true);
    }
  }

  Future<Directory?> _findLinuxBundle(Directory projectDirectory) async {
    final linuxBuildDirectory = Directory(
      _joinPath(projectDirectory.path, 'build/linux'),
    );
    if (!linuxBuildDirectory.existsSync()) {
      return null;
    }

    await for (final entity in linuxBuildDirectory.list(recursive: true)) {
      if (entity is Directory &&
          _basename(entity.path) == 'bundle' &&
          entity.path.contains(
            '${Platform.pathSeparator}release${Platform.pathSeparator}',
          )) {
        return entity;
      }
    }

    return null;
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (destination.existsSync()) {
      await destination.delete(recursive: true);
    }
    await destination.create(recursive: true);

    await for (final entity in source.list(recursive: true)) {
      final relativePath = entity.path.substring(source.path.length + 1);
      final newPath = _joinPath(destination.path, relativePath);

      if (entity is Directory) {
        await Directory(newPath).create(recursive: true);
      } else if (entity is File) {
        await File(newPath).parent.create(recursive: true);
        await File(entity.path).copy(newPath);
      }
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

    const maxLength = 500;
    if (output.length <= maxLength) {
      return output;
    }

    return output.substring(output.length - maxLength);
  }

  String _slugify(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'flutter-app' : slug;
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

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final trimmed = normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
    return trimmed.substring(trimmed.lastIndexOf('/') + 1);
  }
}

class BuildEvent {
  const BuildEvent.log(BuildLogEntry this.logEntry) : progress = null;

  const BuildEvent.progress(int this.progress) : logEntry = null;

  final BuildLogEntry? logEntry;
  final int? progress;
}
