import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/build_configuration.dart';
import '../../core/models/build_log_entry.dart';
import '../../core/models/build_target.dart';
import '../../core/models/chip_tone.dart';
import '../../core/models/builder_environment.dart';
import '../../core/models/config_preset.dart';
import '../../core/models/package_inspection.dart';
import '../../core/models/project_config.dart';
import '../../core/models/tool_status.dart';
import '../../core/services/android_device_service.dart';
import '../../core/services/app_preferences.dart';
import '../../core/services/build_service.dart';
import '../../core/services/builder_environment_service.dart';
import '../../core/services/flutter_locator.dart';
import '../../core/services/package_inspector_service.dart';
import '../../core/services/project_config_service.dart';
import '../../core/services/project_icon_finder.dart';
import '../../core/services/project_platforms.dart';
import '../../core/services/toolchain_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_settings_panel.dart';
import '../widgets/build_panel.dart';
import '../widgets/config_presets_panel.dart';
import '../widgets/preferences_panel.dart';
import '../widgets/project_panel.dart';
import '../widgets/installer_settings_panel.dart';
import '../widgets/package_dependencies_panel.dart';
import '../widgets/package_inspector_panel.dart';
import '../widgets/toolchain_panel.dart';
import '../widgets/welcome_dialog.dart';

class PackFoundryHomePage extends StatefulWidget {
  const PackFoundryHomePage({
    required this.themeMode,
    required this.localeMode,
    required this.showWelcome,
    required this.onThemeModeChanged,
    required this.onLocaleModeChanged,
    required this.onWelcomeCompleted,
    required this.enableToolchainDiagnostics,
    super.key,
  });

  final ThemeMode themeMode;
  final AppLocaleMode localeMode;
  final bool showWelcome;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<AppLocaleMode> onLocaleModeChanged;
  final WelcomeCompleted onWelcomeCompleted;
  final bool enableToolchainDiagnostics;

  @override
  State<PackFoundryHomePage> createState() => _PackFoundryHomePageState();
}

