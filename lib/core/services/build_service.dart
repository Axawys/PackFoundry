import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/build_configuration.dart';
import '../models/builder_environment.dart';
import '../models/build_log_entry.dart';
import '../models/build_target.dart';
import 'builder_environment_service.dart';

class BuildService {
  static const _stepProject = 'project';
  static const _stepWorkspace = 'workspace';
  static const _stepLocalBuild = 'local-build';
  static const _stepBundle = 'bundle';
  static const _stepRpm = 'rpm';
  static const _stepAppImage = 'appimage';
  static const _stepTarGz = 'targz';
  static const _stepDebContainer = 'deb-container';
  static const _stepDebBuild = 'deb-build';
  static const _stepDebPackage = 'deb-package';
  static const _stepWindowsKit = 'windows-kit';
  static const _stepAndroidBuild = 'android-build';
  static const _stepApkExport = 'apk-export';
  static const _stepSummary = 'summary';
  static const _stepCleanup = 'cleanup';

  static const _appImageToolBaseUrl =
      'https://github.com/AppImage/AppImageKit/releases/download/continuous';

  final _builderEnvironmentService = BuilderEnvironmentService();

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
    final windowsTargets = selectedTargets
        .where((target) => target.platform == 'Windows')
        .toList();
    final androidTargets = selectedTargets
        .where((target) => target.platform == 'Android')
        .toList();

    yield BuildEvent.roadmapPlan(createRoadmapPlan(selectedTargets));

    Directory? buildTempDirectory;
    var dockerTouchedWorkspace = false;

    try {
      yield const BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepProject,
          state: BuildRoadmapStepState.running,
          progress: 25,
          detail: 'Checking project folder and pubspec.yaml.',
        ),
      );
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Analyzing project',
          detail: configuration.projectPath,
          state: BuildLogState.running,
        ),
      );

      await outputDirectory.create(recursive: true);
      yield const BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepProject,
          state: BuildRoadmapStepState.success,
          progress: 100,
          detail: 'Project metadata and output folder are ready.',
        ),
      );
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Output folder is ready',
          detail: outputDirectory.path,
          state: BuildLogState.success,
        ),
      );

      final unsupportedTargets = selectedTargets
          .where(
            (target) =>
                target.platform != 'Linux' &&
                target.platform != 'Windows' &&
                target.platform != 'Android',
          )
          .toList();
      for (final target in unsupportedTargets) {
        yield BuildEvent.log(
          BuildLogEntry(
            title: '${target.platform} ${target.artifact} skipped',
            detail: 'This target is not wired yet.',
            state: BuildLogState.warning,
          ),
        );
      }

      if (linuxTargets.isEmpty &&
          windowsTargets.isEmpty &&
          androidTargets.isEmpty) {
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'No supported targets selected',
            detail:
                'Select AppImage, deb, rpm, tar.gz, APK or Windows EXE build kit.',
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      yield const BuildEvent.progress(10);
      yield const BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepWorkspace,
          state: BuildRoadmapStepState.running,
          progress: 20,
          detail: 'Copying project into a disposable workspace.',
        ),
      );
      yield const BuildEvent.log(
        BuildLogEntry(
          title: 'Preparing temporary build workspace',
          detail:
              'Copying the project and applying window settings without changing source files.',
          state: BuildLogState.running,
        ),
      );

      final buildWorkspaceInfo = await _createBuildWorkspace(
        projectDirectory: projectDirectory,
        configuration: configuration,
      );
      buildTempDirectory = buildWorkspaceInfo.tempDirectory;
      final workspace = buildWorkspaceInfo.workspace;
      yield const BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepWorkspace,
          state: BuildRoadmapStepState.success,
          progress: 100,
          detail: 'Temporary project copy is ready.',
        ),
      );

      final debTargets = linuxTargets
          .where((target) => target.artifact == 'deb package')
          .toList();
      final localLinuxTargets = linuxTargets
          .where((target) => target.artifact != 'deb package')
          .toList();

      if (localLinuxTargets.isNotEmpty) {
        yield const BuildEvent.progress(15);
        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepLocalBuild,
            state: BuildRoadmapStepState.running,
            progress: 10,
            detail: 'Running flutter build linux --release.',
          ),
        );
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'Running Flutter release build',
            detail: 'flutter build linux --release',
            state: BuildLogState.running,
          ),
        );

        final buildResult = await _runFlutterBuild(workspace.path);
        if (buildResult.exitCode != 0) {
          yield BuildEvent.roadmapUpdate(
            BuildRoadmapUpdate(
              id: _stepLocalBuild,
              state: BuildRoadmapStepState.warning,
              progress: 100,
              detail: _shortProcessOutput(buildResult),
            ),
          );
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
        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepLocalBuild,
            state: BuildRoadmapStepState.success,
            progress: 100,
            detail: 'Linux release bundle was compiled.',
          ),
        );
        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepBundle,
            state: BuildRoadmapStepState.running,
            progress: 40,
            detail: 'Looking for release/bundle and executable file.',
          ),
        );
        yield BuildEvent.log(
          BuildLogEntry(
            title: 'Flutter build completed',
            detail: _shortProcessOutput(buildResult),
            state: BuildLogState.success,
          ),
        );

        final bundleDirectory = await _findLinuxBundle(workspace);
        if (bundleDirectory == null) {
          yield const BuildEvent.roadmapUpdate(
            BuildRoadmapUpdate(
              id: _stepBundle,
              state: BuildRoadmapStepState.warning,
              progress: 100,
              detail: 'Expected build/linux/<arch>/release/bundle.',
            ),
          );
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
        await _copySelectedIconToLinuxBundle(
          bundleDirectory: bundleDirectory,
          iconPath: configuration.iconPath,
        );

        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepBundle,
            state: BuildRoadmapStepState.success,
            progress: 100,
            detail: 'Bundle and executable are ready for packaging.',
          ),
        );

        yield* _exportLinuxTargets(
          configuration: configuration,
          targets: localLinuxTargets,
          bundleDirectory: bundleDirectory,
          outputDirectory: outputDirectory,
        );
      }

      if (windowsTargets.isNotEmpty) {
        yield const BuildEvent.progress(58);
        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepWindowsKit,
            state: BuildRoadmapStepState.running,
            progress: 10,
            detail: 'Preparing transferable Windows build kit zip.',
          ),
        );
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'Preparing Windows build kit',
            detail:
                'Creating a zip with the Flutter project, Inno Setup config and a Windows build script.',
            state: BuildLogState.running,
          ),
        );
        yield* _createWindowsBuildKit(
          configuration: configuration,
          workspace: workspace,
          outputDirectory: outputDirectory,
        );
      }

      if (androidTargets.any((target) => target.artifact == 'APK')) {
        yield const BuildEvent.progress(58);
        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepAndroidBuild,
            state: BuildRoadmapStepState.running,
            progress: 10,
            detail: 'Running flutter build apk --release.',
          ),
        );
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'Building Android APK',
            detail: 'flutter build apk --release',
            state: BuildLogState.running,
          ),
        );
        yield* _createApkPackage(
          configuration: configuration,
          workspace: workspace,
          outputDirectory: outputDirectory,
        );
      }

      if (debTargets.isNotEmpty) {
        yield const BuildEvent.progress(60);
        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepDebContainer,
            state: BuildRoadmapStepState.running,
            progress: 10,
            detail: 'Starting Debian Docker builder.',
          ),
        );
        dockerTouchedWorkspace = true;
        yield BuildEvent.log(
          BuildLogEntry(
            title: 'Packaging deb in Docker',
            detail:
                'Using ${BuilderEnvironment.debBookworm.imageTag} to build and package without depending on the host distro.',
            state: BuildLogState.running,
          ),
        );
        yield* _createDebPackageWithDocker(
          configuration: configuration,
          workspace: workspace,
          outputDirectory: outputDirectory,
        );
      }

      yield const BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepSummary,
          state: BuildRoadmapStepState.success,
          progress: 100,
          detail: 'Selected artifacts were written to the export folder.',
        ),
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
          title: 'Could not run command',
          detail: error.message,
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
    } finally {
      if (buildTempDirectory != null && buildTempDirectory.existsSync()) {
        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepCleanup,
            state: BuildRoadmapStepState.running,
            progress: 40,
            detail:
                'Removing temporary Flutter and packaging workspaces. Docker builds can leave a large cache here.',
          ),
        );
        final cleanupResult = await _deleteTemporaryDirectory(
          buildTempDirectory,
          takeOwnership: dockerTouchedWorkspace,
        );
        yield BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepCleanup,
            state: cleanupResult.deleted
                ? BuildRoadmapStepState.success
                : BuildRoadmapStepState.warning,
            progress: 100,
            detail: cleanupResult.message,
          ),
        );
      }
    }
  }

  List<BuildRoadmapStep> createRoadmapPlan(Iterable<BuildTarget> targets) {
    final selectedTargets = targets.where((target) => target.selected);
    final linuxTargets = selectedTargets
        .where((target) => target.platform == 'Linux')
        .toList();
    final windowsTargets = selectedTargets
        .where((target) => target.platform == 'Windows')
        .toList();
    final androidTargets = selectedTargets
        .where((target) => target.platform == 'Android')
        .toList();
    if (linuxTargets.isEmpty &&
        windowsTargets.isEmpty &&
        androidTargets.isEmpty) {
      return const [];
    }
    return _createRoadmapPlan(
      linuxTargets: linuxTargets,
      windowsTargets: windowsTargets,
      androidTargets: androidTargets,
    );
  }

  List<BuildRoadmapStep> _createRoadmapPlan({
    required List<BuildTarget> linuxTargets,
    required List<BuildTarget> windowsTargets,
    required List<BuildTarget> androidTargets,
  }) {
    final hasDeb = linuxTargets.any(
      (target) => target.artifact == 'deb package',
    );
    final hasRpm = linuxTargets.any(
      (target) => target.artifact == 'rpm package',
    );
    final hasAppImage = linuxTargets.any(
      (target) => target.artifact == 'AppImage',
    );
    final hasTarGz = linuxTargets.any(
      (target) => target.artifact == 'tar.gz bundle',
    );
    final hasWindowsKit = windowsTargets.any(
      (target) => target.artifact == 'Inno Setup exe',
    );
    final hasApk = androidTargets.any((target) => target.artifact == 'APK');
    final hasLocalBuild = hasRpm || hasAppImage || hasTarGz;
    var number = 1;

    BuildRoadmapStep step({
      required String id,
      required String title,
      required String description,
      required int estimatedSeconds,
    }) {
      return BuildRoadmapStep(
        id: id,
        number: number++,
        title: title,
        description: description,
        state: BuildRoadmapStepState.pending,
        estimatedSeconds: estimatedSeconds,
      );
    }

    return [
      step(
        id: _stepProject,
        title: 'Project',
        description: 'Check pubspec.yaml, app metadata and export folder.',
        estimatedSeconds: 3,
      ),
      step(
        id: _stepWorkspace,
        title: 'Workspace',
        description:
            'Copy the project and apply settings without touching sources.',
        estimatedSeconds: 8,
      ),
      if (hasLocalBuild) ...[
        step(
          id: _stepLocalBuild,
          title: 'Flutter build',
          description: 'Compile the Linux release bundle on the host.',
          estimatedSeconds: 120,
        ),
        step(
          id: _stepBundle,
          title: 'Linux bundle',
          description: 'Find the release bundle and executable file.',
          estimatedSeconds: 5,
        ),
      ],
      if (hasRpm)
        step(
          id: _stepRpm,
          title: 'RPM',
          description: 'Generate spec metadata and run rpmbuild.',
          estimatedSeconds: 25,
        ),
      if (hasAppImage)
        step(
          id: _stepAppImage,
          title: 'APPIMAGE',
          description:
              'Create AppDir, AppRun and package it with appimagetool.',
          estimatedSeconds: 25,
        ),
      if (hasTarGz)
        step(
          id: _stepTarGz,
          title: 'TAR.GZ',
          description: 'Archive the Linux release bundle.',
          estimatedSeconds: 10,
        ),
      if (hasWindowsKit)
        step(
          id: _stepWindowsKit,
          title: 'WINDOWS KIT',
          description:
              'Create a transferable zip with project, Inno Setup config and Windows build script.',
          estimatedSeconds: 20,
        ),
      if (hasApk) ...[
        step(
          id: _stepAndroidBuild,
          title: 'APK build',
          description: 'Compile the Android release APK with Flutter.',
          estimatedSeconds: 180,
        ),
        step(
          id: _stepApkExport,
          title: 'APK export',
          description: 'Find the generated APK and copy it to export.',
          estimatedSeconds: 5,
        ),
      ],
      if (hasDeb) ...[
        step(
          id: _stepDebContainer,
          title: 'DEB builder',
          description: 'Start the cached Debian builder environment.',
          estimatedSeconds: 10,
        ),
        step(
          id: _stepDebBuild,
          title: 'DEB build',
          description:
              'Resolve dependencies and compile inside the cached builder.',
          estimatedSeconds: 90,
        ),
        step(
          id: _stepDebPackage,
          title: 'DEB package',
          description: 'Create DEBIAN/control and run dpkg-deb.',
          estimatedSeconds: 15,
        ),
      ],
      step(
        id: _stepSummary,
        title: 'Export',
        description: 'Verify and report generated artifacts.',
        estimatedSeconds: 3,
      ),
      step(
        id: _stepCleanup,
        title: 'Cleanup',
        description:
            'Remove temporary workspaces. Builder builds keep heavy caches outside this folder.',
        estimatedSeconds: hasDeb ? 30 : 15,
      ),
    ];
  }

  Future<_CleanupResult> _deleteTemporaryDirectory(
    Directory directory, {
    required bool takeOwnership,
  }) async {
    if (!directory.existsSync()) {
      return const _CleanupResult(
        deleted: true,
        message: 'Temporary files were already removed.',
      );
    }

    if (Platform.isLinux || Platform.isMacOS) {
      if (takeOwnership) {
        await _tryTakeOwnershipOfTemporaryDirectory(directory);
      }
      final result = await Process.run('rm', ['-rf', directory.path]);
      if (result.exitCode == 0 || !directory.existsSync()) {
        return const _CleanupResult(
          deleted: true,
          message: 'Temporary files were removed.',
        );
      }
    }

    try {
      await directory.delete(recursive: true);
      return const _CleanupResult(
        deleted: true,
        message: 'Temporary files were removed.',
      );
    } on FileSystemException catch (error) {
      return _CleanupResult(
        deleted: false,
        message:
            'Build is finished, but temporary files could not be removed automatically: ${error.message}.',
      );
    }
  }

  Future<void> _tryTakeOwnershipOfTemporaryDirectory(
    Directory directory,
  ) async {
    final runtime = await _builderEnvironmentService.resolveRuntime();
    if (runtime == null) {
      return;
    }

    final userId = (await Process.run('id', ['-u'])).stdout.toString().trim();
    final groupId = (await Process.run('id', ['-g'])).stdout.toString().trim();
    if (userId.isEmpty || groupId.isEmpty) {
      return;
    }

    await Process.run(runtime.executable, [
      'run',
      '--rm',
      '-v',
      '${directory.path}:/cleanup',
      BuilderEnvironment.debBookworm.imageTag,
      'chown',
      '-R',
      '$userId:$groupId',
      '/cleanup',
    ]);
  }

  Future<_BuildWorkspace> _createBuildWorkspace({
    required Directory projectDirectory,
    required BuildConfiguration configuration,
  }) async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'pack_foundry_build_',
    );
    final workspace = Directory(_joinPath(tempRoot.path, 'project'));
    await _copyProjectDirectory(projectDirectory, workspace);
    await _applyWindowSizeOverrides(workspace, configuration);
    await _applyIconOverrides(workspace, configuration);
    return _BuildWorkspace(tempDirectory: tempRoot, workspace: workspace);
  }

  Future<void> _copyProjectDirectory(
    Directory source,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      final relativePath = entity.path.substring(source.path.length + 1);
      if (_shouldSkipProjectPath(relativePath)) {
        continue;
      }

      final newPath = _joinPath(destination.path, relativePath);
      if (entity is Directory) {
        await Directory(newPath).create(recursive: true);
      } else if (entity is File) {
        await File(newPath).parent.create(recursive: true);
        await entity.copy(newPath);
      }
    }
  }

  bool _shouldSkipProjectPath(String relativePath) {
    final parts = relativePath.split(Platform.pathSeparator);
    return parts.any((part) {
      return part == 'build' ||
          part == '.dart_tool' ||
          part == '.git' ||
          part == '.idea';
    });
  }

  Future<void> _applyWindowSizeOverrides(
    Directory workspace,
    BuildConfiguration configuration,
  ) async {
    final width = configuration.windowWidth;
    final height = configuration.windowHeight;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return;
    }

    await _patchLinuxWindowSize(workspace, width, height);
    await _patchWindowsWindowSize(workspace, width, height);
  }

  Future<void> _applyIconOverrides(
    Directory workspace,
    BuildConfiguration configuration,
  ) async {
    final appName = configuration.appName.trim().isEmpty
        ? 'Flutter App'
        : configuration.appName.trim();
    final packageName = _slugify(appName);
    final desktopFileId = _linuxDesktopFileId(appName);
    await _patchLinuxApplicationId(workspace, desktopFileId);
    await _patchLinuxWindowIcon(
      workspace: workspace,
      iconName: desktopFileId,
      windowClass: packageName,
    );
  }

  Future<void> _patchLinuxApplicationId(
    Directory workspace,
    String applicationId,
  ) async {
    final file = File(_joinPath(workspace.path, 'linux/CMakeLists.txt'));
    if (!file.existsSync()) {
      return;
    }

    final content = await file.readAsString();
    final updated = content.replaceFirst(
      RegExp(r'set\s*\(\s*APPLICATION_ID\s+"[^"]*"\s*\)'),
      'set(APPLICATION_ID "${_cStringLiteral(applicationId)}")',
    );
    if (updated != content) {
      await file.writeAsString(updated);
    }
  }

  Future<void> _patchLinuxWindowIcon({
    required Directory workspace,
    required String iconName,
    required String windowClass,
  }) async {
    final file = File(
      _joinPath(workspace.path, 'linux/runner/my_application.cc'),
    );
    if (!file.existsSync()) {
      return;
    }

    final content = await file.readAsString();
    var updated = content;
    final cIconName = _cStringLiteral(iconName);
    final cWindowClass = _cStringLiteral(windowClass);
    if (!updated.contains('pack_foundry_window_icon')) {
      updated = updated.replaceFirstMapped(
        RegExp(r'gtk_window_set_default_size\s*\([^;]+;\s*', multiLine: true),
        (match) =>
            '''${match.group(0)}  gtk_window_set_icon_name(window, "$cIconName");
  const gchar* pack_foundry_icon_candidates[] = {
    "pack_foundry_window_icon.svg",
    "pack_foundry_window_icon.png",
    nullptr,
  };
  g_autofree gchar* pf_executable_path = g_file_read_link("/proc/self/exe", nullptr);
  if (pf_executable_path != nullptr) {
    g_autofree gchar* pf_executable_dir = g_path_get_dirname(pf_executable_path);
    for (int pf_icon_index = 0; pack_foundry_icon_candidates[pf_icon_index] != nullptr; pf_icon_index++) {
      g_autofree gchar* pf_icon_path = g_build_filename(
          pf_executable_dir, pack_foundry_icon_candidates[pf_icon_index], nullptr);
      if (g_file_test(pf_icon_path, G_FILE_TEST_EXISTS)) {
        gtk_window_set_icon_from_file(window, pf_icon_path, nullptr);
        break;
      }
    }
  }

''',
      );
    }

    updated = updated.replaceAllMapped(
      RegExp(r'g_set_prgname\s*\([^;]+\);'),
      (_) => 'g_set_prgname("$cWindowClass");',
    );

    if (updated != content) {
      await file.writeAsString(updated);
    }
  }

  Future<void> _patchLinuxWindowSize(
    Directory workspace,
    int width,
    int height,
  ) async {
    final file = File(
      _joinPath(workspace.path, 'linux/runner/my_application.cc'),
    );
    if (!file.existsSync()) {
      return;
    }

    final content = await file.readAsString();
    final updated = content.replaceFirst(
      RegExp(r'gtk_window_set_default_size\s*\([^,]+,\s*\d+\s*,\s*\d+\s*\)'),
      'gtk_window_set_default_size(window, $width, $height)',
    );
    if (updated != content) {
      await file.writeAsString(updated);
    }
  }

  Future<void> _patchWindowsWindowSize(
    Directory workspace,
    int width,
    int height,
  ) async {
    final file = File(_joinPath(workspace.path, 'windows/runner/main.cpp'));
    if (!file.existsSync()) {
      return;
    }

    final content = await file.readAsString();
    final updated = content.replaceFirst(
      RegExp(r'Win32Window::Size\s+size\s*\(\s*\d+\s*,\s*\d+\s*\)'),
      'Win32Window::Size size($width, $height)',
    );
    if (updated != content) {
      await file.writeAsString(updated);
    }
  }

  Stream<BuildEvent> _exportLinuxTargets({
    required BuildConfiguration configuration,
    required List<BuildTarget> targets,
    required Directory bundleDirectory,
    required Directory outputDirectory,
  }) async* {
    for (var index = 0; index < targets.length; index++) {
      final target = targets[index];

      if (target.artifact == 'AppImage') {
        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepAppImage,
            state: BuildRoadmapStepState.running,
            progress: 15,
            detail: 'Preparing AppDir and appimagetool package.',
          ),
        );
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'Packaging AppImage',
            detail: 'Preparing AppDir and appimagetool package.',
            state: BuildLogState.running,
          ),
        );
        yield* _createAppImage(
          configuration: configuration,
          bundleDirectory: bundleDirectory,
          outputDirectory: outputDirectory,
        );
      } else if (target.artifact == 'rpm package') {
        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepRpm,
            state: BuildRoadmapStepState.running,
            progress: 15,
            detail: 'Preparing rpmbuild tree and package metadata.',
          ),
        );
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'Packaging RPM',
            detail: 'Preparing rpmbuild tree and package metadata.',
            state: BuildLogState.running,
          ),
        );
        yield* _createRpmPackage(
          configuration: configuration,
          bundleDirectory: bundleDirectory,
          outputDirectory: outputDirectory,
        );
      } else if (target.artifact == 'tar.gz bundle') {
        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepTarGz,
            state: BuildRoadmapStepState.running,
            progress: 30,
            detail: 'Creating compressed release bundle.',
          ),
        );
        yield* _createTarGzBundle(
          appName: configuration.appName,
          bundleDirectory: bundleDirectory,
          outputDirectory: outputDirectory,
        );
      } else {
        final artifactSlug = _slugify(target.artifact);
        final fallbackDirectory = Directory(
          _joinPath(
            outputDirectory.path,
            '${_slugify(configuration.appName)}-linux-$artifactSlug-bundle',
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

  Stream<BuildEvent> _createWindowsBuildKit({
    required BuildConfiguration configuration,
    required Directory workspace,
    required Directory outputDirectory,
  }) async* {
    Directory? tempDirectory;
    try {
      final zip = await _findExecutable('zip');
      if (zip == null) {
        yield const BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepWindowsKit,
            state: BuildRoadmapStepState.warning,
            progress: 100,
            detail: 'zip command was not found in PATH.',
          ),
        );
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'Windows build kit failed',
            detail: 'zip command was not found in PATH.',
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      final appName = configuration.appName.trim().isEmpty
          ? 'Flutter App'
          : configuration.appName.trim();
      final packageName = _slugify(appName);
      final safeName = _safeFileName(appName);
      tempDirectory = await Directory.systemTemp.createTemp(
        'pack_foundry_windows_kit_',
      );
      final kitRoot = Directory(
        _joinPath(tempDirectory.path, '${packageName}_windows_build_kit'),
      );
      final projectDirectory = Directory(_joinPath(kitRoot.path, 'project'));
      final scriptsDirectory = Directory(_joinPath(kitRoot.path, 'scripts'));
      final innoDirectory = Directory(_joinPath(kitRoot.path, 'inno'));
      final assetsDirectory = Directory(_joinPath(kitRoot.path, 'assets'));
      await scriptsDirectory.create(recursive: true);
      await innoDirectory.create(recursive: true);
      await assetsDirectory.create(recursive: true);

      yield const BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepWindowsKit,
          state: BuildRoadmapStepState.running,
          progress: 35,
          detail: 'Copying project and writing Windows helper files.',
        ),
      );

      await _copyDirectory(workspace, projectDirectory);
      final iconRelativePath = await _copyWindowsKitIcon(
        assetsDirectory: assetsDirectory,
        iconPath: configuration.iconPath,
      );
      await File(_joinPath(innoDirectory.path, 'setup.iss')).writeAsString(
        _windowsInnoSetupScript(
          configuration: configuration,
          appName: appName,
          packageName: packageName,
          iconRelativePath: iconRelativePath,
        ),
      );
      await File(
        _joinPath(scriptsDirectory.path, 'build_windows.ps1'),
      ).writeAsString(_windowsBuildPowerShellScript(appName: appName));
      await File(
        _joinPath(kitRoot.path, 'README_WINDOWS_BUILD.txt'),
      ).writeAsString(_windowsBuildKitReadme(appName));

      yield const BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepWindowsKit,
          state: BuildRoadmapStepState.running,
          progress: 70,
          detail: 'Compressing Windows build kit zip.',
        ),
      );

      final outputFile = File(
        _joinPath(outputDirectory.path, '${safeName}_windows_build_kit.zip'),
      );
      if (outputFile.existsSync()) {
        await outputFile.delete();
      }
      final result = await Process.run(
        zip.path,
        ['-qr', outputFile.path, _basename(kitRoot.path)],
        workingDirectory: tempDirectory.path,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0 || !outputFile.existsSync()) {
        yield BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepWindowsKit,
            state: BuildRoadmapStepState.warning,
            progress: 100,
            detail: _shortProcessOutput(result),
          ),
        );
        yield BuildEvent.log(
          BuildLogEntry(
            title: 'Windows build kit failed',
            detail: _shortProcessOutput(result),
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      yield BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepWindowsKit,
          state: BuildRoadmapStepState.success,
          progress: 100,
          detail: outputFile.path,
        ),
      );
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Created Windows build kit',
          detail: outputFile.path,
          state: BuildLogState.success,
        ),
      );
    } finally {
      if (tempDirectory != null && tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    }
  }

  Stream<BuildEvent> _createApkPackage({
    required BuildConfiguration configuration,
    required Directory workspace,
    required Directory outputDirectory,
  }) async* {
    final buildResult = await _runFlutterApkBuild(workspace.path);
    if (buildResult.exitCode != 0) {
      yield BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepAndroidBuild,
          state: BuildRoadmapStepState.warning,
          progress: 100,
          detail: _shortProcessOutput(buildResult),
        ),
      );
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Android APK build failed',
          detail: _shortProcessOutput(buildResult),
          state: BuildLogState.warning,
        ),
      );
      return;
    }

    yield const BuildEvent.roadmapUpdate(
      BuildRoadmapUpdate(
        id: _stepAndroidBuild,
        state: BuildRoadmapStepState.success,
        progress: 100,
        detail: 'Android release APK was compiled.',
      ),
    );
    yield BuildEvent.log(
      BuildLogEntry(
        title: 'Android APK build completed',
        detail: _shortProcessOutput(buildResult),
        state: BuildLogState.success,
      ),
    );

    yield const BuildEvent.roadmapUpdate(
      BuildRoadmapUpdate(
        id: _stepApkExport,
        state: BuildRoadmapStepState.running,
        progress: 40,
        detail: 'Looking for build/app/outputs/flutter-apk/app-release.apk.',
      ),
    );

    final apkFile = _findReleaseApk(workspace);
    if (apkFile == null) {
      yield const BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepApkExport,
          state: BuildRoadmapStepState.warning,
          progress: 100,
          detail: 'Expected build/app/outputs/flutter-apk/app-release.apk.',
        ),
      );
      yield const BuildEvent.log(
        BuildLogEntry(
          title: 'Android APK not found',
          detail: 'Expected build/app/outputs/flutter-apk/app-release.apk.',
          state: BuildLogState.warning,
        ),
      );
      return;
    }

    final appName = configuration.appName.trim().isEmpty
        ? 'Flutter App'
        : configuration.appName.trim();
    final version = _packageVersion(configuration);
    final outputFile = File(
      _joinPath(
        outputDirectory.path,
        version == null
            ? '${_safeFileName(appName)}.apk'
            : '${_safeFileName(appName)}_$version.apk',
      ),
    );
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }
    await apkFile.copy(outputFile.path);

    yield BuildEvent.roadmapUpdate(
      BuildRoadmapUpdate(
        id: _stepApkExport,
        state: BuildRoadmapStepState.success,
        progress: 100,
        detail: outputFile.path,
      ),
    );
    yield BuildEvent.log(
      BuildLogEntry(
        title: 'Created Android APK',
        detail: outputFile.path,
        state: BuildLogState.success,
      ),
    );
  }

  Future<String?> _copyWindowsKitIcon({
    required Directory assetsDirectory,
    required String? iconPath,
  }) async {
    if (iconPath == null || iconPath.isEmpty) {
      return null;
    }

    final source = File(iconPath);
    if (!source.existsSync()) {
      return null;
    }

    final extension = _extension(source.path).toLowerCase();
    final fileName = extension == '.ico'
        ? 'installer.ico'
        : extension == '.svg'
        ? 'icon.svg'
        : 'icon.png';
    await source.copy(_joinPath(assetsDirectory.path, fileName));
    return '../assets/$fileName';
  }

  String _windowsInnoSetupScript({
    required BuildConfiguration configuration,
    required String appName,
    required String packageName,
    required String? iconRelativePath,
  }) {
    final escapedAppName = _innoValue(appName);
    final escapedPackageName = _innoValue(packageName);
    final publisher = _innoValue(_publisherName(configuration));
    final version = _innoValue(
      _packageVersion(configuration, fallback: '1.0.0')!,
    );
    final homepage = _innoValue(configuration.homepageUrl.trim());
    final iconLine =
        iconRelativePath != null && iconRelativePath.endsWith('.ico')
        ? 'SetupIconFile=$iconRelativePath\n'
        : '';
    return '''#define MyAppName "$escapedAppName"
#define MyAppPublisher "$publisher"
#ifndef MyAppExeName
#define MyAppExeName "$escapedPackageName.exe"
#endif

[Setup]
AppId={{$escapedPackageName-packfoundry}}
AppName={#MyAppName}
AppVersion=$version
AppPublisher={#MyAppPublisher}
${homepage.isEmpty ? '' : 'AppPublisherURL=$homepage\nAppSupportURL=$homepage\nAppUpdatesURL=$homepage'}
DefaultDirName={autopf}\\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\\output
OutputBaseFilename=$escapedPackageName-setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
$iconLine
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "..\\project\\build\\windows\\x64\\runner\\Release\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"
Name: "{autodesktop}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
''';
  }

  String _windowsBuildPowerShellScript({required String appName}) {
    final escapedAppName = _powerShellSingleQuoted(appName);
    return '''param(
  [string]\$FlutterChannel = 'stable'
)

\$ErrorActionPreference = 'Stop'
\$Root = Split-Path -Parent \$PSScriptRoot
\$ProjectDir = Join-Path \$Root 'project'
\$InnoScript = Join-Path \$Root 'inno\\setup.iss'
\$OutputDir = Join-Path \$Root 'output'
\$AppName = '$escapedAppName'

function Write-Step {
  param([string]\$Message)
  Write-Host ''
  Write-Host "=== \$Message ===" -ForegroundColor Cyan
}

function Test-CommandAvailable {
  param([string]\$Name)
  return \$null -ne (Get-Command \$Name -ErrorAction SilentlyContinue)
}

function Invoke-CheckedNative {
  param(
    [string]\$Executable,
    [string[]]\$Arguments,
    [string]\$ErrorMessage
  )
  & \$Executable @Arguments
  if (\$LASTEXITCODE -ne 0) {
    throw "\$ErrorMessage Exit code: \$LASTEXITCODE."
  }
}

function Test-DeveloperModeEnabled {
  \$path = 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AppModelUnlock'
  try {
    \$value = Get-ItemPropertyValue -Path \$path -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction Stop
    return \$value -eq 1
  } catch {
    return \$false
  }
}

function Ensure-DeveloperMode {
  if (Test-DeveloperModeEnabled) {
    Write-Host 'Developer Mode is already enabled.'
    return
  }

  Write-Host 'Developer Mode is required by Flutter plugins on Windows because they use symlinks.'
  \$regArguments = @(
    'add', 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AppModelUnlock',
    '/t', 'REG_DWORD', '/f', '/v', 'AllowDevelopmentWithoutDevLicense', '/d', '1'
  )
  & reg.exe @regArguments | Out-Host
  if (\$LASTEXITCODE -eq 0 -and (Test-DeveloperModeEnabled)) {
    Write-Host 'Developer Mode was enabled automatically.'
    return
  }

  Start-Process 'ms-settings:developers'
  throw 'Developer Mode is not enabled. Enable it in Windows Settings, then run this script again.'
}

function Add-PathForCurrentProcess {
  param([string]\$Directory)
  if ([string]::IsNullOrWhiteSpace(\$Directory)) { return }
  if (-not (Test-Path \$Directory)) { return }
  if ((\$env:Path -split ';') -notcontains \$Directory) {
    \$env:Path = "\$env:Path;\$Directory"
  }
}

function Find-GitCommand {
  \$command = Get-Command 'git.exe' -ErrorAction SilentlyContinue
  if (\$null -ne \$command) { return \$command.Source }

  \$candidates = @(
    "\$env:ProgramFiles\\Git\\cmd\\git.exe",
    "\$env:ProgramFiles\\Git\\bin\\git.exe",
    "\${env:ProgramFiles(x86)}\\Git\\cmd\\git.exe",
    "\${env:ProgramFiles(x86)}\\Git\\bin\\git.exe",
    "\$env:LOCALAPPDATA\\Programs\\Git\\cmd\\git.exe",
    "\$env:LOCALAPPDATA\\Programs\\Git\\bin\\git.exe"
  )
  foreach (\$candidate in \$candidates) {
    if (Test-Path \$candidate) { return \$candidate }
  }
  return \$null
}

function Ensure-GitAvailable {
  \$git = Find-GitCommand
  if (-not [string]::IsNullOrWhiteSpace(\$git)) {
    Add-PathForCurrentProcess -Directory (Split-Path -Parent \$git)
    return \$git
  }

  Write-Step 'Installing Git'
  Invoke-WingetInstall -PackageId 'Git.Git'
  \$git = Find-GitCommand
  if ([string]::IsNullOrWhiteSpace(\$git)) {
    throw 'Git was installed, but git.exe was not found. Restart PowerShell or install Git manually.'
  }
  Add-PathForCurrentProcess -Directory (Split-Path -Parent \$git)
  return \$git
}

function Invoke-WingetInstall {
  param([string]\$PackageId, [string[]]\$ExtraArguments = @())
  if (-not (Test-CommandAvailable 'winget')) {
    throw 'winget was not found. Install App Installer from Microsoft Store or install tools manually.'
  }
  \$arguments = @(
    'install', '--id', \$PackageId, '--exact',
    '--accept-source-agreements', '--accept-package-agreements',
    '--silent'
  ) + \$ExtraArguments
  Write-Host "winget \$(\$arguments -join ' ')"
  \$output = & winget @arguments 2>&1
  \$exitCode = \$LASTEXITCODE
  if (\$output) { \$output | ForEach-Object { Write-Host \$_ } }
  if (\$exitCode -eq 0) { return }

  \$alreadyInstalledCode = \$exitCode -eq -1978335189
  \$alreadyInstalledText = \$output -match 'existing installed package|installed package|no available upgrade|no newer package versions|no applicable update found|already installed'
  if (\$alreadyInstalledCode -or \$alreadyInstalledText) {
    Write-Host "winget reports that \$PackageId is already installed or has no available update. Continuing."
    return
  }

  throw "winget install \$PackageId failed with exit code \$exitCode."
}

function Find-InnoCompiler {
  \$command = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
  if (\$null -ne \$command) { return \$command.Source }

  \$roots = @(
    \$env:ProgramFiles,
    \${env:ProgramFiles(x86)},
    \$env:LOCALAPPDATA
  ) | Where-Object { -not [string]::IsNullOrWhiteSpace(\$_) }

  foreach (\$root in \$roots) {
    \$direct = Join-Path \$root 'Inno Setup 6\\ISCC.exe'
    if (Test-Path \$direct) { return \$direct }
    \$match = Get-ChildItem -Path \$root -Filter 'ISCC.exe' -Recurse -ErrorAction SilentlyContinue |
      Where-Object { \$_.FullName -like '*Inno Setup*' } |
      Select-Object -First 1
    if (\$null -ne \$match) { return \$match.FullName }
  }

  return \$null
}

function Find-VisualStudioBuildTools {
  \$vswhere = "\${env:ProgramFiles(x86)}\\Microsoft Visual Studio\\Installer\\vswhere.exe"
  if (Test-Path \$vswhere) {
    \$installPath = & \$vswhere -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>\$null | Select-Object -First 1
    if (-not [string]::IsNullOrWhiteSpace(\$installPath)) { return \$installPath.Trim() }
  }
  \$msbuild = Get-Command 'MSBuild.exe' -ErrorAction SilentlyContinue
  if (\$null -ne \$msbuild) { return \$msbuild.Source }
  return \$null
}

function Ensure-FlutterSdk {
  if (Test-CommandAvailable 'flutter') {
    Write-Host 'Flutter is already available.'
    return
  }
  \$git = Ensure-GitAvailable
  \$packFoundryRoot = Join-Path \$env:LOCALAPPDATA 'PackFoundry'
  \$flutterRoot = Join-Path \$packFoundryRoot 'flutter'
  if (-not (Test-Path \$flutterRoot)) {
    Write-Step "Downloading Flutter SDK (\$FlutterChannel)"
    New-Item -ItemType Directory -Force -Path \$packFoundryRoot | Out-Null
    & \$git clone --depth 1 --branch \$FlutterChannel https://github.com/flutter/flutter.git \$flutterRoot
    if (\$LASTEXITCODE -ne 0) { throw 'Flutter SDK clone failed.' }
  }
  \$flutterBin = Join-Path \$flutterRoot 'bin'
  \$env:Path = "\$env:Path;\$flutterBin"
  \$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ((\$userPath -split ';') -notcontains \$flutterBin) {
    [Environment]::SetEnvironmentVariable('Path', "\$userPath;\$flutterBin", 'User')
  }
}

Write-Step "Preparing Windows build for \$AppName"
New-Item -ItemType Directory -Force -Path \$OutputDir | Out-Null

Write-Step 'Checking Flutter SDK'
Ensure-FlutterSdk
Invoke-CheckedNative -Executable 'flutter' -Arguments @('--version') -ErrorMessage 'flutter --version failed.'
Invoke-CheckedNative -Executable 'flutter' -Arguments @('config', '--enable-windows-desktop') -ErrorMessage 'flutter config failed.'

Write-Step 'Checking Windows Developer Mode'
Ensure-DeveloperMode

Write-Step 'Checking Visual Studio Build Tools'
if ([string]::IsNullOrWhiteSpace((Find-VisualStudioBuildTools))) {
  Invoke-WingetInstall -PackageId 'Microsoft.VisualStudio.2022.BuildTools' -ExtraArguments @(
    '--override', '"--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools;includeRecommended --add Microsoft.VisualStudio.Component.Windows10SDK.19041"'
  )
} else {
  Write-Host 'Visual Studio Build Tools are already installed.'
}

Write-Step 'Checking Inno Setup'
\$iscc = Find-InnoCompiler
if ([string]::IsNullOrWhiteSpace(\$iscc)) {
  Invoke-WingetInstall -PackageId 'JRSoftware.InnoSetup'
  \$iscc = Find-InnoCompiler
}
if ([string]::IsNullOrWhiteSpace(\$iscc)) { throw 'ISCC.exe was not found after installation.' }
Write-Host "Inno Setup compiler: \$iscc"

Write-Step 'Resolving Flutter dependencies'
Push-Location \$ProjectDir
try {
  Invoke-CheckedNative -Executable 'flutter' -Arguments @('pub', 'get') -ErrorMessage 'flutter pub get failed.'

  Write-Step 'Building Windows release bundle'
  Invoke-CheckedNative -Executable 'flutter' -Arguments @('build', 'windows', '--release') -ErrorMessage 'flutter build windows failed.'
} finally {
  Pop-Location
}
\$releaseDir = Join-Path \$ProjectDir 'build\\windows\\x64\\runner\\Release'
\$appExe = Get-ChildItem \$releaseDir -Filter '*.exe' | Select-Object -First 1
if (\$null -eq \$appExe) { throw "No .exe file was found in \$releaseDir" }
Write-Host "Windows executable: \$(\$appExe.Name)"

Write-Step 'Creating EXE installer with Inno Setup'
& \$iscc "/DMyAppExeName=\$(\$appExe.Name)" \$InnoScript
if (\$LASTEXITCODE -ne 0) { throw 'Inno Setup compilation failed.' }

Write-Step 'Done'
Write-Host "Installer files are in: \$OutputDir" -ForegroundColor Green
Get-ChildItem \$OutputDir
''';
  }

  String _windowsBuildKitReadme(String appName) {
    return '''PackFoundry Windows build kit for $appName

1. Copy this folder to Windows 10/11.
2. Open PowerShell in this folder.
3. Run:

   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\\scripts\\build_windows.ps1

The script prints every step, installs missing tools through winget when possible,
builds the Flutter Windows release bundle, runs Inno Setup and writes the final
EXE installer into the output folder next to this file.

Required Windows-side tools prepared by the script:
- Git, if Flutter SDK must be downloaded.
- Flutter SDK stable channel, stored in %LOCALAPPDATA%\\PackFoundry\\flutter.
- Visual Studio 2022 Build Tools with C++ workload.
- Inno Setup 6.
''';
  }

  String _innoValue(String value) {
    return value
        .replaceAll('"', '\\"')
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ');
  }

  String _powerShellSingleQuoted(String value) {
    return value
        .replaceAll("'", "''")
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ');
  }

  Stream<BuildEvent> _createAppImage({
    required BuildConfiguration configuration,
    required Directory bundleDirectory,
    required Directory outputDirectory,
  }) async* {
    Directory? tempDirectory;
    try {
      final appImageTool = await _resolveAppImageTool();
      final appName = configuration.appName.trim().isEmpty
          ? 'Flutter App'
          : configuration.appName.trim();
      final desktopFileId = _linuxDesktopFileId(appName);
      final executable = await _findBundleExecutable(bundleDirectory);
      if (executable == null) {
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'AppImage packaging failed',
            detail:
                'Could not find the executable in the Flutter Linux bundle.',
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      tempDirectory = await Directory.systemTemp.createTemp(
        'pack_foundry_appimage_',
      );
      final appDir = Directory(
        _joinPath(tempDirectory.path, '$desktopFileId.AppDir'),
      );
      final appBinDir = Directory(_joinPath(appDir.path, 'usr/bin'));
      await appBinDir.create(recursive: true);
      await _copyDirectory(bundleDirectory, appBinDir);

      await _writeAppRun(
        appDir: appDir,
        executableName: _basename(executable.path),
      );
      await _writeDesktopFile(
        appDir: appDir,
        appName: appName,
        desktopFileId: desktopFileId,
        windowClass: _slugify(appName),
      );
      await _prepareAppIcon(
        appDir: appDir,
        iconName: desktopFileId,
        iconPath: configuration.iconPath,
      );

      final appImagePath = _joinPath(
        outputDirectory.path,
        '${_safeFileName(appName)}.AppImage',
      );
      final appImageFile = File(appImagePath);
      if (appImageFile.existsSync()) {
        await appImageFile.delete();
      }

      final result = await Process.run(
        appImageTool.path,
        [appDir.path, appImagePath],
        environment: {
          ...Platform.environment,
          'ARCH': _appImageArchitecture(),
          'APPIMAGE_EXTRACT_AND_RUN': '1',
        },
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0 || !appImageFile.existsSync()) {
        yield BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepAppImage,
            state: BuildRoadmapStepState.warning,
            progress: 100,
            detail: _shortProcessOutput(result),
          ),
        );
        yield BuildEvent.log(
          BuildLogEntry(
            title: 'AppImage packaging failed',
            detail: _shortProcessOutput(result),
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      await _makeExecutable(appImageFile);
      yield BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepAppImage,
          state: BuildRoadmapStepState.success,
          progress: 100,
          detail: appImagePath,
        ),
      );
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Created AppImage',
          detail: appImagePath,
          state: BuildLogState.success,
        ),
      );
    } on SocketException catch (error) {
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Could not download appimagetool',
          detail: error.message,
          state: BuildLogState.warning,
        ),
      );
    } on HttpException catch (error) {
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Could not download appimagetool',
          detail: error.message,
          state: BuildLogState.warning,
        ),
      );
    } finally {
      if (tempDirectory != null && tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    }
  }

  Stream<BuildEvent> _createTarGzBundle({
    required String appName,
    required Directory bundleDirectory,
    required Directory outputDirectory,
  }) async* {
    final archivePath = _joinPath(
      outputDirectory.path,
      '${_slugify(appName)}-linux.tar.gz',
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
      yield BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepTarGz,
          state: BuildRoadmapStepState.success,
          progress: 100,
          detail: archivePath,
        ),
      );
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
  }

  Stream<BuildEvent> _createRpmPackage({
    required BuildConfiguration configuration,
    required Directory bundleDirectory,
    required Directory outputDirectory,
  }) async* {
    Directory? tempDirectory;
    try {
      final rpmbuild = await _findExecutable('rpmbuild');
      if (rpmbuild == null) {
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'RPM packaging failed',
            detail: 'rpmbuild was not found in PATH.',
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      final executable = await _findBundleExecutable(bundleDirectory);
      if (executable == null) {
        yield const BuildEvent.log(
          BuildLogEntry(
            title: 'RPM packaging failed',
            detail:
                'Could not find the executable in the Flutter Linux bundle.',
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      final appName = configuration.appName.trim().isEmpty
          ? 'Flutter App'
          : configuration.appName.trim();
      final packageName = _slugify(appName);
      final desktopFileId = _linuxDesktopFileId(appName);
      final rpmVersion = await _readRpmVersion(configuration);
      final desktopFileName = '$desktopFileId.desktop';

      tempDirectory = await Directory.systemTemp.createTemp(
        'pack_foundry_rpm_',
      );
      final topDirectory = Directory(_joinPath(tempDirectory.path, 'rpmbuild'));
      final specsDirectory = Directory(_joinPath(topDirectory.path, 'SPECS'));
      final rpmsDirectory = Directory(_joinPath(topDirectory.path, 'RPMS'));
      final assetsDirectory = Directory(
        _joinPath(tempDirectory.path, 'assets'),
      );
      await specsDirectory.create(recursive: true);
      await assetsDirectory.create(recursive: true);
      final preparedIcon = await _copyPackageIcon(
        assetsDirectory: assetsDirectory,
        iconPath: configuration.iconPath,
        fileNameWithoutExtension: desktopFileId,
      );

      final desktopFile = File(
        _joinPath(assetsDirectory.path, desktopFileName),
      );
      await desktopFile.writeAsString('''[Desktop Entry]
Type=Application
Name=${_escapeDesktopValue(appName)}
Exec=/opt/$packageName/${_basename(executable.path)}
Icon=$desktopFileId
StartupWMClass=$packageName
Categories=Utility;
Terminal=false
''');

      final iconSource =
          preparedIcon ??
          await _writeFallbackRpmIcon(assetsDirectory, desktopFileId);
      final specFile = File(
        _joinPath(specsDirectory.path, '$packageName.spec'),
      );
      await specFile.writeAsString(
        _rpmSpec(
          configuration: configuration,
          appName: appName,
          packageName: packageName,
          desktopFileId: desktopFileId,
          version: rpmVersion.version,
          release: rpmVersion.release,
          bundleDirectory: bundleDirectory,
          desktopFile: desktopFile,
          iconFile: iconSource,
          executableName: _basename(executable.path),
        ),
      );

      final result = await Process.run(
        rpmbuild.path,
        ['-bb', '--define', '_topdir ${topDirectory.path}', specFile.path],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0) {
        yield BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: _stepRpm,
            state: BuildRoadmapStepState.warning,
            progress: 100,
            detail: _shortProcessOutput(result),
          ),
        );
        yield BuildEvent.log(
          BuildLogEntry(
            title: 'RPM packaging failed',
            detail: _shortProcessOutput(result),
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      final rpmFile = await _findFirstFileWithExtension(rpmsDirectory, '.rpm');
      if (rpmFile == null) {
        yield BuildEvent.log(
          BuildLogEntry(
            title: 'RPM packaging failed',
            detail: 'rpmbuild finished, but no .rpm file was found.',
            state: BuildLogState.warning,
          ),
        );
        return;
      }

      final outputFile = File(
        _joinPath(
          outputDirectory.path,
          '${_safeFileName(appName)}-${rpmVersion.version}-${rpmVersion.release}.${_rpmArchitecture()}.rpm',
        ),
      );
      if (outputFile.existsSync()) {
        await outputFile.delete();
      }
      await rpmFile.copy(outputFile.path);

      yield BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepRpm,
          state: BuildRoadmapStepState.success,
          progress: 100,
          detail: outputFile.path,
        ),
      );
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'Created RPM package',
          detail: outputFile.path,
          state: BuildLogState.success,
        ),
      );
    } finally {
      if (tempDirectory != null && tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    }
  }

  String _rpmSpec({
    required BuildConfiguration configuration,
    required String appName,
    required String packageName,
    required String desktopFileId,
    required String version,
    required String release,
    required Directory bundleDirectory,
    required File desktopFile,
    required File iconFile,
    required String executableName,
  }) {
    final iconExtension = _extension(iconFile.path).toLowerCase();
    final iconDestination = iconExtension == '.svg'
        ? '%{buildroot}/usr/share/icons/hicolor/scalable/apps/$desktopFileId.svg'
        : '%{buildroot}/usr/share/icons/hicolor/256x256/apps/$desktopFileId.png';

    final homepage = configuration.homepageUrl.trim();
    final rpmRequires = _packageDependencies(
      configuration,
      type: 'rpm',
      defaults: const ['gtk3', 'libstdc++', 'xz-libs'],
    );
    return '''%global __brp_check_rpaths %{nil}

Name:           $packageName
Version:        $version
Release:        $release%{?dist}
Summary:        ${_rpmHeaderValue(_packageSummary(configuration, appName))}
License:        ${_rpmHeaderValue(_packageLicense(configuration))}
${homepage.isEmpty ? '' : 'URL:            ${_rpmHeaderValue(homepage)}\n'}Requires:       $rpmRequires

%description
${_rpmDescription(_packageDescription(configuration, appName))}

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt/$packageName
cp -a ${_shellQuote(bundleDirectory.path)}/. %{buildroot}/opt/$packageName/
chmod 755 %{buildroot}/opt/$packageName/${_shellQuote(executableName)}
install -Dm0644 ${_shellQuote(desktopFile.path)} %{buildroot}/usr/share/applications/$desktopFileId.desktop
install -Dm0644 ${_shellQuote(iconFile.path)} $iconDestination

%files
/opt/$packageName
/usr/share/applications/$desktopFileId.desktop
/usr/share/icons/hicolor/*/apps/$desktopFileId.*

%changelog
* ${_rpmChangelogDate()} ${_rpmHeaderValue(_publisherName(configuration))} <${_rpmHeaderValue(_developerEmail(configuration))}> - $version-$release
- Packaged with PackFoundry
''';
  }

  Future<_RpmVersion> _readRpmVersion(BuildConfiguration configuration) async {
    final configuredVersion = _packageVersion(configuration);
    if (configuredVersion != null) {
      return _rpmVersionFromRaw(configuredVersion);
    }

    final pubspec = File(_joinPath(configuration.projectPath, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      return const _RpmVersion(version: '1.0.0', release: '1');
    }

    final match = RegExp(
      r'^version:\s*([^\s#]+)',
      multiLine: true,
    ).firstMatch(await pubspec.readAsString());
    final rawVersion = match?.group(1)?.trim();
    if (rawVersion == null || rawVersion.isEmpty) {
      return const _RpmVersion(version: '1.0.0', release: '1');
    }
    return _rpmVersionFromRaw(rawVersion);
  }

  _RpmVersion _rpmVersionFromRaw(String rawVersion) {
    final normalizedRaw = _normalizeReleaseVersion(rawVersion);
    final parts = normalizedRaw.split('+');
    final version = parts.first.replaceAll(RegExp(r'[^A-Za-z0-9._~]'), '.');
    final release = parts.length > 1
        ? parts[1].replaceAll(RegExp(r'[^A-Za-z0-9._~]'), '.')
        : '1';
    return _RpmVersion(
      version: version.isEmpty ? '1.0.0' : version,
      release: release.isEmpty ? '1' : release,
    );
  }

  Future<File?> _findFirstFileWithExtension(
    Directory directory,
    String extension,
  ) async {
    if (!directory.existsSync()) {
      return null;
    }

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.toLowerCase().endsWith(extension)) {
        return entity;
      }
    }
    return null;
  }

  Future<File> _writeFallbackRpmIcon(
    Directory assetsDirectory,
    String packageName,
  ) async {
    final fallbackIcon = File(
      _joinPath(assetsDirectory.path, '$packageName.svg'),
    );
    await fallbackIcon.writeAsString(
      '''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <rect width="256" height="256" rx="48" fill="#0EA5A4"/>
  <path d="M64 80h86a42 42 0 0 1 0 84H96v44H64V80Zm32 28v28h50a14 14 0 0 0 0-28H96Z" fill="#ffffff"/>
</svg>
''',
    );
    return fallbackIcon;
  }

  String _rpmArchitecture() {
    final architecture = Process.runSync('uname', [
      '-m',
    ]).stdout.toString().trim();
    return switch (architecture) {
      'x86_64' => 'x86_64',
      'aarch64' => 'aarch64',
      'arm64' => 'aarch64',
      final value when value.isNotEmpty => value,
      _ => 'x86_64',
    };
  }

  String _rpmHeaderValue(String value) {
    return value.replaceAll('\n', ' ').replaceAll('\r', ' ');
  }

  String _rpmDescription(String value) {
    final description = _rpmHeaderValue(value).trim();
    return description.isEmpty ? 'Flutter application' : description;
  }

  String _rpmChangelogDate() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    final weekday = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][now.weekday - 1];
    return '$weekday ${months[now.month - 1]} ${now.day} ${now.year}';
  }

  String _shellQuote(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }

  Stream<BuildEvent> _createDebPackageWithDocker({
    required BuildConfiguration configuration,
    required Directory workspace,
    required Directory outputDirectory,
  }) async* {
    final runtime = await _builderEnvironmentService.resolveRuntime();
    if (runtime == null) {
      yield const BuildEvent.log(
        BuildLogEntry(
          title: 'deb packaging failed',
          detail: 'Docker or Podman was not found in PATH.',
          state: BuildLogState.warning,
        ),
      );
      return;
    }

    final imageStatus = await _builderImageAvailable(
      runtime,
      BuilderEnvironment.debBookworm,
    );
    if (!imageStatus) {
      yield BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepDebContainer,
          state: BuildRoadmapStepState.warning,
          progress: 100,
          detail:
              '${BuilderEnvironment.debBookworm.imageTag} is not installed. Install the DEB builder in Settings first.',
        ),
      );
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'deb builder is not installed',
          detail:
              'Install ${BuilderEnvironment.debBookworm.imageTag} from Settings to enable reproducible DEB builds.',
          state: BuildLogState.warning,
        ),
      );
      return;
    }

    final appName = configuration.appName.trim().isEmpty
        ? 'Flutter App'
        : configuration.appName.trim();
    final packageName = _slugify(appName);
    final desktopFileId = _linuxDesktopFileId(appName);
    final version = await _readDebianVersion(workspace, configuration);
    final iconPath = await _copyIconIntoWorkspace(
      workspace: workspace,
      iconPath: configuration.iconPath,
    );
    final outputFileName = '${_safeFileName(appName)}_$version';
    final dockerArguments = [
      'run',
      '--rm',
      '-v',
      '${workspace.path}:/work',
      '-v',
      '${outputDirectory.path}:/out',
      '-v',
      '${BuilderEnvironment.debBookworm.cacheVolume}:/root/.pub-cache',
      '-e',
      'PACKFOUNDRY_APP_NAME=${_dockerEnvValue(appName)}',
      '-e',
      'PACKFOUNDRY_PACKAGE_NAME=$packageName',
      '-e',
      'PACKFOUNDRY_DESKTOP_FILE_ID=$desktopFileId',
      '-e',
      'PACKFOUNDRY_VERSION=$version',
      '-e',
      'PACKFOUNDRY_MAINTAINER=${_dockerEnvValue(_debianMaintainer(configuration))}',
      '-e',
      'PACKFOUNDRY_DESCRIPTION=${_dockerEnvValue(_packageDescription(configuration, appName))}',
      '-e',
      'PACKFOUNDRY_HOMEPAGE=${_dockerEnvValue(configuration.homepageUrl.trim())}',
      '-e',
      'PACKFOUNDRY_DEB_DEPENDS=${_dockerEnvValue(_packageDependencies(configuration, type: 'deb', defaults: const ['libgtk-3-0', 'libstdc++6', 'liblzma5']))}',
      '-e',
      'PACKFOUNDRY_OUTPUT_BASENAME=${_dockerEnvValue(outputFileName)}',
      if (iconPath != null) ...[
        '-e',
        'PACKFOUNDRY_ICON_PATH=${_dockerEnvValue(iconPath)}',
      ],
      BuilderEnvironment.debBookworm.imageTag,
      'bash',
      '-lc',
      _debDockerScript,
    ];

    yield BuildEvent.log(
      BuildLogEntry(
        title: 'Starting Debian builder',
        detail:
            '${runtime.name} run --rm ${BuilderEnvironment.debBookworm.imageTag}',
        state: BuildLogState.running,
      ),
    );

    final process = await Process.start(
      runtime.executable,
      dockerArguments,
      runInShell: false,
    );
    final outputTail = _OutputTail(maxLines: 80);
    final outputLines = _processLines(process);
    String? debPath;
    String? activeDebRoadmapStepId;

    await for (final line in outputLines) {
      outputTail.add(line.line);
      final debStep = _parseDebProgressLine(line.line);
      if (debStep == null) {
        continue;
      }

      yield BuildEvent.progress(debStep.progress);
      final roadmapStepId = _debRoadmapStepId(debStep.progress);
      if (activeDebRoadmapStepId != null &&
          activeDebRoadmapStepId != roadmapStepId) {
        yield BuildEvent.roadmapUpdate(
          BuildRoadmapUpdate(
            id: activeDebRoadmapStepId,
            state: BuildRoadmapStepState.success,
            progress: 100,
            detail: 'Step completed.',
          ),
        );
      }
      activeDebRoadmapStepId = roadmapStepId;
      yield BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: roadmapStepId,
          state: BuildRoadmapStepState.running,
          progress: _debRoadmapProgress(debStep.progress),
          detail: debStep.detail,
        ),
      );
      yield BuildEvent.log(
        BuildLogEntry(
          title: debStep.title,
          detail: debStep.detail,
          state: BuildLogState.running,
        ),
      );
      if (debStep.artifactPath != null) {
        debPath = debStep.artifactPath;
      }
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      yield BuildEvent.roadmapUpdate(
        BuildRoadmapUpdate(
          id: _stepDebPackage,
          state: BuildRoadmapStepState.warning,
          progress: 100,
          detail: outputTail.text.isEmpty
              ? 'Docker exited with code $exitCode.'
              : outputTail.text,
        ),
      );
      yield BuildEvent.log(
        BuildLogEntry(
          title: 'deb packaging failed',
          detail: outputTail.text.isEmpty
              ? 'Docker exited with code $exitCode.'
              : outputTail.text,
          state: BuildLogState.warning,
        ),
      );
      return;
    }

    yield BuildEvent.roadmapUpdate(
      BuildRoadmapUpdate(
        id: _stepDebPackage,
        state: BuildRoadmapStepState.success,
        progress: 100,
        detail: debPath ?? '${_safeFileName(appName)}_$version.deb',
      ),
    );
    yield BuildEvent.progress(95);
    yield BuildEvent.log(
      BuildLogEntry(
        title: 'Created deb package',
        detail: debPath ?? '${_safeFileName(appName)}_$version.deb',
        state: BuildLogState.success,
      ),
    );
  }

  static const _debDockerScript = r'''
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

pf_step() {
  printf 'PACKFOUNDRY_STEP|%s|%s|%s\n' "$1" "$2" "$3"
}

pf_step 62 "DEB builder ready" "Using cached PackFoundry Debian builder with Flutter SDK and Linux packaging tools."
export PATH=/opt/flutter/bin:$PATH
git config --global --add safe.directory /opt/flutter
git config --global --add safe.directory /work

cd /work
rm -rf build/linux
pf_step 70 "Resolve Flutter dependencies" "Running flutter pub get with persistent PackFoundry pub-cache."
flutter pub get
pf_step 78 "Compile Debian Linux bundle" "Running flutter build linux --release inside the Debian builder."
flutter build linux --release

bundle="$(find build/linux -type d -path '*/release/bundle' | head -n 1)"
if [ -z "$bundle" ]; then
  echo "Flutter Linux bundle was not found" >&2
  exit 30
fi

pf_step 86 "Create Debian package layout" "Writing DEBIAN/control, desktop entry and icon files."
arch="$(dpkg --print-architecture)"
package_root="/tmp/${PACKFOUNDRY_PACKAGE_NAME}_${PACKFOUNDRY_VERSION}_${arch}"
rm -rf "$package_root"
mkdir -p \
  "$package_root/DEBIAN" \
  "$package_root/opt/$PACKFOUNDRY_PACKAGE_NAME" \
  "$package_root/usr/share/applications" \
  "$package_root/usr/share/icons/hicolor/scalable/apps" \
  "$package_root/usr/share/icons/hicolor/256x256/apps"

cp -a "$bundle/." "$package_root/opt/$PACKFOUNDRY_PACKAGE_NAME/"
if [ -n "${PACKFOUNDRY_ICON_PATH:-}" ] && [ -f "/work/$PACKFOUNDRY_ICON_PATH" ]; then
  case "$PACKFOUNDRY_ICON_PATH" in
    *.svg|*.SVG)
      cp "/work/$PACKFOUNDRY_ICON_PATH" "$package_root/opt/$PACKFOUNDRY_PACKAGE_NAME/pack_foundry_window_icon.svg"
      ;;
    *)
      cp "/work/$PACKFOUNDRY_ICON_PATH" "$package_root/opt/$PACKFOUNDRY_PACKAGE_NAME/pack_foundry_window_icon.png"
      ;;
  esac
fi
executable="$(find "$package_root/opt/$PACKFOUNDRY_PACKAGE_NAME" -maxdepth 1 -type f -perm /111 ! -name '*.so' | head -n 1)"
if [ -z "$executable" ]; then
  echo "Bundle executable was not found" >&2
  exit 31
fi
chmod 755 "$executable"

cat > "$package_root/DEBIAN/control" <<EOF
Package: $PACKFOUNDRY_PACKAGE_NAME
Version: $PACKFOUNDRY_VERSION
Section: utils
Priority: optional
Architecture: $arch
Maintainer: $PACKFOUNDRY_MAINTAINER
Depends: $PACKFOUNDRY_DEB_DEPENDS
Description: $PACKFOUNDRY_DESCRIPTION
 Packaged with PackFoundry.
EOF
if [ -n "${PACKFOUNDRY_HOMEPAGE:-}" ]; then
  printf 'Homepage: %s\n' "$PACKFOUNDRY_HOMEPAGE" >> "$package_root/DEBIAN/control"
fi

cat > "$package_root/usr/share/applications/$PACKFOUNDRY_DESKTOP_FILE_ID.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$PACKFOUNDRY_APP_NAME
Exec=/opt/$PACKFOUNDRY_PACKAGE_NAME/$(basename "$executable")
Icon=$PACKFOUNDRY_DESKTOP_FILE_ID
StartupWMClass=$PACKFOUNDRY_PACKAGE_NAME
Categories=Utility;
Terminal=false
EOF

if [ -n "${PACKFOUNDRY_ICON_PATH:-}" ] && [ -f "/work/$PACKFOUNDRY_ICON_PATH" ]; then
  case "$PACKFOUNDRY_ICON_PATH" in
    *.svg|*.SVG)
      cp "/work/$PACKFOUNDRY_ICON_PATH" "$package_root/usr/share/icons/hicolor/scalable/apps/$PACKFOUNDRY_DESKTOP_FILE_ID.svg"
      ;;
    *)
      cp "/work/$PACKFOUNDRY_ICON_PATH" "$package_root/usr/share/icons/hicolor/256x256/apps/$PACKFOUNDRY_DESKTOP_FILE_ID.png"
      ;;
  esac
else
  cat > "$package_root/usr/share/icons/hicolor/scalable/apps/$PACKFOUNDRY_DESKTOP_FILE_ID.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <rect width="256" height="256" rx="48" fill="#0EA5A4"/>
  <path d="M64 80h86a42 42 0 0 1 0 84H96v44H64V80Zm32 28v28h50a14 14 0 0 0 0-28H96Z" fill="#ffffff"/>
</svg>
EOF
fi

pf_step 91 "Build DEB archive" "Running dpkg-deb --build for the package root."
deb_path="/out/${PACKFOUNDRY_OUTPUT_BASENAME}_${arch}.deb"
rm -f "$deb_path"
dpkg-deb --build --root-owner-group "$package_root" "$deb_path"
pf_step 94 "Export DEB artifact" "$deb_path"
echo "$deb_path"
''';

  Future<File> _resolveAppImageTool() async {
    final systemTool = await _findExecutable('appimagetool');
    if (systemTool != null) {
      return systemTool;
    }

    final toolsDirectory = Directory(
      _joinPath(_userCacheDirectory().path, 'pack_foundry/tools'),
    );
    await toolsDirectory.create(recursive: true);

    final architecture = _appImageArchitecture();
    final toolFile = File(
      _joinPath(toolsDirectory.path, 'appimagetool-$architecture.AppImage'),
    );
    if (!toolFile.existsSync()) {
      await _downloadFile(
        Uri.parse('$_appImageToolBaseUrl/appimagetool-$architecture.AppImage'),
        toolFile,
      );
    }
    await _makeExecutable(toolFile);
    return toolFile;
  }

  Stream<_ProcessLine> _processLines(Process process) {
    final controller = StreamController<_ProcessLine>();
    var openStreams = 2;

    void closeWhenReady() {
      openStreams -= 1;
      if (openStreams == 0) {
        unawaited(controller.close());
      }
    }

    void addLine(String source, String line) {
      if (!controller.isClosed) {
        controller.add(_ProcessLine(source: source, line: line));
      }
    }

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) => addLine('stdout', line),
          onError: controller.addError,
          onDone: closeWhenReady,
          cancelOnError: false,
        );
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) => addLine('stderr', line),
          onError: controller.addError,
          onDone: closeWhenReady,
          cancelOnError: false,
        );

    return controller.stream;
  }

  String _debRoadmapStepId(int debProgress) {
    if (debProgress < 78) {
      return _stepDebContainer;
    }
    if (debProgress < 86) {
      return _stepDebBuild;
    }
    return _stepDebPackage;
  }

  int _debRoadmapProgress(int debProgress) {
    if (debProgress < 78) {
      return ((debProgress - 60).clamp(0, 18) / 18 * 100).round();
    }
    if (debProgress < 86) {
      return ((debProgress - 78).clamp(0, 8) / 8 * 100).round();
    }
    return ((debProgress - 86).clamp(0, 8) / 8 * 100).round();
  }

  _DebProgressStep? _parseDebProgressLine(String line) {
    if (!line.startsWith('PACKFOUNDRY_STEP|')) {
      return null;
    }

    final parts = line.split('|');
    if (parts.length < 4) {
      return null;
    }

    final progress = int.tryParse(parts[1]);
    if (progress == null) {
      return null;
    }

    final title = parts[2].trim();
    final detail = parts.sublist(3).join('|').trim();
    return _DebProgressStep(
      progress: progress.clamp(0, 100),
      title: title.isEmpty ? 'Packaging deb' : title,
      detail: detail,
      artifactPath: progress >= 94 ? detail : null,
    );
  }

  Future<String> _readDebianVersion(
    Directory workspace,
    BuildConfiguration configuration,
  ) async {
    final configuredVersion = _packageVersion(configuration);
    if (configuredVersion != null) {
      final debianVersion = _normalizeReleaseVersion(
        configuredVersion,
      ).replaceAll(RegExp(r'[^A-Za-z0-9.+:~_-]'), '');
      return debianVersion.isEmpty ? '1.0.0' : debianVersion;
    }
    final pubspec = File(_joinPath(workspace.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      return '1.0.0';
    }

    final match = RegExp(
      r'^version:\s*([^\s#]+)',
      multiLine: true,
    ).firstMatch(await pubspec.readAsString());
    final version = match?.group(1)?.trim();
    if (version == null || version.isEmpty) {
      return '1.0.0';
    }

    final debianVersion = version.replaceAll(RegExp(r'[^A-Za-z0-9.+:~_-]'), '');
    return debianVersion.isEmpty ? '1.0.0' : debianVersion;
  }

  Future<bool> _builderImageAvailable(
    ContainerRuntime runtime,
    BuilderEnvironment builder,
  ) async {
    final result = await Process.run(
      runtime.executable,
      ['image', 'inspect', builder.imageTag],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return result.exitCode == 0;
  }

  Future<String?> _copyIconIntoWorkspace({
    required Directory workspace,
    required String? iconPath,
  }) async {
    if (iconPath == null || iconPath.isEmpty) {
      return null;
    }

    final source = File(iconPath);
    if (!source.existsSync()) {
      return null;
    }

    final extension = _extension(source.path).toLowerCase() == '.svg'
        ? '.svg'
        : '.png';
    final assetsDirectory = Directory(
      _joinPath(workspace.path, '.pack_foundry'),
    );
    await assetsDirectory.create(recursive: true);
    final destination = File(_joinPath(assetsDirectory.path, 'icon$extension'));
    await source.copy(destination.path);
    return '.pack_foundry/icon$extension';
  }

  Future<void> _copySelectedIconToLinuxBundle({
    required Directory bundleDirectory,
    required String? iconPath,
  }) async {
    final preparedIcon = await _copyPackageIcon(
      assetsDirectory: bundleDirectory,
      iconPath: iconPath,
      fileNameWithoutExtension: 'pack_foundry_window_icon',
    );
    if (preparedIcon == null) {
      return;
    }

    final extension = _extension(preparedIcon.path).toLowerCase();
    final otherExtension = extension == '.svg' ? '.png' : '.svg';
    final staleIcon = File(
      _joinPath(
        bundleDirectory.path,
        'pack_foundry_window_icon$otherExtension',
      ),
    );
    if (staleIcon.existsSync()) {
      await staleIcon.delete();
    }
  }

  Future<File?> _copyPackageIcon({
    required Directory assetsDirectory,
    required String? iconPath,
    required String fileNameWithoutExtension,
  }) async {
    if (iconPath == null || iconPath.isEmpty) {
      return null;
    }

    final source = File(iconPath);
    if (!source.existsSync()) {
      return null;
    }

    await assetsDirectory.create(recursive: true);
    final extension = _extension(source.path).toLowerCase() == '.svg'
        ? '.svg'
        : '.png';
    final destination = File(
      _joinPath(assetsDirectory.path, '$fileNameWithoutExtension$extension'),
    );
    await source.copy(destination.path);
    return destination;
  }

  String _dockerEnvValue(String value) {
    return value.replaceAll('\n', ' ').replaceAll('\r', ' ');
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

  Future<File?> _findBundleExecutable(Directory bundleDirectory) async {
    final files = await bundleDirectory
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
    for (final file in files) {
      final name = _basename(file.path);
      if (name.contains('.') || name.endsWith('.so')) {
        continue;
      }
      if (await _isExecutable(file)) {
        return file;
      }
    }

    final executableLikeFiles = files.where(
      (file) => !_basename(file.path).contains('.'),
    );
    return executableLikeFiles.isEmpty ? null : executableLikeFiles.first;
  }

  Future<bool> _isExecutable(File file) async {
    final stat = await file.stat();
    return stat.mode & 0x49 != 0;
  }

  Future<void> _writeAppRun({
    required Directory appDir,
    required String executableName,
  }) async {
    final appRun = File(_joinPath(appDir.path, 'AppRun'));
    await appRun.writeAsString('''#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\$0")")"
exec "\$HERE/usr/bin/$executableName" "\$@"
''');
    await _makeExecutable(appRun);
  }

  Future<void> _writeDesktopFile({
    required Directory appDir,
    required String appName,
    required String desktopFileId,
    required String windowClass,
  }) async {
    final desktopFile = File(_joinPath(appDir.path, '$desktopFileId.desktop'));
    await desktopFile.writeAsString('''[Desktop Entry]
Type=Application
Name=${_escapeDesktopValue(appName)}
Exec=AppRun
Icon=$desktopFileId
StartupWMClass=$windowClass
Categories=Utility;
Terminal=false
''');
  }

  Future<void> _prepareAppIcon({
    required Directory appDir,
    required String iconName,
    required String? iconPath,
  }) async {
    final source = iconPath == null ? null : File(iconPath);
    if (source != null && source.existsSync()) {
      final extension = _extension(source.path).toLowerCase();
      final normalizedExtension = extension == '.svg' ? '.svg' : '.png';
      final iconFile = File(
        _joinPath(appDir.path, '$iconName$normalizedExtension'),
      );
      await source.copy(iconFile.path);
      await source.copy(_joinPath(appDir.path, '.DirIcon'));
      return;
    }

    final fallbackIcon = File(_joinPath(appDir.path, '$iconName.svg'));
    await fallbackIcon.writeAsString(
      '''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <rect width="256" height="256" rx="48" fill="#0EA5A4"/>
  <path d="M64 80h86a42 42 0 0 1 0 84H96v44H64V80Zm32 28v28h50a14 14 0 0 0 0-28H96Z" fill="#ffffff"/>
</svg>
''',
    );
    await fallbackIcon.copy(_joinPath(appDir.path, '.DirIcon'));
  }

  Future<ProcessResult> _runFlutterBuild(String projectPath) async {
    final candidates = [
      'flutter',
      if (_managedFlutterExecutable().existsSync())
        _managedFlutterExecutable().path,
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

  Future<ProcessResult> _runFlutterApkBuild(String projectPath) async {
    final candidates = [
      'flutter',
      if (_managedFlutterExecutable().existsSync())
        _managedFlutterExecutable().path,
    ];

    ProcessException? lastError;
    for (final executable in candidates) {
      try {
        return await Process.run(
          executable,
          ['build', 'apk', '--release'],
          workingDirectory: projectPath,
          runInShell: true,
          environment: _androidBuildEnvironment(),
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
          'apk',
          '--release',
        ], 'Flutter executable was not found.');
  }

  File? _findReleaseApk(Directory projectDirectory) {
    final standardApk = File(
      _joinPath(
        projectDirectory.path,
        'build/app/outputs/flutter-apk/app-release.apk',
      ),
    );
    if (standardApk.existsSync()) {
      return standardApk;
    }

    final outputDirectory = Directory(
      _joinPath(projectDirectory.path, 'build/app/outputs'),
    );
    if (!outputDirectory.existsSync()) {
      return null;
    }

    for (final entity in outputDirectory.listSync(recursive: true)) {
      if (entity is File &&
          entity.path.endsWith('.apk') &&
          _basename(entity.path).contains('release')) {
        return entity;
      }
    }
    return null;
  }

  Map<String, String>? _androidBuildEnvironment() {
    final sdkRoot =
        Platform.environment['ANDROID_HOME'] ??
        Platform.environment['ANDROID_SDK_ROOT'];
    if (sdkRoot != null && sdkRoot.isNotEmpty) {
      return null;
    }

    final managedSdk = _managedAndroidSdkDirectory();
    if (!managedSdk.existsSync()) {
      return null;
    }
    return {
      ...Platform.environment,
      'ANDROID_HOME': managedSdk.path,
      'ANDROID_SDK_ROOT': managedSdk.path,
    };
  }

  File _managedFlutterExecutable() {
    return File(
      _joinPath(
        _joinPath(_userDataDirectory().path, 'pack_foundry/flutter/bin'),
        'flutter',
      ),
    );
  }

  Directory _managedAndroidSdkDirectory() {
    return Directory(
      _joinPath(_userDataDirectory().path, 'pack_foundry/android-sdk'),
    );
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

  Future<void> _makeExecutable(File file) async {
    if (!Platform.isLinux && !Platform.isMacOS) {
      return;
    }
    await Process.run('chmod', ['755', file.path]);
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

  String _appImageArchitecture() {
    final architecture = Process.runSync('uname', [
      '-m',
    ]).stdout.toString().trim();
    return switch (architecture) {
      'aarch64' => 'aarch64',
      'arm64' => 'aarch64',
      _ => 'x86_64',
    };
  }

  String _publisherName(BuildConfiguration configuration) {
    final value = configuration.publisherName.trim();
    return value.isEmpty ? 'PackFoundry' : value;
  }

  String _developerEmail(BuildConfiguration configuration) {
    final value = configuration.developerEmail.trim();
    return value.isEmpty ? 'packfoundry@localhost' : value;
  }

  String _debianMaintainer(BuildConfiguration configuration) {
    return '${_publisherName(configuration)} <${_developerEmail(configuration)}>';
  }

  String _packageLicense(BuildConfiguration configuration) {
    final value = configuration.license.trim();
    return value.isEmpty ? 'GPL-2.0-only' : value;
  }

  String _packageSummary(
    BuildConfiguration configuration,
    String fallbackAppName,
  ) {
    final description = configuration.description.trim();
    if (description.isEmpty) {
      return fallbackAppName;
    }
    return description.split(RegExp(r'[\r\n]+')).first.trim();
  }

  String _packageDescription(
    BuildConfiguration configuration,
    String fallbackAppName,
  ) {
    final description = configuration.description.trim();
    if (description.isEmpty) {
      return '$fallbackAppName packaged with PackFoundry.';
    }
    return description
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _packageDependencies(
    BuildConfiguration configuration, {
    required String type,
    required List<String> defaults,
  }) {
    final seen = <String>{};
    final dependencies = <String>[];
    void add(String value) {
      final normalized = value.trim();
      if (normalized.isEmpty || !seen.add(normalized.toLowerCase())) {
        return;
      }
      dependencies.add(normalized);
    }

    for (final dependency in defaults) {
      add(dependency);
    }
    final extra = configuration.additionalDependencies[type] ?? '';
    for (final dependency in _splitDependencyInput(extra)) {
      add(dependency);
    }
    return dependencies.join(', ');
  }

  List<String> _splitDependencyInput(String value) {
    final withoutFieldName = value.replaceFirst(
      RegExp(r'^\s*(Depends|Requires)\s*:', caseSensitive: false),
      '',
    );
    return [
      for (final part
          in withoutFieldName.replaceAll('\r\n', '\n').split(RegExp(r'[\n,]')))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  String? _packageVersion(
    BuildConfiguration configuration, {
    String? fallback,
  }) {
    final value = configuration.releaseTag.trim();
    if (value.isEmpty) {
      return fallback;
    }
    return _normalizeReleaseVersion(value);
  }

  String _normalizeReleaseVersion(String value) {
    final trimmed = value.trim();
    if (trimmed.length > 1 &&
        (trimmed.startsWith('v') || trimmed.startsWith('V')) &&
        RegExp(r'\d').hasMatch(trimmed[1])) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  String _safeFileName(String value) {
    final fileName = value.trim().replaceAll(RegExp(r'[\\/\x00]+'), '-');
    return fileName.isEmpty ? 'Flutter App' : fileName;
  }

  String _slugify(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'flutter-app' : slug;
  }

  String _linuxDesktopFileId(String appName) {
    return 'dev.packfoundry.${_dbusIdPart(appName)}';
  }

  String _dbusIdPart(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final fallback = normalized.isEmpty ? 'flutter_app' : normalized;
    if (RegExp(r'^[a-z_]').hasMatch(fallback)) {
      return fallback;
    }
    return 'app_$fallback';
  }

  String _escapeDesktopValue(String value) {
    return value.replaceAll('\n', ' ').replaceAll('\r', ' ');
  }

  String _cStringLiteral(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
  }

  String _extension(String path) {
    final name = _basename(path);
    final dotIndex = name.lastIndexOf('.');
    return dotIndex == -1 ? '' : name.substring(dotIndex);
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

class _RpmVersion {
  const _RpmVersion({required this.version, required this.release});

  final String version;
  final String release;
}

class _ProcessLine {
  const _ProcessLine({required this.source, required this.line});

  final String source;
  final String line;
}

class _DebProgressStep {
  const _DebProgressStep({
    required this.progress,
    required this.title,
    required this.detail,
    required this.artifactPath,
  });

  final int progress;
  final String title;
  final String detail;
  final String? artifactPath;
}

class _OutputTail {
  _OutputTail({required this.maxLines});

  final int maxLines;
  final List<String> _lines = [];

  void add(String line) {
    if (line.trim().isEmpty) {
      return;
    }
    _lines.add(line);
    if (_lines.length > maxLines) {
      _lines.removeAt(0);
    }
  }

  String get text => _lines.join('\n');
}

class _CleanupResult {
  const _CleanupResult({required this.deleted, required this.message});

  final bool deleted;
  final String message;
}

class _BuildWorkspace {
  const _BuildWorkspace({required this.tempDirectory, required this.workspace});

  final Directory tempDirectory;
  final Directory workspace;
}

class BuildEvent {
  const BuildEvent.log(BuildLogEntry this.logEntry)
    : progress = null,
      roadmapPlan = null,
      roadmapUpdate = null;

  const BuildEvent.progress(int this.progress)
    : logEntry = null,
      roadmapPlan = null,
      roadmapUpdate = null;

  const BuildEvent.roadmapPlan(List<BuildRoadmapStep> this.roadmapPlan)
    : logEntry = null,
      progress = null,
      roadmapUpdate = null;

  const BuildEvent.roadmapUpdate(BuildRoadmapUpdate this.roadmapUpdate)
    : logEntry = null,
      progress = null,
      roadmapPlan = null;

  final BuildLogEntry? logEntry;
  final int? progress;
  final List<BuildRoadmapStep>? roadmapPlan;
  final BuildRoadmapUpdate? roadmapUpdate;
}