class _PackFoundryHomePageState extends State<PackFoundryHomePage>
    with SingleTickerProviderStateMixin {
  static const _defaultAppName = 'My Flutter App';
  static const _workspaceCount = 4;

  final _buildService = BuildService();
  final _toolchainService = ToolchainService();
  final _builderService = BuilderEnvironmentService();
  final _packageInspectorService = const PackageInspectorService();
  final _projectConfigService = const ProjectConfigService();
  final _androidDeviceService = AndroidDeviceService();
  final _appPreferences = AppPreferences();
  final _appNameController = TextEditingController(text: _defaultAppName);
  final _projectPathController = TextEditingController();
  final _releaseTagController = TextEditingController();
  final _developerEmailController = TextEditingController();
  final _publisherNameController = TextEditingController();
  final _homepageUrlController = TextEditingController();
  final _licenseController = TextEditingController(text: 'GPL-2.0-only');
  final _descriptionController = TextEditingController();
  final _widthController = TextEditingController(text: '1280');
  final _heightController = TextEditingController(text: '800');
  final _debAdditionalDependenciesController = TextEditingController();
  final _rpmAdditionalDependenciesController = TextEditingController();
  final _pacmanAdditionalDependenciesController = TextEditingController();
  final _packageMetadataController = TextEditingController();
  final _packageDependenciesController = TextEditingController();
  final _buildLog = <BuildLogEntry>[];
  final _roadmapSteps = <BuildRoadmapStep>[];
  final _projectChecks = <ProjectCheck>[];
  final _configPresets = <ConfigPreset>[];
  Timer? _metadataSaveTimer;
  bool _metadataListenersAttached = false;

  String? _projectPath;
  String? _activeConfigPath;
  String? _iconPath;

  /// True while [_iconPath] was found in the project rather than chosen by
  /// the user or a config, so switching projects may replace it.
  bool _iconAutoDetected = false;
  String? _outputPath;
  PackageInspection? _packageInspection;
  bool _isBuilding = false;
  bool _isRunningProject = false;

  /// Whether the selected project has a desktop runner. Without one there is
  /// nothing `flutter run` could launch, so the run action stays hidden.
  bool _hasDesktopRunner = false;
  bool _isSendingToDevice = false;

  /// Short progress line shown next to the send action, because its technical
  /// log lives on another workspace tab.
  String? _sendToDeviceStatus;
  Process? _sendToDeviceProcess;
  bool _sendToDeviceCancelled = false;
  bool _isInspectingPackage = false;
  ToolchainInstallTarget? _installingToolTarget;
  int _buildProgress = 0;
  bool _welcomeDialogShown = false;
  int _workspaceIndex = 1;
  late final TabController _workspaceTabController;
  ToolAvailability _flutterStatus = ToolAvailability.available;
  ToolAvailability _gitStatus = ToolAvailability.available;
  ToolAvailability _archiveToolsStatus = ToolAvailability.available;
  ToolAvailability _linuxToolchainStatus = ToolAvailability.available;
  ToolAvailability _containerRuntimeStatus = ToolAvailability.available;
  String? _containerRuntimeName;
  ToolInstallProgress? _installProgress;
  bool _toolInstallCancelRequested = false;
  ToolAvailability _debBuilderStatus = ToolAvailability.available;
  ToolAvailability _rpmBuilderStatus = ToolAvailability.available;
  ToolAvailability _appImageToolStatus = ToolAvailability.available;
  ToolAvailability _debToolStatus = ToolAvailability.available;
  ToolAvailability _rpmToolStatus = ToolAvailability.available;
  ToolAvailability _makepkgStatus = ToolAvailability.available;

  /// False until the first toolchain probe finishes; targets keep their
  /// optimistic defaults until then.
  bool _toolchainChecked = false;
  ToolAvailability _fakerootStatus = ToolAvailability.available;
  ToolAvailability _tarToolStatus = ToolAvailability.available;
  ToolAvailability _zipToolStatus = ToolAvailability.available;
  ToolAvailability _javaStatus = ToolAvailability.available;
  ToolAvailability _androidSdkStatus = ToolAvailability.available;
  Process? _runningProjectProcess;

  final List<BuildTarget> _targets = [
    BuildTarget(
      platform: 'Linux',
      artifact: 'AppImage',
      status: TargetStatus.ready,
    ),
    BuildTarget(
      platform: 'Linux',
      artifact: 'deb package',
      status: TargetStatus.ready,
    ),
    BuildTarget(
      platform: 'Linux',
      artifact: 'rpm package',
      status: TargetStatus.ready,
    ),
    BuildTarget(
      platform: 'Linux',
      artifact: 'pacman package',
      status: TargetStatus.ready,
    ),
    BuildTarget(
      platform: 'Linux',
      artifact: 'tar.gz bundle',
      status: TargetStatus.ready,
    ),
    BuildTarget(
      platform: 'Windows',
      artifact: 'Inno Setup exe',
      status: TargetStatus.installable,
    ),
    BuildTarget(
      platform: 'Android',
      artifact: 'APK',
      status: TargetStatus.installable,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _workspaceTabController = TabController(
      length: _workspaceCount,
      initialIndex: _workspaceIndex,
      vsync: this,
    );
    _workspaceTabController.addListener(_handleWorkspaceTabChanged);
    _loadReleaseMetadata();
    _loadConfigPresets();
    if (widget.enableToolchainDiagnostics) {
      _refreshToolchainStatus();
    }
  }

  void _handleWorkspaceTabChanged() {
    final index = _workspaceTabController.index;
    if (index == _workspaceIndex) {
      return;
    }
    setState(() {
      _workspaceIndex = index;
    });
  }

  Future<void> _loadReleaseMetadata() async {
    final metadata = await _appPreferences.loadReleaseMetadata();
    if (!mounted) {
      return;
    }

    _restoreControllerText(_releaseTagController, metadata.releaseTag);
    _restoreControllerText(_developerEmailController, metadata.developerEmail);
    _restoreControllerText(_publisherNameController, metadata.publisherName);
    _restoreControllerText(_homepageUrlController, metadata.homepageUrl);
    _restoreControllerText(_descriptionController, metadata.description);
    _attachMetadataListeners();
  }

  void _restoreControllerText(
    TextEditingController controller,
    String savedValue,
  ) {
    if (controller.text.isEmpty && savedValue.isNotEmpty) {
      controller.text = savedValue;
    }
  }

  void _attachMetadataListeners() {
    if (_metadataListenersAttached) {
      return;
    }
    for (final controller in _metadataControllers) {
      controller.addListener(_scheduleReleaseMetadataSave);
    }
    _metadataListenersAttached = true;
  }

  List<TextEditingController> get _metadataControllers => [
    _releaseTagController,
    _developerEmailController,
    _publisherNameController,
    _homepageUrlController,
    _descriptionController,
  ];

  void _scheduleReleaseMetadataSave() {
    _metadataSaveTimer?.cancel();
    _metadataSaveTimer = Timer(
      const Duration(milliseconds: 400),
      _saveReleaseMetadata,
    );
  }

  Future<void> _saveReleaseMetadata() {
    return _appPreferences.saveReleaseMetadata(
      SavedReleaseMetadata(
        releaseTag: _releaseTagController.text,
        developerEmail: _developerEmailController.text,
        publisherName: _publisherNameController.text,
        homepageUrl: _homepageUrlController.text,
        description: _descriptionController.text,
      ),
    );
  }

  Future<void> _refreshToolchainStatus() async {
    final runtime = await _builderService.resolveRuntime();
    final results = await Future.wait([
      _toolchainService.flutterAvailability(),
      _linuxToolchainAvailable(),
      _builderService.builderAvailability(BuilderEnvironment.debBookworm),
      _builderService.builderAvailability(BuilderEnvironment.rpmFedora),
      _toolchainService.appImageToolAvailability(),
      _toolchainService.commandAvailability('dpkg-deb', ['--version']),
      _toolchainService.commandAvailability('rpmbuild', ['--version']),
      _toolchainService.commandAvailability('tar', ['--version']),
      _toolchainService.commandAvailability('zip', ['--version']),
      _toolchainService.commandAvailability('java', ['-version']),
      _toolchainService.androidSdkAvailability(),
      _toolchainService.commandAvailability('git', ['--version']),
      _archiveToolsAvailable(),
      _toolchainService.commandAvailability('makepkg', ['--version']),
      _toolchainService.commandAvailability('fakeroot', ['--version']),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _flutterStatus = results[0];
      _linuxToolchainStatus = results[1];
      _containerRuntimeStatus = runtime == null
          ? ToolAvailability.missing
          : ToolAvailability.installed;
      _containerRuntimeName = runtime?.displayName;
      _debBuilderStatus = results[2];
      _rpmBuilderStatus = results[3];
      _appImageToolStatus = results[4];
      _debToolStatus = results[5];
      _rpmToolStatus = results[6];
      _tarToolStatus = results[7];
      _zipToolStatus = results[8];
      _javaStatus = results[9];
      _androidSdkStatus = results[10];
      _gitStatus = results[11];
      _archiveToolsStatus = results[12];
      _makepkgStatus = results[13];
      _fakerootStatus = results[14];
      _toolchainChecked = true;
      _updateTargetStatuses();
    });
  }

  /// Recomputes every target from the toolchain state and the selected
  /// project. A target whose platform folder the project lacks cannot be
  /// built at all, so it is disabled before the flutter tool fails on it.
  void _updateTargetStatuses() {
    final projectPath = _projectPath;
    for (final target in _targets) {
      final missingPlatform =
          projectPath != null &&
          !ProjectPlatforms.supports(projectPath, target.platform);
      target.status = missingPlatform
          ? TargetStatus.missingPlatform
          : _toolchainTargetStatus(target);
      if (!target.canSelect) {
        target.selected = false;
      }
    }
  }

  TargetStatus _toolchainTargetStatus(BuildTarget target) {
    if (target.platform == 'Windows') {
      return TargetStatus.installable;
    }
    if (!_toolchainChecked) {
      return target.platform == 'Android'
          ? TargetStatus.installable
          : TargetStatus.ready;
    }
    if (target.platform == 'Android') {
      return _androidBuildStatus == ToolAvailability.installed
          ? TargetStatus.ready
          : TargetStatus.installable;
    }
    // pacman packages are built natively with makepkg, so only Arch-based
    // hosts can produce them.
    if (target.artifact == 'pacman package') {
      if (_hostDistribution.family != _LinuxDistributionFamily.arch) {
        return TargetStatus.hostLimited;
      }
      return _makepkgStatus == ToolAvailability.installed &&
              _fakerootStatus == ToolAvailability.installed
          ? TargetStatus.ready
          : TargetStatus.installable;
    }
    return TargetStatus.ready;
  }

  Future<ToolAvailability> _linuxToolchainAvailable() async {
    final available = await _toolchainService.allCommandsAvailable([
      const CommandCheck('clang', ['--version']),
      const CommandCheck('cmake', ['--version']),
      const CommandCheck('ninja', ['--version']),
    ]);
    return available ? ToolAvailability.installed : ToolAvailability.missing;
  }

  /// Utilities the flutter tool itself needs to fetch the Dart SDK and engine.
  Future<ToolAvailability> _archiveToolsAvailable() async {
    final available = await _toolchainService.allCommandsAvailable([
      const CommandCheck('curl', ['--version']),
      const CommandCheck('unzip', ['-v']),
      const CommandCheck('xz', ['--version']),
    ]);
    return available ? ToolAvailability.installed : ToolAvailability.missing;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_buildLog.isEmpty) {
      final l10n = context.l10n;
      _buildLog.add(
        BuildLogEntry(
          title: l10n.readyTitle,
          detail: l10n.readyDetail,
          state: BuildLogState.idle,
        ),
      );
    }
    _scheduleWelcomeDialog();
  }

  @override
  void didUpdateWidget(covariant PackFoundryHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showWelcome && widget.showWelcome) {
      _welcomeDialogShown = false;
    }
    _scheduleWelcomeDialog();
  }

  void _scheduleWelcomeDialog() {
    if (!widget.showWelcome || _welcomeDialogShown) {
      return;
    }

    _welcomeDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => WelcomeDialog(
          initialThemeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          onCompleted: widget.onWelcomeCompleted,
        ),
      );
    });
  }

  List<ToolchainGroup> _toolGroups(AppLocalizations l10n) {
    final distribution = _hostDistribution;
    final debGroup = _debBuildGroup(l10n, distribution);
    final rpmGroup = _rpmBuildGroup(l10n, distribution);
    final pacmanGroup = _pacmanBuildGroup(l10n, distribution);
    final nativePackageGroups = switch (distribution.family) {
      _LinuxDistributionFamily.deb => [debGroup, rpmGroup, pacmanGroup],
      _LinuxDistributionFamily.arch => [pacmanGroup, rpmGroup, debGroup],
      _ => [rpmGroup, debGroup, pacmanGroup],
    };

    return [
      _commonToolsGroup(l10n),
      ...nativePackageGroups,
      _appImageBuildGroup(l10n),
      _tarGzBuildGroup(l10n),
      _windowsBuildGroup(l10n),
      _androidBuildGroup(l10n),
    ];
  }

  ToolchainGroup _commonToolsGroup(AppLocalizations l10n) {
    return ToolchainGroup(
      title: l10n.commonToolsGroupTitle,
      subtitle: l10n.commonToolsGroupSubtitle,
      status: _commonToolsStatus,
      category: ToolchainCategory.common,
      installTarget: ToolchainInstallTarget.common,
      installProgress: _installProgressFor(ToolchainInstallTarget.common),
      tools: [
        _flutterTool(l10n),
        ToolStatus(
          name: 'Git',
          command: 'git',
          status: _gitStatus,
          note: l10n.gitNote,
        ),
        ToolStatus(
          name: l10n.archiveToolsName,
          command: 'curl, unzip, xz',
          status: _archiveToolsStatus,
          note: l10n.archiveToolsNote,
        ),
      ],
    );
  }

  ToolInstallProgress? _installProgressFor(ToolchainInstallTarget target) {
    return _installProgress?.target == target ? _installProgress : null;
  }

  /// Platform groups that build on the host need the common Flutter SDK.
  String? _commonToolsDependencyNote(AppLocalizations l10n) {
    return _commonToolsStatus == ToolAvailability.installed
        ? null
        : l10n.requiresCommonTools;
  }

  ToolchainGroup _debBuildGroup(
    AppLocalizations l10n,
    _HostDistribution distribution,
  ) {
    final isNativeDeb = distribution.family == _LinuxDistributionFamily.deb;
    final tools = isNativeDeb
        ? [
            _hostSystemTool(l10n, distribution),
            _linuxToolchainTool(l10n),
            ToolStatus(
              name: 'dpkg-deb',
              command: 'dpkg-deb',
              status: _debToolStatus,
              note: l10n.dpkgDebNote,
            ),
          ]
        : [
            ToolStatus(
              name: _containerRuntimeName ?? 'Container runtime',
              command:
                  _containerRuntimeName?.toLowerCase() ?? 'docker or podman',
              status: _containerRuntimeStatus,
              note: l10n.dockerDebNote,
              showCommand: false,
            ),
            ToolStatus(
              name: 'Debian builder',
              command: BuilderEnvironment.debBookworm.imageTag,
              status: _debBuilderStatus,
              note: l10n.debianBuilderNote,
            ),
          ];

    return ToolchainGroup(
      title: l10n.debBuildGroupTitle,
      subtitle: isNativeDeb
          ? l10n.debBuildNativeSubtitle(distribution.name)
          : l10n.debBuildDockerSubtitle(distribution.name),
      status: isNativeDeb ? _nativeDebBuildStatus : _dockerDebBuildStatus,
      tools: tools,
      installTarget: ToolchainInstallTarget.deb,
      canRemove:
          !isNativeDeb && _debBuilderStatus == ToolAvailability.installed,
      installProgress: _installProgressFor(ToolchainInstallTarget.deb),
      dependencyNote: isNativeDeb ? _commonToolsDependencyNote(l10n) : null,
      installSizeLabel:
          !isNativeDeb && _debBuilderStatus != ToolAvailability.installed
          ? '~5 GB'
          : null,
    );
  }

  ToolchainGroup _rpmBuildGroup(
    AppLocalizations l10n,
    _HostDistribution distribution,
  ) {
    final isNativeRpm = distribution.family == _LinuxDistributionFamily.rpm;
    final unsupportedRpm =
        distribution.family == _LinuxDistributionFamily.unsupportedRpm;

    return ToolchainGroup(
      title: l10n.rpmBuildGroupTitle,
      subtitle: unsupportedRpm
          ? l10n.rpmBuildUnsupportedSubtitle(distribution.name)
          : isNativeRpm
          ? l10n.rpmBuildNativeSubtitle(distribution.name)
          : l10n.rpmBuildDockerSubtitle(distribution.name),
      status: unsupportedRpm
          ? ToolAvailability.missing
          : isNativeRpm
          ? _nativeRpmBuildStatus
          : _dockerRpmBuildStatus,
      installTarget: ToolchainInstallTarget.rpm,
      canRemove:
          !isNativeRpm &&
          !unsupportedRpm &&
          _rpmBuilderStatus == ToolAvailability.installed,
      installProgress: _installProgressFor(ToolchainInstallTarget.rpm),
      dependencyNote: isNativeRpm ? _commonToolsDependencyNote(l10n) : null,
      installSizeLabel:
          !isNativeRpm &&
              !unsupportedRpm &&
              _rpmBuilderStatus != ToolAvailability.installed
          ? '~5 GB'
          : null,
      tools: [
        if (isNativeRpm) ...[
          _hostSystemTool(l10n, distribution),
          _linuxToolchainTool(l10n),
          ToolStatus(
            name: 'rpmbuild',
            command: 'rpmbuild',
            status: _rpmToolStatus,
            note: l10n.rpmBuildToolNote,
          ),
        ] else if (unsupportedRpm) ...[
          _hostSystemTool(l10n, distribution),
          ToolStatus(
            name: l10n.hostRpmCompatibilityToolName,
            command: distribution.id,
            status: ToolAvailability.missing,
            note: l10n.hostRpmCompatibilityToolNote,
          ),
        ] else ...[
          ToolStatus(
            name: _containerRuntimeName ?? 'Container runtime',
            command: _containerRuntimeName?.toLowerCase() ?? 'docker or podman',
            status: _containerRuntimeStatus,
            note: l10n.dockerRpmNote,
            showCommand: false,
          ),
          ToolStatus(
            name: 'Fedora builder',
            command: BuilderEnvironment.rpmFedora.imageTag,
            status: _rpmBuilderStatus,
            note: l10n.rpmBuilderNote,
          ),
        ],
      ],
    );
  }

  ToolchainGroup _pacmanBuildGroup(
    AppLocalizations l10n,
    _HostDistribution distribution,
  ) {
    final isArch = distribution.family == _LinuxDistributionFamily.arch;
    return ToolchainGroup(
      title: l10n.pacmanBuildGroupTitle,
      subtitle: isArch
          ? l10n.pacmanBuildNativeSubtitle(distribution.name)
          : l10n.pacmanBuildUnsupportedSubtitle(distribution.name),
      status: isArch ? _pacmanBuildStatus : ToolAvailability.missing,
      installTarget: ToolchainInstallTarget.pacman,
      installProgress: _installProgressFor(ToolchainInstallTarget.pacman),
      dependencyNote: isArch ? _commonToolsDependencyNote(l10n) : null,
      tools: [
        _hostSystemTool(l10n, distribution),
        if (isArch) ...[
          _linuxToolchainTool(l10n),
          ToolStatus(
            name: 'makepkg',
            command: 'makepkg',
            status: _makepkgStatus,
            note: l10n.makepkgNote,
          ),
          ToolStatus(
            name: 'fakeroot',
            command: 'fakeroot',
            status: _fakerootStatus,
            note: l10n.fakerootNote,
          ),
        ] else
          ToolStatus(
            name: l10n.hostPacmanCompatibilityToolName,
            command: distribution.id,
            status: ToolAvailability.missing,
            note: l10n.hostPacmanCompatibilityToolNote,
          ),
      ],
    );
  }

  ToolchainGroup _appImageBuildGroup(AppLocalizations l10n) {
    return ToolchainGroup(
      title: l10n.appImageBuildGroupTitle,
      subtitle: l10n.appImageBuildGroupSubtitle,
      status: _appImageBuildStatus,
      installTarget: ToolchainInstallTarget.appImage,
      installProgress: _installProgressFor(ToolchainInstallTarget.appImage),
      dependencyNote: _commonToolsDependencyNote(l10n),
      tools: [
        _linuxToolchainTool(l10n),
        ToolStatus(
          name: 'AppImageTool',
          command: 'appimagetool',
          status: _appImageToolStatus,
          note: l10n.appImageToolNote,
        ),
      ],
    );
  }

  ToolchainGroup _tarGzBuildGroup(AppLocalizations l10n) {
    return ToolchainGroup(
      title: l10n.tarGzBuildGroupTitle,
      subtitle: l10n.tarGzBuildGroupSubtitle,
      status: _tarGzBuildStatus,
      installTarget: ToolchainInstallTarget.tarGz,
      installProgress: _installProgressFor(ToolchainInstallTarget.tarGz),
      dependencyNote: _commonToolsDependencyNote(l10n),
      tools: [
        _linuxToolchainTool(l10n),
        ToolStatus(
          name: 'tar',
          command: 'tar',
          status: _tarToolStatus,
          note: l10n.tarToolNote,
        ),
      ],
    );
  }

  ToolchainGroup _windowsBuildGroup(AppLocalizations l10n) {
    return ToolchainGroup(
      title: l10n.windowsBuildGroupTitle,
      subtitle: l10n.windowsBuildGroupSubtitle,
      status: _zipToolStatus == ToolAvailability.installed
          ? ToolAvailability.installed
          : ToolAvailability.available,
      installTarget: ToolchainInstallTarget.exe,
      installProgress: _installProgressFor(ToolchainInstallTarget.exe),
      guideSteps: l10n.windowsBuildKitGuideSteps,
      tools: [
        ToolStatus(
          name: 'zip',
          command: 'zip',
          status: _zipToolStatus,
          note: l10n.windowsZipNote,
        ),
        ToolStatus(
          name: 'Windows 10/11',
          command: 'real machine or VM',
          status: ToolAvailability.available,
          note: l10n.windowsMachineNote,
          showCommand: false,
        ),
        ToolStatus(
          name: 'Windows build script',
          command: 'build_windows.cmd',
          status: ToolAvailability.installed,
          note: l10n.windowsBuildScriptNote,
        ),
      ],
    );
  }

  ToolchainGroup _androidBuildGroup(AppLocalizations l10n) {
    return ToolchainGroup(
      title: l10n.androidBuildGroupTitle,
      subtitle: l10n.androidBuildGroupSubtitle,
      status: _androidToolsStatus,
      installTarget: ToolchainInstallTarget.android,
      installProgress: _installProgressFor(ToolchainInstallTarget.android),
      dependencyNote: _commonToolsDependencyNote(l10n),
      tools: [
        ToolStatus(
          name: 'Android SDK',
          command: r'ANDROID_HOME / sdkmanager',
          status: _androidSdkStatus,
          note: l10n.androidSdkNote,
        ),
        ToolStatus(
          name: 'Java',
          command: 'java',
          status: _javaStatus,
          note: l10n.javaNote,
        ),
      ],
    );
  }

  ToolStatus _hostSystemTool(
    AppLocalizations l10n,
    _HostDistribution distribution,
  ) {
    return ToolStatus(
      name: l10n.hostSystemToolName,
      command: distribution.id,
      status: distribution.family == _LinuxDistributionFamily.unknown
          ? ToolAvailability.missing
          : ToolAvailability.installed,
      note: l10n.hostSystemToolNote,
    );
  }

  ToolStatus _flutterTool(AppLocalizations l10n) {
    return ToolStatus(
      name: 'Flutter SDK',
      command: 'flutter',
      status: _flutterStatus,
      note: l10n.flutterSdkNote,
    );
  }

  ToolStatus _linuxToolchainTool(AppLocalizations l10n) {
    return ToolStatus(
      name: 'Linux toolchain',
      command: 'clang, cmake, ninja, GTK',
      status: _linuxToolchainStatus,
      note: l10n.hostLinuxToolchainNote,
    );
  }

  ToolAvailability get _nativeDebBuildStatus {
    if (_linuxToolchainStatus == ToolAvailability.installed &&
        _debToolStatus == ToolAvailability.installed) {
      return ToolAvailability.installed;
    }
    return ToolAvailability.available;
  }

  ToolAvailability get _dockerDebBuildStatus {
    if (_containerRuntimeStatus == ToolAvailability.installed &&
        _debBuilderStatus == ToolAvailability.installed) {
      return ToolAvailability.installed;
    }
    return ToolAvailability.available;
  }

  ToolAvailability get _nativeRpmBuildStatus {
    if (_linuxToolchainStatus == ToolAvailability.installed &&
        _rpmToolStatus == ToolAvailability.installed) {
      return ToolAvailability.installed;
    }
    return ToolAvailability.available;
  }

  ToolAvailability get _dockerRpmBuildStatus {
    // The Fedora builder can already be installed and managed, but RPM builds
    // are still wired through the host packager until container RPM export lands.
    return ToolAvailability.available;
  }

  ToolAvailability get _pacmanBuildStatus {
    if (_linuxToolchainStatus == ToolAvailability.installed &&
        _makepkgStatus == ToolAvailability.installed &&
        _fakerootStatus == ToolAvailability.installed) {
      return ToolAvailability.installed;
    }
    return ToolAvailability.available;
  }

  ToolAvailability get _appImageBuildStatus {
    if (_linuxToolchainStatus == ToolAvailability.installed &&
        _appImageToolStatus == ToolAvailability.installed) {
      return ToolAvailability.installed;
    }
    return ToolAvailability.available;
  }

  ToolAvailability get _tarGzBuildStatus {
    if (_linuxToolchainStatus == ToolAvailability.installed &&
        _tarToolStatus == ToolAvailability.installed) {
      return ToolAvailability.installed;
    }
    return ToolAvailability.available;
  }

  ToolAvailability get _commonToolsStatus {
    if (_flutterStatus == ToolAvailability.installed &&
        _gitStatus == ToolAvailability.installed &&
        _archiveToolsStatus == ToolAvailability.installed) {
      return ToolAvailability.installed;
    }
    return ToolAvailability.available;
  }

  ToolAvailability get _androidToolsStatus {
    if (_androidSdkStatus == ToolAvailability.installed &&
        _javaStatus == ToolAvailability.installed) {
      return ToolAvailability.installed;
    }
    return ToolAvailability.available;
  }

  /// Android targets are buildable only when the Flutter SDK is there too.
  ToolAvailability get _androidBuildStatus {
    if (_flutterStatus == ToolAvailability.installed &&
        _androidToolsStatus == ToolAvailability.installed) {
      return ToolAvailability.installed;
    }
    return ToolAvailability.available;
  }

  _HostDistribution get _hostDistribution {
    if (!Platform.isLinux) {
      return _HostDistribution(
        id: Platform.operatingSystem,
        name: _hostSystemLabel(),
        family: _LinuxDistributionFamily.unknown,
      );
    }

    final values = _readOsRelease();
    final id = values['ID']?.toLowerCase() ?? 'linux';
    final idLike = values['ID_LIKE']?.toLowerCase() ?? '';
    final name = values['NAME'] ?? _hostSystemLabel();
    final family = _detectDistributionFamily(id, idLike);
    return _HostDistribution(id: id, name: name, family: family);
  }

  _LinuxDistributionFamily _detectDistributionFamily(String id, String idLike) {
    final rpmIds = {'fedora', 'rhel', 'centos', 'rocky', 'almalinux'};
    final unsupportedRpmIds = {
      'opensuse',
      'opensuse-leap',
      'opensuse-tumbleweed',
      'sles',
      'alt',
      'altlinux',
    };
    final debIds = {
      'debian',
      'ubuntu',
      'linuxmint',
      'pop',
      'elementary',
      'zorin',
    };
    final archIds = {
      'arch',
      'archarm',
      'manjaro',
      'endeavouros',
      'garuda',
      'cachyos',
      'artix',
    };
    final tokens = {
      id,
      ...idLike.split(RegExp(r'\s+')).where((part) => part.isNotEmpty),
    };

    if (tokens.any(unsupportedRpmIds.contains)) {
      return _LinuxDistributionFamily.unsupportedRpm;
    }
    if (tokens.any(debIds.contains)) {
      return _LinuxDistributionFamily.deb;
    }
    if (tokens.any(rpmIds.contains)) {
      return _LinuxDistributionFamily.rpm;
    }
    if (tokens.any(archIds.contains)) {
      return _LinuxDistributionFamily.arch;
    }
    return _LinuxDistributionFamily.unknown;
  }

  Map<String, String> _readOsRelease() {
    final file = File('/etc/os-release');
    if (!file.existsSync()) {
      return const {};
    }

    final values = <String, String>{};
    for (final line in file.readAsLinesSync()) {
      final separator = line.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      final key = line.substring(0, separator);
      var value = line.substring(separator + 1).trim();
      if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      values[key] = value;
    }
    return values;
  }

  String _hostSystemLabel() {
    final system = switch (Platform.operatingSystem) {
      'linux' => 'Linux',
      'windows' => 'Windows',
      'macos' => 'macOS',
      'android' => 'Android',
      'ios' => 'iOS',
      final value => value,
    };
    final architecture = _hostArchitecture();
    return architecture.isEmpty ? system : '$system $architecture';
  }

  String _hostArchitecture() {
    if (!Platform.isLinux && !Platform.isMacOS) {
      return '';
    }

    try {
      final result = Process.runSync('uname', ['-m']);
      final architecture = result.stdout.toString().trim();
      if (architecture.isNotEmpty) {
        return architecture;
      }
    } on Object {
      // The UI can still show the OS if architecture probing is unavailable.
    }
    return '';
  }

  Future<void> _installTools(ToolchainInstallTarget target) async {
    if (_installingToolTarget != null) {
      return;
    }

    final l10n = context.l10n;
    _toolInstallCancelRequested = false;
    _toolchainService.beginInstall();
    setState(() {
      _installingToolTarget = target;
      _installProgress = ToolInstallProgress(
        target: target,
        progress: 0,
        remainingSeconds: null,
        detail: l10n.installPreparing,
      );
    });

    final result = await _runToolInstall(target);

    if (!mounted) {
      return;
    }

    setState(() {
      _installingToolTarget = null;
      _installProgress = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? l10n.toolInstallSuccess(result.message)
              : l10n.toolInstallFailed(result.message),
        ),
      ),
    );

    if (result.success && widget.enableToolchainDiagnostics) {
      await _refreshToolchainStatus();
    }
  }

  Future<void> _cancelToolInstall() async {
    _toolInstallCancelRequested = true;
    await Future.wait([
      _toolchainService.cancelActiveInstall(),
      _builderService.cancelActiveInstall(),
    ]);
  }

  Future<void> _removeTools(ToolchainInstallTarget target) async {
    if (_installingToolTarget != null) {
      return;
    }

    setState(() {
      _installingToolTarget = target;
      _installProgress = null;
    });

    final l10n = context.l10n;
    final result = await _runToolRemove(target);

    if (!mounted) {
      return;
    }

    setState(() {
      _installingToolTarget = null;
      _installProgress = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? l10n.toolRemoveSuccess(result.message)
              : l10n.toolRemoveFailed(result.message),
        ),
      ),
    );

    if (result.success && widget.enableToolchainDiagnostics) {
      await _refreshToolchainStatus();
    }
  }

  Future<ToolInstallResult> _runToolRemove(
    ToolchainInstallTarget target,
  ) async {
    return switch (target) {
      ToolchainInstallTarget.common => const ToolInstallResult.failure(
        'Common tools removal is not implemented yet.',
      ),
      ToolchainInstallTarget.rpm => _builderService.removeBuilder(
        BuilderEnvironment.rpmFedora,
      ),
      ToolchainInstallTarget.deb => _builderService.removeBuilder(
        BuilderEnvironment.debBookworm,
      ),
      ToolchainInstallTarget.pacman => const ToolInstallResult.failure(
        'pacman tool removal is not implemented yet.',
      ),
      ToolchainInstallTarget.appImage => const ToolInstallResult.failure(
        'AppImageTool removal is not implemented yet.',
      ),
      ToolchainInstallTarget.tarGz => const ToolInstallResult.failure(
        'tar.gz tool removal is not implemented yet.',
      ),
      ToolchainInstallTarget.exe => ToolInstallResult.failure(
        context.l10n.exeInstallUnsupported,
      ),
      ToolchainInstallTarget.android => const ToolInstallResult.failure(
        'Android SDK removal is not implemented yet.',
      ),
    };
  }

  Future<ToolInstallResult> _runToolInstall(
    ToolchainInstallTarget target,
  ) async {
    final l10n = context.l10n;
    final distribution = _hostDistribution;
    if (target == ToolchainInstallTarget.rpm &&
        distribution.family == _LinuxDistributionFamily.unsupportedRpm) {
      return ToolInstallResult.failure(l10n.rpmHostInstallUnsupported);
    }
    if (target == ToolchainInstallTarget.pacman &&
        distribution.family != _LinuxDistributionFamily.arch) {
      return ToolInstallResult.failure(l10n.pacmanHostInstallUnsupported);
    }

    final steps = switch (target) {
      ToolchainInstallTarget.common => [
        if (_gitStatus != ToolAvailability.installed ||
            _archiveToolsStatus != ToolAvailability.installed)
          _systemPackagesStep(l10n, _commonPackages),
        if (_flutterStatus != ToolAvailability.installed) _flutterStep(l10n),
      ],
      ToolchainInstallTarget.rpm =>
        distribution.family == _LinuxDistributionFamily.rpm
            ? _hostBuildSteps(
                l10n,
                systemToolsReady:
                    _linuxToolchainStatus == ToolAvailability.installed &&
                    _rpmToolStatus == ToolAvailability.installed,
                packagesByManager: _rpmHostPackages,
              )
            : _builderSteps(l10n, BuilderEnvironment.rpmFedora),
      ToolchainInstallTarget.deb =>
        distribution.family == _LinuxDistributionFamily.deb
            ? _hostBuildSteps(
                l10n,
                systemToolsReady:
                    _linuxToolchainStatus == ToolAvailability.installed &&
                    _debToolStatus == ToolAvailability.installed,
                packagesByManager: _debHostPackages,
              )
            : _builderSteps(l10n, BuilderEnvironment.debBookworm),
      ToolchainInstallTarget.pacman =>
        distribution.family == _LinuxDistributionFamily.arch
            ? _hostBuildSteps(
                l10n,
                systemToolsReady:
                    _linuxToolchainStatus == ToolAvailability.installed &&
                    _makepkgStatus == ToolAvailability.installed &&
                    _fakerootStatus == ToolAvailability.installed,
                packagesByManager: _pacmanHostPackages,
              )
            : const <_ToolInstallStep>[],
      ToolchainInstallTarget.appImage => [
        ..._hostBuildSteps(
          l10n,
          systemToolsReady: _linuxToolchainStatus == ToolAvailability.installed,
          packagesByManager: _appImageHostPackages,
        ),
        if (_appImageToolStatus != ToolAvailability.installed)
          _appImageToolStep(l10n),
      ],
      ToolchainInstallTarget.tarGz => _hostBuildSteps(
        l10n,
        systemToolsReady:
            _linuxToolchainStatus == ToolAvailability.installed &&
            _tarToolStatus == ToolAvailability.installed,
        packagesByManager: _tarGzHostPackages,
      ),
      ToolchainInstallTarget.exe => [
        if (_zipToolStatus != ToolAvailability.installed)
          _systemPackagesStep(l10n, _windowsKitPackages),
      ],
      ToolchainInstallTarget.android => [
        ..._hostBuildSteps(
          l10n,
          systemToolsReady: await _toolchainService.allCommandsAvailable([
            const CommandCheck('git', ['--version']),
            const CommandCheck('unzip', ['-v']),
            const CommandCheck('java', ['-version']),
          ]),
          packagesByManager: _androidHostPackages,
        ),
        if (_androidSdkStatus != ToolAvailability.installed)
          _androidSdkStep(l10n),
      ],
    };

    if (steps.isEmpty) {
      return const ToolInstallResult.success(
        'Required tools are already installed.',
      );
    }
    return _runInstallSteps(target, steps);
  }

  /// Runs install steps in order and turns their reports into one overall
  /// progress value for the toolchain card.
  Future<ToolInstallResult> _runInstallSteps(
    ToolchainInstallTarget target,
    List<_ToolInstallStep> steps,
  ) async {
    final session = _ToolInstallSession(target, steps);
    final messages = <String>[];
    var lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);

    for (var index = 0; index < steps.length; index++) {
      void report(double? fraction, String detail, {int? remainingSeconds}) {
        final progress = session.report(
          index,
          fraction,
          detail,
          remainingSeconds: remainingSeconds,
        );
        // git and sdkmanager can print hundreds of progress lines a second.
        final now = DateTime.now();
        final stepChanged = _installProgress?.currentStep != index;
        if (!mounted ||
            (!stepChanged &&
                now.difference(lastUpdate) <
                    const Duration(milliseconds: 100))) {
          return;
        }
        lastUpdate = now;
        setState(() => _installProgress = progress);
      }

      report(null, steps[index].title);
      final result = await steps[index].run(report);
      if (_toolInstallCancelRequested) {
        return const ToolInstallResult.failure('Installation was cancelled.');
      }
      if (!result.success) {
        return result;
      }
      messages.add(result.message);
    }
    return ToolInstallResult.success(messages.join('\n'));
  }

  /// Steps for targets built on the host: their system packages and the
  /// common Flutter SDK, so a single click is enough even on a clean machine.
  List<_ToolInstallStep> _hostBuildSteps(
    AppLocalizations l10n, {
    required bool systemToolsReady,
    required Map<String, List<String>> packagesByManager,
  }) {
    final needsFlutter = _flutterStatus != ToolAvailability.installed;
    final needsCommonPackages =
        needsFlutter &&
        (_gitStatus != ToolAvailability.installed ||
            _archiveToolsStatus != ToolAvailability.installed);
    return [
      if (!systemToolsReady || needsCommonPackages)
        _systemPackagesStep(
          l10n,
          needsCommonPackages
              ? _mergePackages(_commonPackages, packagesByManager)
              : packagesByManager,
        ),
      if (needsFlutter) _flutterStep(l10n),
    ];
  }

  List<_ToolInstallStep> _builderSteps(
    AppLocalizations l10n,
    BuilderEnvironment builder,
  ) {
    return [
      if (_containerRuntimeStatus != ToolAvailability.installed)
        _ToolInstallStep(
          title: l10n.installStepContainerRuntime,
          weight: 3,
          cancellable: false,
          run: _installDockerTools,
        ),
      _ToolInstallStep(
        title: l10n.installStepBuilderImage,
        weight: 8,
        run: (report) => _installBuilderImage(builder, report),
      ),
    ];
  }

  _ToolInstallStep _systemPackagesStep(
    AppLocalizations l10n,
    Map<String, List<String>> packagesByManager,
  ) {
    return _ToolInstallStep(
      title: l10n.installStepSystemPackages,
      weight: 3,
      cancellable: false,
      run: (report) => _toolchainService.installSystemPackages(
        packagesByManager: packagesByManager,
        onProgress: (fraction, detail) => report(fraction, detail),
      ),
    );
  }

  _ToolInstallStep _flutterStep(AppLocalizations l10n) {
    return _ToolInstallStep(
      title: l10n.installStepFlutterSdk,
      weight: 6,
      run: (report) => _toolchainService.installFlutterSdk(
        onProgress: (fraction, detail) => report(fraction, detail),
      ),
    );
  }

  _ToolInstallStep _androidSdkStep(AppLocalizations l10n) {
    return _ToolInstallStep(
      title: l10n.installStepAndroidSdk,
      weight: 6,
      run: (report) => _toolchainService.installAndroidSdk(
        onProgress: (fraction, detail) => report(fraction, detail),
      ),
    );
  }

  _ToolInstallStep _appImageToolStep(AppLocalizations l10n) {
    return _ToolInstallStep(
      title: l10n.installStepAppImageTool,
      weight: 1,
      run: (report) => _toolchainService.installAppImageTool(
        onProgress: (fraction, detail) => report(fraction, detail),
      ),
    );
  }

  Future<ToolInstallResult> _installBuilderImage(
    BuilderEnvironment builder,
    _InstallStepReport report,
  ) async {
    ToolInstallResult? result;
    await for (final event in _builderService.installBuilder(builder)) {
      final eventResult = event.result;
      if (eventResult != null) {
        result = eventResult;
        continue;
      }
      final progress = event.progress;
      report(
        progress == null ? null : progress / 100,
        event.detail ?? '',
        remainingSeconds: event.remainingSeconds,
      );
    }

    return result ??
        const ToolInstallResult.failure('Builder installation did not finish.');
  }

  Future<ToolInstallResult> _installDockerTools(
    _InstallStepReport report,
  ) async {
    final installResult = await _toolchainService.installSystemPackages(
      packagesByManager: const {
        'dnf': ['moby-engine', 'docker-cli', 'containerd'],
        'apt-get': ['docker.io'],
        'zypper': ['docker'],
        'pacman': ['docker'],
      },
      onProgress: (fraction, detail) => report(fraction, detail),
    );
    if (!installResult.success) {
      return installResult;
    }

    report(null, 'Enabling Docker service.');
    final serviceResult = await _toolchainService.enableDockerService();
    if (!serviceResult.success) {
      return serviceResult;
    }

    report(null, 'Adding current user to docker group.');
    final groupResult = await _toolchainService.addCurrentUserToDockerGroup();
    if (!groupResult.success) {
      return groupResult;
    }

    return ToolInstallResult.success(
      [
        installResult.message,
        serviceResult.message,
        groupResult.message,
      ].join('\n'),
    );
  }

  @override
  void dispose() {
    _workspaceTabController.removeListener(_handleWorkspaceTabChanged);
    _workspaceTabController.dispose();
    _runningProjectProcess?.kill(ProcessSignal.sigterm);
    _sendToDeviceProcess?.kill(ProcessSignal.sigterm);
    if (_metadataListenersAttached) {
      for (final controller in _metadataControllers) {
        controller.removeListener(_scheduleReleaseMetadataSave);
      }
    }
    if (_metadataSaveTimer?.isActive ?? false) {
      unawaited(_saveReleaseMetadata());
    }
    _metadataSaveTimer?.cancel();
    _appNameController.dispose();
    _projectPathController.dispose();
    _releaseTagController.dispose();
    _developerEmailController.dispose();
    _publisherNameController.dispose();
    _homepageUrlController.dispose();
    _licenseController.dispose();
    _descriptionController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _debAdditionalDependenciesController.dispose();
    _rpmAdditionalDependenciesController.dispose();
    _pacmanAdditionalDependenciesController.dispose();
    _packageMetadataController.dispose();
    _packageDependenciesController.dispose();
    super.dispose();
  }

  Future<void> _runBuild() async {
    if (_isBuilding || _isSendingToDevice) {
      return;
    }

    final projectPath = _projectPath;
    if (projectPath == null) {
      _replaceLog(
        BuildLogEntry(
          title: context.l10n.projectNotSelectedTitle,
          detail: context.l10n.projectNotSelectedDetail,
          state: BuildLogState.warning,
        ),
      );
      return;
    }

    setState(() {
      _isBuilding = true;
      _buildProgress = 0;
      _buildLog.clear();
      _replaceRoadmapWithPreview();
    });

    final configuration = BuildConfiguration(
      appName: _appNameController.text,
      releaseTag: _releaseTagController.text,
      developerEmail: _developerEmailController.text,
      publisherName: _publisherNameController.text,
      homepageUrl: _homepageUrlController.text,
      license: _licenseController.text,
      description: _descriptionController.text,
      projectPath: projectPath,
      outputPath: _outputPath,
      iconPath: _iconPath,
      windowWidth: int.tryParse(_widthController.text),
      windowHeight: int.tryParse(_heightController.text),
      targets: _targets,
      additionalDependencies: _additionalPackageDependencies(),
    );

    var hadWarning = false;
    var sawSuccess = false;
    var shouldShowSuccess = false;
    String? firstWarningDetail;
    try {
      await for (final event in _buildService.build(configuration)) {
        if (!mounted) {
          return;
        }

        setState(() {
          final logEntry = event.logEntry;
          final progress = event.progress;
          final roadmapPlan = event.roadmapPlan;
          final roadmapUpdate = event.roadmapUpdate;
          if (logEntry != null) {
            _buildLog.add(logEntry);
            if (logEntry.state == BuildLogState.warning) {
              hadWarning = true;
              firstWarningDetail ??= logEntry.detail.trim().isEmpty
                  ? logEntry.title
                  : logEntry.detail;
            }
            sawSuccess = sawSuccess || logEntry.state == BuildLogState.success;
          }
          if (progress != null) {
            _buildProgress = progress.clamp(0, 100);
          }
          if (roadmapPlan != null) {
            _roadmapSteps
              ..clear()
              ..addAll(roadmapPlan);
          }
          if (roadmapUpdate != null) {
            _applyRoadmapUpdate(roadmapUpdate);
          }
        });
      }
      shouldShowSuccess = sawSuccess && !hadWarning;
    } on Object catch (error) {
      // Without this the stream error stayed invisible: the roadmap was reset
      // and the build simply ended without saying anything.
      hadWarning = true;
      firstWarningDetail ??= error.toString();
      if (mounted) {
        setState(() {
          _buildLog.add(
            BuildLogEntry(
              title: context.l10n.buildWarningsTitle,
              detail: error.toString(),
              state: BuildLogState.warning,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBuilding = false;
          _buildProgress = 0;
          if (!hadWarning) {
            // On failure the roadmap stays as it is, so the step that broke
            // remains on screen instead of being replaced by a clean preview.
            _replaceRoadmapWithPreview();
          }
        });
        if (shouldShowSuccess) {
          await _showBuildSuccessDialog();
        } else if (hadWarning) {
          await _showBuildWarningsDialog(firstWarningDetail);
        }
      }
    }
  }

  Future<void> _runProjectWithoutBuild() async {
    if (_isBuilding || _isRunningProject || _isSendingToDevice) {
      return;
    }

    final projectPath = _projectPath;
    if (projectPath == null) {
      _replaceLog(
        BuildLogEntry(
          title: context.l10n.projectNotSelectedTitle,
          detail: context.l10n.projectNotSelectedDetail,
          state: BuildLogState.warning,
        ),
      );
      return;
    }

    setState(() {
      _isRunningProject = true;
      _buildLog
        ..clear()
        ..add(
          const BuildLogEntry(
            title: 'Running Flutter app',
            detail: 'flutter run -d linux',
            state: BuildLogState.running,
          ),
        );
    });

    try {
      final process = await _startFlutterRun(projectPath);
      _runningProjectProcess = process;
      _listenToRunOutput(process.stdout, BuildLogState.running);
      _listenToRunOutput(process.stderr, BuildLogState.warning);
      unawaited(_waitForRunProcess(process));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRunningProject = false;
        _runningProjectProcess = null;
        _buildLog.add(
          BuildLogEntry(
            title: 'Could not run Flutter app',
            detail: error.toString(),
            state: BuildLogState.warning,
          ),
        );
      });
    }
  }

  Future<Process> _startFlutterRun(String projectPath) {
    return _startFlutter(projectPath, const ['run', '-d', 'linux']);
  }

  /// Starts the resolved flutter executable without a shell, so a missing
  /// SDK is reported instead of ending as "flutter: command not found".
  Future<Process> _startFlutter(String projectPath, List<String> arguments) {
    final locator = FlutterLocator();
    final flutter = locator.find();
    if (flutter == null) {
      throw ProcessException(
        'flutter',
        arguments,
        context.l10n.flutterSdkNotFound,
      );
    }
    return Process.start(
      flutter.path,
      arguments,
      workingDirectory: projectPath,
      environment: {...?_runEnvironment(), ...locator.environmentFor(flutter)},
    );
  }

  void _listenToRunOutput(Stream<List<int>> stream, BuildLogState state) {
    stream.transform(utf8.decoder).transform(const LineSplitter()).listen((
      line,
    ) {
      final trimmed = line.trim();
      if (!mounted || trimmed.isEmpty) {
        return;
      }
      setState(() {
        _buildLog.add(
          BuildLogEntry(
            title: state == BuildLogState.warning
                ? 'Flutter stderr'
                : 'Flutter output',
            detail: trimmed,
            state: state,
          ),
        );
      });
    });
  }

  Future<void> _waitForRunProcess(Process process) async {
    final exitCode = await process.exitCode;
    if (!mounted || _runningProjectProcess != process) {
      return;
    }
    setState(() {
      _isRunningProject = false;
      _runningProjectProcess = null;
      _buildLog.add(
        BuildLogEntry(
          title: 'Flutter app stopped',
          detail: 'Process exited with code $exitCode.',
          state: exitCode == 0 ? BuildLogState.success : BuildLogState.warning,
        ),
      );
    });
  }

  void _stopRunningProject() {
    final process = _runningProjectProcess;
    if (process == null) {
      return;
    }
    process.kill(ProcessSignal.sigterm);
    setState(() {
      _isRunningProject = false;
      _runningProjectProcess = null;
      _buildLog.add(
        const BuildLogEntry(
          title: 'Stopping Flutter app',
          detail: 'Sent SIGTERM to the running flutter process.',
          state: BuildLogState.running,
        ),
      );
    });
  }

  /// Builds a release APK straight from the project folder and installs it on
  /// an attached device. The packaging pipeline is deliberately not reused: it
  /// copies the project into a throwaway workspace, which would force a cold
  /// Gradle build on every send.
  Future<void> _sendApkToDevice() async {
    if (_isBuilding || _isRunningProject || _isSendingToDevice) {
      return;
    }

    final projectPath = _projectPath;
    if (projectPath == null) {
      _replaceLog(
        BuildLogEntry(
          title: context.l10n.projectNotSelectedTitle,
          detail: context.l10n.projectNotSelectedDetail,
          state: BuildLogState.warning,
        ),
      );
      return;
    }

    if (await _androidDeviceService.resolveExecutable() == null) {
      if (mounted) {
        _showSnackBar(context.l10n.adbMissing);
      }
      return;
    }

    final device = await _resolveTargetDevice();
    if (device == null || !mounted) {
      return;
    }

    setState(() {
      _isSendingToDevice = true;
      _sendToDeviceCancelled = false;
      _sendToDeviceStatus = context.l10n.androidBuildingApk;
      _buildLog
        ..clear()
        ..add(
          BuildLogEntry(
            title: 'Building release APK',
            detail: 'flutter build apk --release (${device.label})',
            state: BuildLogState.running,
          ),
        );
    });

    try {
      final buildExitCode = await _runSendStep(
        await _startFlutterApkBuild(projectPath),
      );
      if (!mounted || _sendToDeviceCancelled) {
        return;
      }
      if (buildExitCode != 0) {
        _finishSendToDevice(context.l10n.androidBuildFailed, failed: true);
        return;
      }

      final apk = _findReleaseApk(projectPath);
      if (apk == null) {
        _finishSendToDevice(context.l10n.androidApkMissing, failed: true);
        return;
      }

      setState(() {
        _sendToDeviceStatus = context.l10n.androidInstallingApk(device.label);
        _buildLog.add(
          BuildLogEntry(
            title: 'Installing APK',
            detail: 'adb -s ${device.serial} install -r ${apk.path}',
            state: BuildLogState.running,
          ),
        );
      });

      final installed = await _installApkOnDevice(
        device: device,
        apkPath: apk.path,
        projectPath: projectPath,
      );
      if (!mounted || _sendToDeviceCancelled) {
        return;
      }
      if (!installed) {
        _finishSendToDevice(context.l10n.androidInstallFailed, failed: true);
        return;
      }

      await _launchInstalledApp(device: device, projectPath: projectPath);
      if (!mounted || _sendToDeviceCancelled) {
        return;
      }
      _finishSendToDevice(context.l10n.androidInstallSucceeded(device.label));
    } on Object catch (error) {
      if (!mounted || _sendToDeviceCancelled) {
        return;
      }
      setState(() {
        _buildLog.add(
          BuildLogEntry(
            title: 'Could not send the app to the device',
            detail: error.toString(),
            state: BuildLogState.warning,
          ),
        );
      });
      _finishSendToDevice(context.l10n.androidInstallFailed, failed: true);
    }
  }

  /// Picks the device to install on, walking the user through the states adb
  /// reports: nothing attached, attached but waiting for the USB debugging
  /// confirmation, or several devices to choose from.
  Future<AndroidDevice?> _resolveTargetDevice() async {
    while (mounted) {
      final devices = await _androidDeviceService.listDevices();
      if (!mounted) {
        return null;
      }

      final authorized = devices
          .where((device) => device.isAuthorized)
          .toList();
      if (authorized.length == 1) {
        return authorized.first;
      }
      if (authorized.length > 1) {
        return _chooseAndroidDevice(authorized);
      }

      AndroidDevice? unauthorized;
      for (final device in devices) {
        if (device.isUnauthorized) {
          unauthorized = device;
          break;
        }
      }

      final retry = unauthorized == null
          ? await _showDeviceProblemDialog(
              title: context.l10n.androidDeviceSearchTitle,
              message: context.l10n.androidDeviceMissingMessage,
              icon: Icons.usb_outlined,
            )
          : await _showDeviceProblemDialog(
              title: context.l10n.androidDeviceUnauthorizedTitle,
              message: context.l10n.androidDeviceUnauthorizedMessage(
                unauthorized.label,
              ),
              icon: Icons.phonelink_lock_outlined,
            );
      if (!retry) {
        return null;
      }
    }
    return null;
  }

  Future<bool> _showDeviceProblemDialog({
    required String title,
    required String message,
    required IconData icon,
  }) async {
    final l10n = context.l10n;
    final retry = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.retryDeviceCheck),
          ),
        ],
      ),
    );
    return retry ?? false;
  }

  Future<AndroidDevice?> _chooseAndroidDevice(
    List<AndroidDevice> devices,
  ) async {
    final l10n = context.l10n;
    return showDialog<AndroidDevice>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.smartphone_outlined),
        title: Text(l10n.chooseAndroidDeviceTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final device in devices)
              ListTile(
                leading: const Icon(Icons.smartphone_outlined),
                title: Text(device.label),
                onTap: () => Navigator.of(context).pop(device),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  /// Installs the APK, recovering from the two failures that a device with an
  /// older build of the same app reliably produces.
  Future<bool> _installApkOnDevice({
    required AndroidDevice device,
    required String apkPath,
    required String projectPath,
  }) async {
    var result = await _runAdbInstall(device.serial, apkPath);
    if (result.isSuccess) {
      return true;
    }

    // A lower versionCode than the installed build: the APK is still the newer
    // source, so retrying with an explicit downgrade is what the user wants.
    if (result.contains('INSTALL_FAILED_VERSION_DOWNGRADE')) {
      _logAdbResult('Retrying install with downgrade allowed', result);
      result = await _runAdbInstall(
        device.serial,
        apkPath,
        allowDowngrade: true,
      );
      if (result.isSuccess) {
        return true;
      }
    }

    // A build signed with another key cannot replace the installed one, and
    // removing it destroys the app data, so this needs an explicit decision.
    final signatureConflict =
        result.contains('INSTALL_FAILED_UPDATE_INCOMPATIBLE') ||
        result.contains('signatures do not match');
    if (signatureConflict) {
      _logAdbResult('Install rejected: signature mismatch', result);
      final applicationId = _readAndroidApplicationId(projectPath);
      if (applicationId != null && await _confirmReinstall()) {
        final uninstall = await _androidDeviceService.run([
          '-s',
          device.serial,
          'uninstall',
          applicationId,
        ]);
        _logAdbResult('Uninstalling the previous build', uninstall);
        result = await _runAdbInstall(device.serial, apkPath);
        if (result.isSuccess) {
          return true;
        }
      }
    }

    _logAdbResult('Install failed', result);
    return false;
  }

  Future<AdbResult> _runAdbInstall(
    String serial,
    String apkPath, {
    bool allowDowngrade = false,
  }) {
    return _androidDeviceService.run([
      '-s',
      serial,
      'install',
      '-r',
      if (allowDowngrade) '-d',
      apkPath,
    ], timeout: const Duration(minutes: 10));
  }

  Future<bool> _confirmReinstall() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_outlined),
        title: Text(l10n.androidSignatureConflictTitle),
        content: Text(l10n.androidSignatureConflictMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.removeAndInstall),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Opens the freshly installed app. A device that refuses to launch it is not
  /// an install failure, so this only ever adds a log entry.
  Future<void> _launchInstalledApp({
    required AndroidDevice device,
    required String projectPath,
  }) async {
    final applicationId = _readAndroidApplicationId(projectPath);
    if (applicationId == null) {
      return;
    }
    final result = await _androidDeviceService.run([
      '-s',
      device.serial,
      'shell',
      'monkey',
      '-p',
      applicationId,
      '-c',
      'android.intent.category.LAUNCHER',
      '1',
    ], timeout: const Duration(seconds: 30));
    _logAdbResult('Launching $applicationId', result);
  }

  /// Reads `applicationId` from the Gradle config of the Android project. Only
  /// a literal value is accepted, so a computed id is skipped instead of being
  /// guessed wrong.
  String? _readAndroidApplicationId(String projectPath) {
    for (final relativePath in const [
      'android/app/build.gradle.kts',
      'android/app/build.gradle',
    ]) {
      final file = File(_joinPath(projectPath, relativePath));
      if (!file.existsSync()) {
        continue;
      }
      final match = RegExp(
        '''applicationId\\s*=?\\s*["']([^"']+)["']''',
      ).firstMatch(file.readAsStringSync());
      final applicationId = match?.group(1);
      if (applicationId != null && applicationId.isNotEmpty) {
        return applicationId;
      }
    }
    return null;
  }

  Future<Process> _startFlutterApkBuild(String projectPath) {
    return _startFlutter(projectPath, const ['build', 'apk', '--release']);
  }

  Future<int> _runSendStep(Process process) async {
    _sendToDeviceProcess = process;
    _listenToRunOutput(process.stdout, BuildLogState.running);
    _listenToRunOutput(process.stderr, BuildLogState.warning);
    return process.exitCode;
  }

  File? _findReleaseApk(String projectPath) {
    final standardApk = File(
      _joinPath(projectPath, 'build/app/outputs/flutter-apk/app-release.apk'),
    );
    if (standardApk.existsSync()) {
      return standardApk;
    }

    final outputDirectory = Directory(
      _joinPath(projectPath, 'build/app/outputs'),
    );
    if (!outputDirectory.existsSync()) {
      return null;
    }
    for (final entity in outputDirectory.listSync(recursive: true)) {
      if (entity is File &&
          entity.path.endsWith('.apk') &&
          entity.path.contains('release')) {
        return entity;
      }
    }
    return null;
  }

  void _logAdbResult(String title, AdbResult result) {
    if (!mounted) {
      return;
    }
    setState(() {
      _buildLog.add(
        BuildLogEntry(
          title: title,
          detail: result.output.isEmpty
              ? 'adb exited with code ${result.exitCode}.'
              : result.output,
          state: result.isSuccess
              ? BuildLogState.success
              : BuildLogState.warning,
        ),
      );
    });
  }

  void _finishSendToDevice(String message, {bool failed = false}) {
    setState(() {
      _isSendingToDevice = false;
      _sendToDeviceProcess = null;
      _sendToDeviceStatus = null;
      _buildLog.add(
        BuildLogEntry(
          title: failed ? 'Send to device failed' : 'Send to device finished',
          detail: message,
          state: failed ? BuildLogState.warning : BuildLogState.success,
        ),
      );
    });
    _showSnackBar(message);
  }

  void _cancelSendToDevice() {
    if (!_isSendingToDevice) {
      return;
    }
    // An adb step cannot be interrupted mid-flight, so the flag is what stops
    // the flow: its result is dropped instead of being reported as a failure.
    _sendToDeviceCancelled = true;
    _sendToDeviceProcess?.kill(ProcessSignal.sigterm);
    _sendToDeviceProcess = null;
    setState(() {
      _isSendingToDevice = false;
      _sendToDeviceStatus = null;
      _buildLog.add(
        BuildLogEntry(
          title: 'Send to device cancelled',
          detail: context.l10n.androidSendCancelled,
          state: BuildLogState.warning,
        ),
      );
    });
  }

  Map<String, String>? _runEnvironment() {
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

  void _replaceRoadmapWithPreview() {
    _roadmapSteps
      ..clear()
      ..addAll(_buildService.createRoadmapPlan(_targets));
  }

  void _applyRoadmapUpdate(BuildRoadmapUpdate update) {
    final index = _roadmapSteps.indexWhere((step) => step.id == update.id);
    if (index == -1) {
      return;
    }
    _roadmapSteps[index] = _roadmapSteps[index].copyWith(
      state: update.state,
      progress: update.progress,
      detail: update.detail,
    );
  }

  Future<void> _chooseProjectFolder() async {
    final path = await getDirectoryPath(
      confirmButtonText: context.l10n.chooseProject,
    );
    if (path == null || !mounted) {
      return;
    }

    _setProjectPath(path);
  }

  /// Applies the path typed into the project field. An unknown folder is
  /// reported instead of being applied, so the checks never describe a folder
  /// that is not there.
  void _applyTypedProjectPath() {
    final path = _expandHomeDirectory(_projectPathController.text.trim());
    if (path == _projectPath) {
      if (_projectPathController.text != path) {
        _projectPathController.text = path ?? '';
      }
      return;
    }

    if (path == null) {
      setState(() {
        _projectPath = null;
        _hasDesktopRunner = false;
        _projectChecks.clear();
        _projectPathController.clear();
        _updateTargetStatuses();
        if (!_isBuilding) {
          _replaceRoadmapWithPreview();
        }
      });
      return;
    }

    if (!Directory(path).existsSync()) {
      _showSnackBar(context.l10n.projectFolderNotFound(path));
      return;
    }

    _setProjectPath(path);
  }

  String? _expandHomeDirectory(String path) {
    if (path.isEmpty) {
      return null;
    }
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty || !path.startsWith('~')) {
      return path;
    }
    if (path == '~') {
      return home;
    }
    return path.startsWith('~/') ? _joinPath(home, path.substring(2)) : path;
  }

  void _setProjectPath(String path) {
    final windowSize = _readFlutterWindowSize(path);
    final projectMetadata = _readProjectMetadata(path);
    final projectAppName = projectMetadata.name;
    final detectedIcon = const ProjectIconFinder().find(path);
    final previousProject = _projectPath;
    final currentIcon = _iconPath;
    // Never override an icon the user picked from outside the old project.
    final canReplaceIcon =
        currentIcon == null ||
        _iconAutoDetected ||
        (previousProject != null &&
            currentIcon.startsWith(
              '$previousProject${Platform.pathSeparator}',
            ));

    setState(() {
      if (canReplaceIcon) {
        _iconPath = detectedIcon;
        _iconAutoDetected = detectedIcon != null;
      }
      _projectPath = path;
      _updateTargetStatuses();
      if (!_isBuilding) {
        _replaceRoadmapWithPreview();
      }
      _hasDesktopRunner = _hasLinuxRunner(path);
      if (_projectPathController.text != path) {
        _projectPathController.text = path;
      }
      _projectChecks
        ..clear()
        ..addAll(_buildProjectChecks(path, projectMetadata, detectedIcon));
      if (windowSize != null) {
        _widthController.text = windowSize.width.toString();
        _heightController.text = windowSize.height.toString();
      }
      if (projectAppName != null && _shouldAutofillAppName) {
        _appNameController.text = projectAppName;
      }
      if (projectMetadata.version != null &&
          _releaseTagController.text.trim().isEmpty) {
        _releaseTagController.text = 'v${projectMetadata.version}';
      }
      if (projectMetadata.description != null &&
          _descriptionController.text.trim().isEmpty) {
        _descriptionController.text = projectMetadata.description!;
      }
      if (projectMetadata.homepage != null &&
          _homepageUrlController.text.trim().isEmpty) {
        _homepageUrlController.text = projectMetadata.homepage!;
      }
    });
  }

  Future<void> _loadConfigPresets() async {
    await _refreshConfigPresets(await _appPreferences.loadConfigPresetPaths());
  }

  /// Rereads every pinned config. Entries whose file no longer exists are
  /// dropped: a preset lives exactly as long as its file on disk.
  Future<void> _refreshConfigPresets(List<String> paths) async {
    final presets = <ConfigPreset>[];
    final keptPaths = <String>[];
    for (final path in paths) {
      if (!await File(path).exists()) {
        continue;
      }
      keptPaths.add(path);
      presets.add(await _readConfigPreset(path));
    }

    if (keptPaths.length != paths.length) {
      await _appPreferences.saveConfigPresetPaths(keptPaths);
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _configPresets
        ..clear()
        ..addAll(presets);
      if (!keptPaths.contains(_activeConfigPath)) {
        _activeConfigPath = null;
      }
    });
  }

  Future<ConfigPreset> _readConfigPreset(String path) async {
    try {
      return ConfigPreset.fromConfig(
        path,
        await _projectConfigService.load(path),
      );
    } on Object {
      return ConfigPreset.broken(path);
    }
  }

  Future<void> _addConfigPreset() async {
    if (_isBuilding) {
      return;
    }

    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(label: context.l10n.configFileType, extensions: ['json']),
      ],
      confirmButtonText: context.l10n.addConfig,
    );
    if (file == null || !mounted) {
      return;
    }

    final alreadyPinned = _configPresets.any(
      (preset) => preset.path == file.path,
    );
    await _pinConfigPath(file.path);
    if (!mounted) {
      return;
    }
    if (alreadyPinned) {
      _showSnackBar(context.l10n.configPresetAlreadyPinned);
    }
    await _applyConfigPreset(file.path);
  }

  Future<void> _pinConfigPath(String path) async {
    final paths = List<String>.from(
      await _appPreferences.loadConfigPresetPaths(),
    );
    if (!paths.contains(path)) {
      paths.add(path);
      await _appPreferences.saveConfigPresetPaths(paths);
    }
    await _refreshConfigPresets(paths);
  }

  Future<void> _applyConfigPreset(String path) async {
    if (_isBuilding) {
      return;
    }

    try {
      final config = await _projectConfigService.load(path);
      if (!mounted) {
        return;
      }
      _applyProjectConfig(config);
      setState(() {
        _activeConfigPath = path;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.configImportFailed(error.toString()));
      await _loadConfigPresets();
    }
  }

  Future<void> _removeConfigPreset(ConfigPreset preset) async {
    final paths = List<String>.from(
      await _appPreferences.loadConfigPresetPaths(),
    )..remove(preset.path);
    await _appPreferences.saveConfigPresetPaths(paths);
    await _refreshConfigPresets(paths);
    if (!mounted) {
      return;
    }
    _showSnackBar(context.l10n.configPresetRemoved);
  }

  Future<void> _exportProjectConfig() async {
    if (_isBuilding) {
      return;
    }

    final location = await getSaveLocation(
      acceptedTypeGroups: [
        XTypeGroup(label: context.l10n.configFileType, extensions: ['json']),
      ],
      initialDirectory: _projectPath,
      suggestedName: 'packfoundry.json',
      confirmButtonText: context.l10n.exportConfig,
      canCreateDirectories: true,
    );
    if (location == null || !mounted) {
      return;
    }

    try {
      await _projectConfigService.save(location.path, _currentProjectConfig());
      await _pinConfigPath(location.path);
      if (!mounted) {
        return;
      }
      setState(() {
        _activeConfigPath = location.path;
      });
      _showSnackBar(context.l10n.configExported);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.configExportFailed(error.toString()));
    }
  }

  ProjectConfig _currentProjectConfig() {
    return ProjectConfig(
      projectPath: _projectPath ?? ProjectConfig.chooseInPackFoundry,
      outputPath: _outputPath ?? ProjectConfig.chooseInPackFoundry,
      iconPath: _iconPath ?? ProjectConfig.chooseInPackFoundry,
      appName: _appNameController.text,
      releaseTag: _releaseTagController.text,
      developerEmail: _developerEmailController.text,
      publisherName: _publisherNameController.text,
      homepageUrl: _homepageUrlController.text,
      license: _licenseController.text,
      description: _descriptionController.text,
      windowWidth: int.tryParse(_widthController.text),
      windowHeight: int.tryParse(_heightController.text),
      packageTypes: [
        for (final target in _targets)
          if (target.selected)
            ProjectConfig.packageTypeForTarget(
              target.platform,
              target.artifact,
            ),
      ],
      additionalDependencies: _additionalPackageDependencies(),
    );
  }

  Map<String, String> _additionalPackageDependencies() {
    return {
      'deb': _debAdditionalDependenciesController.text,
      'rpm': _rpmAdditionalDependenciesController.text,
      'pacman': _pacmanAdditionalDependenciesController.text,
    }..removeWhere((key, value) => value.trim().isEmpty);
  }

  void _applyProjectConfig(ProjectConfig config) {
    final projectPath = config.projectPath;
    if (!config.choosesProject && projectPath != null) {
      _setProjectPath(projectPath);
    }

    setState(() {
      _restoreConfigText(_appNameController, config.appName);
      _restoreConfigText(_releaseTagController, config.releaseTag);
      _restoreConfigText(_developerEmailController, config.developerEmail);
      _restoreConfigText(_publisherNameController, config.publisherName);
      _restoreConfigText(_homepageUrlController, config.homepageUrl);
      _restoreConfigText(_licenseController, config.license);
      _restoreConfigText(_descriptionController, config.description);
      _restoreConfigText(
        _debAdditionalDependenciesController,
        config.additionalDependencies['deb'],
      );
      _restoreConfigText(
        _rpmAdditionalDependenciesController,
        config.additionalDependencies['rpm'],
      );
      _restoreConfigText(
        _pacmanAdditionalDependenciesController,
        config.additionalDependencies['pacman'],
      );
      if (config.windowWidth != null) {
        _widthController.text = config.windowWidth.toString();
      }
      if (config.windowHeight != null) {
        _heightController.text = config.windowHeight.toString();
      }
      if (!config.choosesOutput) {
        _outputPath = config.outputPath;
      }
      if (!config.choosesIcon) {
        _iconPath = config.iconPath;
        _iconAutoDetected = false;
      }
      if (config.packageTypes.isNotEmpty) {
        for (final target in _targets) {
          target.selected =
              target.canSelect &&
              config.packageTypes.any(
                (type) => ProjectConfig.targetMatchesPackageType(
                  type,
                  target.platform,
                  target.artifact,
                ),
              );
        }
      }
      _replaceRoadmapWithPreview();
    });
  }

  void _restoreConfigText(TextEditingController controller, String? value) {
    if (value != null) {
      controller.text = value;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showBuildSuccessDialog() async {
    await SystemSound.play(SystemSoundType.alert);
    if (!mounted) {
      return;
    }

    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.task_alt_outlined),
        title: Text(l10n.buildSuccessTitle),
        content: Text(l10n.buildSuccessMessage),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _showBuildWarningsDialog(String? detail) async {
    await SystemSound.play(SystemSoundType.alert);
    if (!mounted) {
      return;
    }

    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline),
        title: Text(l10n.buildWarningsTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.buildWarningsMessage),
              if (detail != null && detail.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                SelectableText(
                  detail.trim(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  bool get _shouldAutofillAppName {
    final currentName = _appNameController.text.trim();
    return currentName.isEmpty || currentName == _defaultAppName;
  }

  _ProjectMetadata _readProjectMetadata(String projectPath) {
    final file = File(_joinPath(projectPath, 'pubspec.yaml'));
    if (!file.existsSync()) {
      return const _ProjectMetadata();
    }

    final content = file.readAsStringSync();
    final rawName = _readPubspecScalar(content, 'name');
    final name = rawName == null || rawName.isEmpty
        ? null
        : rawName
              .split(RegExp(r'[-_\s]+'))
              .where((part) => part.isNotEmpty)
              .map((part) => part[0].toUpperCase() + part.substring(1))
              .join();

    return _ProjectMetadata(
      name: name,
      version: _readPubspecScalar(content, 'version'),
      description: _readPubspecScalar(content, 'description'),
      homepage: _readPubspecScalar(content, 'homepage'),
    );
  }

  String? _readPubspecScalar(String content, String key) {
    final match = RegExp(
      r'^' + key + r':\s*([^#\n]+)',
      multiLine: true,
    ).firstMatch(content);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  /// The run action launches `flutter run -d linux`, so only the Linux runner
  /// makes a project runnable from this host.
  bool _hasLinuxRunner(String projectPath) {
    return File(
      _joinPath(projectPath, 'linux/runner/my_application.cc'),
    ).existsSync();
  }

  List<ProjectCheck> _buildProjectChecks(
    String projectPath,
    _ProjectMetadata metadata,
    String? detectedIcon,
  ) {
    final l10n = context.l10n;
    final hasPubspec = File(
      _joinPath(projectPath, 'pubspec.yaml'),
    ).existsSync();
    final hasLinuxRunner = _hasLinuxRunner(projectPath);
    final hasWindowsRunner = File(
      _joinPath(projectPath, 'windows/runner/main.cpp'),
    ).existsSync();
    final hasVersion = metadata.version != null && metadata.version!.isNotEmpty;
    final hasDescription =
        metadata.description != null && metadata.description!.isNotEmpty;

    return [
      ProjectCheck(
        label: hasPubspec ? l10n.pubspecFound : l10n.pubspecMissing,
        tone: hasPubspec ? ChipTone.good : ChipTone.warning,
      ),
      if (hasLinuxRunner)
        ProjectCheck(label: l10n.linuxRunnerFound, tone: ChipTone.good),
      if (hasWindowsRunner)
        ProjectCheck(label: l10n.windowsRunnerFound, tone: ChipTone.good),
      ProjectCheck(
        label: hasVersion
            ? l10n.projectVersionFound
            : l10n.projectVersionMissing,
        tone: hasVersion ? ChipTone.good : ChipTone.neutral,
      ),
      ProjectCheck(
        label: hasDescription
            ? l10n.projectDescriptionFound
            : l10n.projectDescriptionMissing,
        tone: hasDescription ? ChipTone.good : ChipTone.neutral,
      ),
      ProjectCheck(
        label: detectedIcon != null
            ? l10n.projectIconFound(
                detectedIcon.substring(projectPath.length + 1),
              )
            : l10n.projectIconMissing,
        tone: detectedIcon != null ? ChipTone.good : ChipTone.neutral,
      ),
    ];
  }

  _WindowSize? _readFlutterWindowSize(String projectPath) {
    return _readLinuxWindowSize(projectPath) ??
        _readWindowsWindowSize(projectPath);
  }

  _WindowSize? _readLinuxWindowSize(String projectPath) {
    final file = File(_joinPath(projectPath, 'linux/runner/my_application.cc'));
    if (!file.existsSync()) {
      return null;
    }

    final match = RegExp(
      r'gtk_window_set_default_size\s*\([^,]+,\s*(\d+)\s*,\s*(\d+)\s*\)',
    ).firstMatch(file.readAsStringSync());
    return _windowSizeFromMatch(match);
  }

  _WindowSize? _readWindowsWindowSize(String projectPath) {
    final file = File(_joinPath(projectPath, 'windows/runner/main.cpp'));
    if (!file.existsSync()) {
      return null;
    }

    final match = RegExp(
      r'Win32Window::Size\s+size\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)',
    ).firstMatch(file.readAsStringSync());
    return _windowSizeFromMatch(match);
  }

  _WindowSize? _windowSizeFromMatch(RegExpMatch? match) {
    if (match == null) {
      return null;
    }

    final width = int.tryParse(match.group(1) ?? '');
    final height = int.tryParse(match.group(2) ?? '');
    if (width == null || height == null) {
      return null;
    }
    return _WindowSize(width: width, height: height);
  }

  String _joinPath(String first, String second) {
    final normalizedSecond = second.replaceAll('/', Platform.pathSeparator);
    if (first.endsWith(Platform.pathSeparator)) {
      return '$first$normalizedSecond';
    }
    return '$first${Platform.pathSeparator}$normalizedSecond';
  }

  Future<void> _chooseOutputFolder() async {
    final path = await getDirectoryPath(
      confirmButtonText: context.l10n.chooseOutput,
    );
    if (path == null || !mounted) {
      return;
    }

    setState(() {
      _outputPath = path;
    });
  }

  Future<void> _chooseIconFile() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: context.l10n.iconTypeGroup,
          extensions: ['png', 'svg'],
        ),
      ],
      confirmButtonText: context.l10n.chooseIcon,
    );
    if (file == null || !mounted) {
      return;
    }

    setState(() {
      _iconPath = file.path;
      _iconAutoDetected = false;
    });
  }

  Future<void> _choosePackageFile() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: context.l10n.packageTypeGroup,
          extensions: [
            'deb',
            'rpm',
            'AppImage',
            'appimage',
            'tar.gz',
            'tgz',
            'gz',
            'apk',
            'exe',
            'zip',
          ],
        ),
      ],
      confirmButtonText: context.l10n.choosePackage,
    );
    if (file == null || !mounted) {
      return;
    }

    setState(() {
      _isInspectingPackage = true;
    });

    try {
      final inspection = await _packageInspectorService.inspect(file.path);
      if (!mounted) {
        return;
      }
      setState(() {
        _packageInspection = inspection;
        _packageMetadataController.text = _formatPackageFields(
          inspection.fields,
        );
        _packageDependenciesController.text = inspection.dependencyText;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.packageInspectFailed(error.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isInspectingPackage = false;
        });
      }
    }
  }

  Future<void> _saveEditedPackage() async {
    final inspection = _packageInspection;
    if (inspection == null || !inspection.saveSupported) {
      return;
    }

    setState(() {
      _isInspectingPackage = true;
    });

    try {
      final outputPath = await _packageInspectorService.saveDebMetadata(
        packagePath: inspection.path,
        metadata: _packageMetadataController.text,
        dependencies: _packageDependenciesController.text,
      );
      final refreshed = await _packageInspectorService.inspect(outputPath);
      if (!mounted) {
        return;
      }
      setState(() {
        _packageInspection = refreshed;
        _packageMetadataController.text = _formatPackageFields(
          refreshed.fields,
        );
        _packageDependenciesController.text = refreshed.dependencyText;
      });
      _showSnackBar(context.l10n.packageSaved(outputPath));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.packageSaveFailed(error.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isInspectingPackage = false;
        });
      }
    }
  }

  String _formatPackageFields(Map<String, String> fields) {
    if (fields.isEmpty) {
      return '';
    }
    return [
      for (final entry in fields.entries) '${entry.key}: ${entry.value}',
    ].join('\n');
  }

  void _replaceLog(BuildLogEntry entry) {
    setState(() {
      _buildLog
        ..clear()
        ..add(entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final toolGroups = _toolGroups(l10n);
    final selectedTargets = _targets.where((target) => target.selected).length;
    final workspaces = [
      _Workspace(
        label: l10n.settings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
      _Workspace(
        label: l10n.project,
        icon: Icons.folder_open_outlined,
        selectedIcon: Icons.folder,
      ),
      _Workspace(
        label: l10n.build,
        icon: Icons.rocket_launch_outlined,
        selectedIcon: Icons.rocket_launch,
      ),
      _Workspace(
        label: l10n.packageInspectorShort,
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
      ),
    ];

    final content = _WorkspaceContent(
      index: _workspaceIndex,
      themeMode: widget.themeMode,
      localeMode: widget.localeMode,
      toolGroups: toolGroups,
      installingToolTarget: _installingToolTarget,
      projectPath: _projectPath,
      projectPathController: _projectPathController,
      projectChecks: _projectChecks,
      configPresets: _configPresets,
      activeConfigPath: _activeConfigPath,
      iconPath: _iconPath,
      outputPath: _outputPath,
      appNameController: _appNameController,
      releaseTagController: _releaseTagController,
      developerEmailController: _developerEmailController,
      publisherNameController: _publisherNameController,
      homepageUrlController: _homepageUrlController,
      licenseController: _licenseController,
      descriptionController: _descriptionController,
      widthController: _widthController,
      heightController: _heightController,
      debAdditionalDependenciesController: _debAdditionalDependenciesController,
      rpmAdditionalDependenciesController: _rpmAdditionalDependenciesController,
      pacmanAdditionalDependenciesController:
          _pacmanAdditionalDependenciesController,
      packageInspection: _packageInspection,
      packageMetadataController: _packageMetadataController,
      packageDependenciesController: _packageDependenciesController,
      isInspectingPackage: _isInspectingPackage,
      targets: _targets,
      selectedTargets: selectedTargets,
      isBuilding: _isBuilding,
      isRunningProject: _isRunningProject,
      canRunProject: _projectPath != null && _hasDesktopRunner,
      canSendToDevice:
          _projectPath != null &&
          _targets.any((target) => target.artifact == 'APK' && target.selected),
      isSendingToDevice: _isSendingToDevice,
      sendToDeviceStatus: _sendToDeviceStatus,
      progress: _buildProgress,
      roadmapSteps: _roadmapSteps,
      log: _buildLog,
      onThemeModeChanged: widget.onThemeModeChanged,
      onLocaleModeChanged: widget.onLocaleModeChanged,
      onInstallTools: _installTools,
      onRemoveTools: _removeTools,
      onCancelInstall: _cancelToolInstall,
      onChooseProject: _chooseProjectFolder,
      onProjectPathSubmitted: _applyTypedProjectPath,
      onAddConfigPreset: _addConfigPreset,
      onSaveCurrentConfig: _exportProjectConfig,
      onApplyConfigPreset: (preset) => _applyConfigPreset(preset.path),
      onRemoveConfigPreset: _removeConfigPreset,
      onChooseIcon: _chooseIconFile,
      onChooseOutput: _chooseOutputFolder,
      onChoosePackage: _choosePackageFile,
      onTargetChanged: _setTargetSelection,
      onSaveEditedPackage: _saveEditedPackage,
      onBuild: _runBuild,
      onRunProject: _runProjectWithoutBuild,
      onStopProject: _stopRunningProject,
      onSendToDevice: _sendApkToDevice,
      onCancelSendToDevice: _cancelSendToDevice,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Image.asset('assets/icon.png', height: 26),
            ),
            Expanded(
              child: TabBar(
                controller: _workspaceTabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (var index = 0; index < workspaces.length; index++)
                    Tab(
                      height: 48,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            index == _workspaceIndex
                                ? workspaces[index].selectedIcon
                                : workspaces[index].icon,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(workspaces[index].label),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(child: content),
    );
  }

  void _setTargetSelection(BuildTarget target, bool selected) {
    if (_isBuilding) {
      return;
    }
    setState(() {
      target.selected = selected;
      _buildProgress = 0;
      _replaceRoadmapWithPreview();
    });
  }
}

class _HostDistribution {
  const _HostDistribution({
    required this.id,
    required this.name,
    required this.family,
  });

  final String id;
  final String name;
  final _LinuxDistributionFamily family;
}

enum _LinuxDistributionFamily { deb, rpm, arch, unsupportedRpm, unknown }

class _ProjectMetadata {
  const _ProjectMetadata({
    this.name,
    this.version,
    this.description,
    this.homepage,
  });

  final String? name;
  final String? version;
  final String? description;
  final String? homepage;
}

class _WindowSize {
  const _WindowSize({required this.width, required this.height});

  final int width;
  final int height;
}

class _WorkspaceContent extends StatelessWidget {
  const _WorkspaceContent({
    required this.index,
    required this.themeMode,
    required this.localeMode,
    required this.toolGroups,
    required this.installingToolTarget,
    required this.projectPath,
    required this.projectPathController,
    required this.projectChecks,
    required this.configPresets,
    required this.activeConfigPath,
    required this.iconPath,
    required this.outputPath,
    required this.appNameController,
    required this.releaseTagController,
    required this.developerEmailController,
    required this.publisherNameController,
    required this.homepageUrlController,
    required this.licenseController,
    required this.descriptionController,
    required this.widthController,
    required this.heightController,
    required this.debAdditionalDependenciesController,
    required this.rpmAdditionalDependenciesController,
    required this.pacmanAdditionalDependenciesController,
    required this.packageInspection,
    required this.packageMetadataController,
    required this.packageDependenciesController,
    required this.isInspectingPackage,
    required this.targets,
    required this.selectedTargets,
    required this.isBuilding,
    required this.isRunningProject,
    required this.canRunProject,
    required this.canSendToDevice,
    required this.isSendingToDevice,
    required this.sendToDeviceStatus,
    required this.progress,
    required this.roadmapSteps,
    required this.log,
    required this.onThemeModeChanged,
    required this.onLocaleModeChanged,
    required this.onInstallTools,
    required this.onRemoveTools,
    required this.onCancelInstall,
    required this.onChooseProject,
    required this.onProjectPathSubmitted,
    required this.onAddConfigPreset,
    required this.onSaveCurrentConfig,
    required this.onApplyConfigPreset,
    required this.onRemoveConfigPreset,
    required this.onChooseIcon,
    required this.onChooseOutput,
    required this.onChoosePackage,
    required this.onTargetChanged,
    required this.onSaveEditedPackage,
    required this.onBuild,
    required this.onRunProject,
    required this.onStopProject,
    required this.onSendToDevice,
    required this.onCancelSendToDevice,
  });

  final int index;
  final ThemeMode themeMode;
  final AppLocaleMode localeMode;
  final List<ToolchainGroup> toolGroups;
  final ToolchainInstallTarget? installingToolTarget;
  final String? projectPath;
  final TextEditingController projectPathController;
  final List<ProjectCheck> projectChecks;
  final List<ConfigPreset> configPresets;
  final String? activeConfigPath;
  final String? iconPath;
  final String? outputPath;
  final TextEditingController appNameController;
  final TextEditingController releaseTagController;
  final TextEditingController developerEmailController;
  final TextEditingController publisherNameController;
  final TextEditingController homepageUrlController;
  final TextEditingController licenseController;
  final TextEditingController descriptionController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final TextEditingController debAdditionalDependenciesController;
  final TextEditingController rpmAdditionalDependenciesController;
  final TextEditingController pacmanAdditionalDependenciesController;
  final PackageInspection? packageInspection;
  final TextEditingController packageMetadataController;
  final TextEditingController packageDependenciesController;
  final bool isInspectingPackage;
  final List<BuildTarget> targets;
  final int selectedTargets;
  final bool isBuilding;
  final bool isRunningProject;
  final bool canRunProject;
  final bool canSendToDevice;
  final bool isSendingToDevice;
  final String? sendToDeviceStatus;
  final int progress;
  final List<BuildRoadmapStep> roadmapSteps;
  final List<BuildLogEntry> log;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<AppLocaleMode> onLocaleModeChanged;
  final ValueChanged<ToolchainInstallTarget> onInstallTools;
  final ValueChanged<ToolchainInstallTarget> onRemoveTools;
  final VoidCallback onCancelInstall;
  final VoidCallback onChooseProject;
  final VoidCallback onProjectPathSubmitted;
  final VoidCallback onAddConfigPreset;
  final VoidCallback onSaveCurrentConfig;
  final ValueChanged<ConfigPreset> onApplyConfigPreset;
  final ValueChanged<ConfigPreset> onRemoveConfigPreset;
  final VoidCallback onChooseIcon;
  final VoidCallback onChooseOutput;
  final VoidCallback onChoosePackage;
  final void Function(BuildTarget target, bool selected) onTargetChanged;
  final VoidCallback onSaveEditedPackage;
  final VoidCallback onBuild;
  final VoidCallback onRunProject;
  final VoidCallback onStopProject;
  final VoidCallback onSendToDevice;
  final VoidCallback onCancelSendToDevice;

  @override
  Widget build(BuildContext context) {
    final children = switch (index) {
      0 => [
        ToolchainPanel(
          groups: toolGroups,
          installingTarget: installingToolTarget,
          onInstallTools: onInstallTools,
          onRemoveTools: onRemoveTools,
          onCancelInstall: onCancelInstall,
        ),
        const SizedBox(height: 16),
        PreferencesPanel(
          themeMode: themeMode,
          localeMode: localeMode,
          onThemeModeChanged: onThemeModeChanged,
          onLocaleModeChanged: onLocaleModeChanged,
        ),
      ],
      1 => [
        ProjectPanel(
          pathController: projectPathController,
          checks: projectChecks,
          onChooseProject: onChooseProject,
          onPathSubmitted: onProjectPathSubmitted,
        ),
        const SizedBox(height: 16),
        ConfigPresetsPanel(
          presets: configPresets,
          activePath: activeConfigPath,
          isBusy: isBuilding,
          isRunning: isRunningProject,
          canRun: canRunProject,
          canSendToDevice: canSendToDevice,
          isSendingToDevice: isSendingToDevice,
          sendToDeviceStatus: sendToDeviceStatus,
          onAddConfig: onAddConfigPreset,
          onSaveCurrentConfig: onSaveCurrentConfig,
          onApplyPreset: onApplyConfigPreset,
          onRemovePreset: onRemoveConfigPreset,
          onRun: onRunProject,
          onStop: onStopProject,
          onSendToDevice: onSendToDevice,
          onCancelSendToDevice: onCancelSendToDevice,
        ),
        const SizedBox(height: 16),
        AppSettingsPanel(
          widthController: widthController,
          heightController: heightController,
          releaseTagController: releaseTagController,
          developerEmailController: developerEmailController,
          publisherNameController: publisherNameController,
          homepageUrlController: homepageUrlController,
          licenseController: licenseController,
          descriptionController: descriptionController,
          iconPath: iconPath,
          onChooseIcon: onChooseIcon,
        ),
        const SizedBox(height: 16),
        InstallerSettingsPanel(
          appNameController: appNameController,
          outputPath: outputPath,
          targets: targets,
          onChooseOutput: onChooseOutput,
          onChanged: onTargetChanged,
        ),
        const SizedBox(height: 16),
        PackageDependenciesPanel(
          debController: debAdditionalDependenciesController,
          rpmController: rpmAdditionalDependenciesController,
          pacmanController: pacmanAdditionalDependenciesController,
        ),
      ],
      2 => [
        BuildPanel(
          selectedTargets: selectedTargets,
          isBuilding: isBuilding,
          isRunning: isRunningProject,
          canRun: canRunProject,
          progress: progress,
          roadmapSteps: roadmapSteps,
          log: log,
          configuration: projectPath == null
              ? null
              : BuildConfiguration(
                  appName: appNameController.text,
                  releaseTag: releaseTagController.text,
                  developerEmail: developerEmailController.text,
                  publisherName: publisherNameController.text,
                  homepageUrl: homepageUrlController.text,
                  license: licenseController.text,
                  description: descriptionController.text,
                  projectPath: projectPath!,
                  outputPath: outputPath,
                  iconPath: iconPath,
                  windowWidth: int.tryParse(widthController.text),
                  windowHeight: int.tryParse(heightController.text),
                  targets: targets,
                  additionalDependencies: {
                    'deb': debAdditionalDependenciesController.text,
                    'rpm': rpmAdditionalDependenciesController.text,
                    'pacman': pacmanAdditionalDependenciesController.text,
                  }..removeWhere((key, value) => value.trim().isEmpty),
                ),
          onBuild: onBuild,
          onRun: onRunProject,
          onStop: onStopProject,
        ),
      ],
      _ => [
        PackageInspectorPanel(
          inspection: packageInspection,
          metadataController: packageMetadataController,
          dependenciesController: packageDependenciesController,
          isBusy: isInspectingPackage,
          onChoosePackage: onChoosePackage,
          onSaveEditedPackage: onSaveEditedPackage,
        ),
      ],
    };

    if (index == 2) {
      // The build workspace fills the window so the plan, commands and log
      // are visible together; it only scrolls when the window is very short.
      return LayoutBuilder(
        builder: (context, constraints) {
          const minHeight = 560.0;
          final panel = Padding(
            padding: const EdgeInsets.all(24),
            child: children.single,
          );
          if (constraints.maxHeight >= minHeight) {
            return panel;
          }
          return SingleChildScrollView(
            child: SizedBox(height: minHeight, child: panel),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Workspace {
  const _Workspace({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

typedef _InstallStepReport =
    void Function(double? fraction, String detail, {int? remainingSeconds});

class _ToolInstallStep {
  const _ToolInstallStep({
    required this.title,
    required this.weight,
    required this.run,
    this.cancellable = true,
  });

  final String title;

  /// Relative share of the overall progress bar, roughly the step duration.
  final int weight;
  final bool cancellable;
  final Future<ToolInstallResult> Function(_InstallStepReport report) run;
}

class _ToolInstallSession {
  _ToolInstallSession(this.target, this.steps)
    : _totalWeight = steps.fold(0, (sum, step) => sum + step.weight);

  final ToolchainInstallTarget target;
  final List<_ToolInstallStep> steps;
  final int _totalWeight;
  final _stopwatch = Stopwatch()..start();
  var _stepIndex = -1;
  double? _stepFraction;
  var _overall = 0.0;

  ToolInstallProgress report(
    int stepIndex,
    double? fraction,
    String detail, {
    int? remainingSeconds,
  }) {
    if (stepIndex != _stepIndex) {
      _stepIndex = stepIndex;
      _stepFraction = null;
    }
    // A null fraction means "no new measurement", so the last one is kept and
    // the bar never jumps backwards.
    if (fraction != null) {
      final clamped = fraction.clamp(0.0, 1.0);
      if (_stepFraction == null || clamped > _stepFraction!) {
        _stepFraction = clamped;
      }
    }

    var doneWeight = 0;
    for (var index = 0; index < stepIndex; index++) {
      doneWeight += steps[index].weight;
    }
    final overall =
        (doneWeight + steps[stepIndex].weight * (_stepFraction ?? 0)) /
        _totalWeight;
    if (overall > _overall) {
      _overall = overall;
    }

    return ToolInstallProgress(
      target: target,
      progress: (_overall * 100).floor(),
      remainingSeconds: remainingSeconds ?? _estimateRemainingSeconds(),
      detail: detail,
      steps: [for (final step in steps) step.title],
      currentStep: stepIndex,
      stepProgress: _stepFraction == null
          ? null
          : (_stepFraction! * 100).floor(),
      cancellable: steps[stepIndex].cancellable,
    );
  }

  int? _estimateRemainingSeconds() {
    final elapsed = _stopwatch.elapsed.inSeconds;
    if (_overall < 0.03 || elapsed < 5) {
      return null;
    }
    return (elapsed * (1 - _overall) / _overall).round();
  }
}

Map<String, List<String>> _mergePackages(
  Map<String, List<String>> first,
  Map<String, List<String>> second,
) {
  return {
    for (final manager in {...first.keys, ...second.keys})
      manager: {...?first[manager], ...?second[manager]}.toList(),
  };
}

/// Everything the flutter tool needs on Linux besides the SDK checkout.
const _commonPackages = {
  'dnf': ['git', 'curl', 'unzip', 'xz', 'which', 'zip'],
  'apt-get': ['git', 'curl', 'unzip', 'xz-utils', 'zip'],
  'zypper': ['git', 'curl', 'unzip', 'xz', 'which', 'zip'],
  'pacman': ['git', 'curl', 'unzip', 'xz', 'which', 'zip'],
};

const _rpmHostPackages = {
  'dnf': ['git', 'clang', 'cmake', 'ninja-build', 'gtk3-devel', 'rpm-build'],
  'apt-get': ['git', 'clang', 'cmake', 'ninja-build', 'libgtk-3-dev', 'rpm'],
  'zypper': ['git', 'clang', 'cmake', 'ninja', 'gtk3-devel', 'rpm-build'],
  'pacman': ['git', 'clang', 'cmake', 'ninja', 'gtk3', 'rpm-tools'],
};

const _debHostPackages = {
  'dnf': ['clang', 'cmake', 'ninja-build', 'gtk3-devel', 'dpkg-dev'],
  'apt-get': [
    'git',
    'clang',
    'cmake',
    'ninja-build',
    'libgtk-3-dev',
    'dpkg-dev',
  ],
  'zypper': ['git', 'clang', 'cmake', 'ninja', 'gtk3-devel', 'dpkg'],
  'pacman': ['git', 'clang', 'cmake', 'ninja', 'gtk3', 'dpkg'],
};

const _tarGzHostPackages = {
  'dnf': ['git', 'clang', 'cmake', 'ninja-build', 'gtk3-devel', 'tar'],
  'apt-get': ['git', 'clang', 'cmake', 'ninja-build', 'libgtk-3-dev', 'tar'],
  'zypper': ['git', 'clang', 'cmake', 'ninja', 'gtk3-devel', 'tar'],
  'pacman': ['git', 'clang', 'cmake', 'ninja', 'gtk3', 'tar'],
};

/// makepkg ships with pacman itself; base-devel adds fakeroot and friends.
const _pacmanHostPackages = {
  'pacman': ['git', 'clang', 'cmake', 'ninja', 'gtk3', 'base-devel'],
};

const _appImageHostPackages = {
  'dnf': ['git', 'clang', 'cmake', 'ninja-build', 'gtk3-devel'],
  'apt-get': ['git', 'clang', 'cmake', 'ninja-build', 'libgtk-3-dev'],
  'zypper': ['git', 'clang', 'cmake', 'ninja', 'gtk3-devel'],
  'pacman': ['git', 'clang', 'cmake', 'ninja', 'gtk3'],
};

const _windowsKitPackages = {
  'dnf': ['zip'],
  'apt-get': ['zip'],
  'zypper': ['zip'],
  'pacman': ['zip'],
};

const _androidHostPackages = {
  'dnf': ['git', 'unzip', 'java-latest-openjdk-devel'],
  'apt-get': ['git', 'unzip', 'openjdk-17-jdk'],
  'zypper': ['git', 'unzip', 'java-17-openjdk-devel'],
  'pacman': ['git', 'unzip', 'jdk17-openjdk'],
};
