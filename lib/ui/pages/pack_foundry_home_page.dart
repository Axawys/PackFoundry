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
import '../../core/models/package_inspection.dart';
import '../../core/models/project_config.dart';
import '../../core/models/tool_status.dart';
import '../../core/services/app_preferences.dart';
import '../../core/services/build_service.dart';
import '../../core/services/builder_environment_service.dart';
import '../../core/services/package_inspector_service.dart';
import '../../core/services/project_config_service.dart';
import '../../core/services/toolchain_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_settings_panel.dart';
import '../widgets/build_panel.dart';
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

class _PackFoundryHomePageState extends State<PackFoundryHomePage> {
  static const _defaultAppName = 'My Flutter App';

  final _buildService = BuildService();
  final _toolchainService = ToolchainService();
  final _builderService = BuilderEnvironmentService();
  final _packageInspectorService = const PackageInspectorService();
  final _projectConfigService = const ProjectConfigService();
  final _appPreferences = AppPreferences();
  final _appNameController = TextEditingController(text: _defaultAppName);
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
  final _packageMetadataController = TextEditingController();
  final _packageDependenciesController = TextEditingController();
  final _buildLog = <BuildLogEntry>[];
  final _roadmapSteps = <BuildRoadmapStep>[];
  final _projectChecks = <ProjectCheck>[];
  Timer? _metadataSaveTimer;
  bool _metadataListenersAttached = false;

  String? _projectPath;
  String? _iconPath;
  String? _outputPath;
  PackageInspection? _packageInspection;
  bool _isBuilding = false;
  bool _isRunningProject = false;
  bool _isInspectingPackage = false;
  ToolchainInstallTarget? _installingToolTarget;
  int _buildProgress = 0;
  bool _welcomeDialogShown = false;
  int _workspaceIndex = 1;
  ToolAvailability _flutterStatus = ToolAvailability.available;
  ToolAvailability _linuxToolchainStatus = ToolAvailability.available;
  ToolAvailability _containerRuntimeStatus = ToolAvailability.available;
  String? _containerRuntimeName;
  ToolInstallProgress? _installProgress;
  ToolAvailability _debBuilderStatus = ToolAvailability.available;
  ToolAvailability _rpmBuilderStatus = ToolAvailability.available;
  ToolAvailability _appImageToolStatus = ToolAvailability.available;
  ToolAvailability _debToolStatus = ToolAvailability.available;
  ToolAvailability _rpmToolStatus = ToolAvailability.available;
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
    BuildTarget(
      platform: 'macOS',
      artifact: 'dmg',
      status: TargetStatus.hostLimited,
    ),
    BuildTarget(
      platform: 'iOS',
      artifact: 'ipa',
      status: TargetStatus.hostLimited,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadReleaseMetadata();
    if (widget.enableToolchainDiagnostics) {
      _refreshToolchainStatus();
    }
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
      _updateAndroidTargetStatus();
    });
  }

  void _updateAndroidTargetStatus() {
    final androidReady = _androidBuildStatus == ToolAvailability.installed;
    for (final target in _targets.where(
      (target) => target.platform == 'Android',
    )) {
      target.status = androidReady
          ? TargetStatus.ready
          : TargetStatus.installable;
    }
  }

  Future<ToolAvailability> _linuxToolchainAvailable() async {
    final available = await _toolchainService.allCommandsAvailable([
      const CommandCheck('clang', ['--version']),
      const CommandCheck('cmake', ['--version']),
      const CommandCheck('ninja', ['--version']),
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
    final nativePackageGroups =
        distribution.family == _LinuxDistributionFamily.deb
        ? [debGroup, rpmGroup]
        : [rpmGroup, debGroup];

    return [
      ...nativePackageGroups,
      _appImageBuildGroup(l10n),
      _tarGzBuildGroup(l10n),
      _windowsBuildGroup(l10n),
      _androidBuildGroup(l10n),
    ];
  }

  ToolchainGroup _debBuildGroup(
    AppLocalizations l10n,
    _HostDistribution distribution,
  ) {
    final isNativeDeb = distribution.family == _LinuxDistributionFamily.deb;
    final tools = isNativeDeb
        ? [
            _hostSystemTool(l10n, distribution),
            _flutterTool(l10n),
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
      installProgress: _installProgress?.target == ToolchainInstallTarget.deb
          ? _installProgress
          : null,
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
      installProgress: _installProgress?.target == ToolchainInstallTarget.rpm
          ? _installProgress
          : null,
      installSizeLabel:
          !isNativeRpm &&
              !unsupportedRpm &&
              _rpmBuilderStatus != ToolAvailability.installed
          ? '~5 GB'
          : null,
      tools: [
        if (isNativeRpm) ...[
          _hostSystemTool(l10n, distribution),
          _flutterTool(l10n),
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

  ToolchainGroup _appImageBuildGroup(AppLocalizations l10n) {
    return ToolchainGroup(
      title: l10n.appImageBuildGroupTitle,
      subtitle: l10n.appImageBuildGroupSubtitle,
      status: _appImageBuildStatus,
      installTarget: ToolchainInstallTarget.appImage,
      tools: [
        _flutterTool(l10n),
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
      tools: [
        _flutterTool(l10n),
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
          name: 'PowerShell build script',
          command: 'scripts/build_windows.ps1',
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
      status: _androidBuildStatus,
      installTarget: ToolchainInstallTarget.android,
      tools: [
        _flutterTool(l10n),
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
    if (_flutterStatus == ToolAvailability.installed &&
        _linuxToolchainStatus == ToolAvailability.installed &&
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
    if (_flutterStatus == ToolAvailability.installed &&
        _linuxToolchainStatus == ToolAvailability.installed &&
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

  ToolAvailability get _appImageBuildStatus {
    if (_flutterStatus == ToolAvailability.installed &&
        _linuxToolchainStatus == ToolAvailability.installed &&
        _appImageToolStatus == ToolAvailability.installed) {
      return ToolAvailability.installed;
    }
    return ToolAvailability.available;
  }

  ToolAvailability get _tarGzBuildStatus {
    if (_flutterStatus == ToolAvailability.installed &&
        _linuxToolchainStatus == ToolAvailability.installed &&
        _tarToolStatus == ToolAvailability.installed) {
      return ToolAvailability.installed;
    }
    return ToolAvailability.available;
  }

  ToolAvailability get _androidBuildStatus {
    if (_flutterStatus == ToolAvailability.installed &&
        _androidSdkStatus == ToolAvailability.installed &&
        _javaStatus == ToolAvailability.installed) {
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

    setState(() {
      _installingToolTarget = target;
      _installProgress = ToolInstallProgress(
        target: target,
        progress: 5,
        remainingSeconds: 60,
        detail: 'Starting tool installation.',
      );
    });

    final l10n = context.l10n;
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
    await _builderService.cancelActiveInstall();
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
      ToolchainInstallTarget.rpm => _builderService.removeBuilder(
        BuilderEnvironment.rpmFedora,
      ),
      ToolchainInstallTarget.deb => _builderService.removeBuilder(
        BuilderEnvironment.debBookworm,
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
    final distribution = _hostDistribution;
    _setToolInstallProgress(
      target,
      15,
      'Checking required tools and package recipes.',
    );
    return switch (target) {
      ToolchainInstallTarget.rpm => _installRpmTools(distribution),
      ToolchainInstallTarget.deb => _installDebTools(distribution),
      ToolchainInstallTarget.appImage => _installAppImageTools(distribution),
      ToolchainInstallTarget.tarGz => _installTarGzTools(distribution),
      ToolchainInstallTarget.exe => _installWindowsTools(distribution),
      ToolchainInstallTarget.android => _installAndroidTools(distribution),
    };
  }

  void _setToolInstallProgress(
    ToolchainInstallTarget target,
    int progress,
    String detail, {
    int remainingSeconds = 60,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      _installProgress = ToolInstallProgress(
        target: target,
        progress: progress.clamp(0, 100),
        remainingSeconds: remainingSeconds,
        detail: detail,
      );
    });
  }

  Future<ToolInstallResult> _installRpmTools(_HostDistribution distribution) {
    if (distribution.family == _LinuxDistributionFamily.rpm) {
      return _installFlutterAndSystemPackages(
        packagesByManager: const {
          'dnf': [
            'git',
            'clang',
            'cmake',
            'ninja-build',
            'gtk3-devel',
            'rpm-build',
          ],
          'apt-get': [
            'git',
            'clang',
            'cmake',
            'ninja-build',
            'libgtk-3-dev',
            'rpm',
          ],
          'zypper': [
            'git',
            'clang',
            'cmake',
            'ninja',
            'gtk3-devel',
            'rpm-build',
          ],
          'pacman': ['git', 'clang', 'cmake', 'ninja', 'gtk3', 'rpm-tools'],
        },
      );
    }

    if (distribution.family == _LinuxDistributionFamily.unsupportedRpm) {
      return Future.value(
        ToolInstallResult.failure(context.l10n.rpmHostInstallUnsupported),
      );
    }

    return _installBuilderEnvironment(BuilderEnvironment.rpmFedora);
  }

  Future<ToolInstallResult> _installDebTools(_HostDistribution distribution) {
    if (distribution.family == _LinuxDistributionFamily.deb) {
      return _installFlutterAndSystemPackages(
        packagesByManager: const {
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
        },
      );
    }

    return _installBuilderEnvironment(BuilderEnvironment.debBookworm);
  }

  Future<ToolInstallResult> _installTarGzTools(_HostDistribution distribution) {
    return _installFlutterAndSystemPackages(
      packagesByManager: const {
        'dnf': ['git', 'clang', 'cmake', 'ninja-build', 'gtk3-devel', 'tar'],
        'apt-get': [
          'git',
          'clang',
          'cmake',
          'ninja-build',
          'libgtk-3-dev',
          'tar',
        ],
        'zypper': ['git', 'clang', 'cmake', 'ninja', 'gtk3-devel', 'tar'],
        'pacman': ['git', 'clang', 'cmake', 'ninja', 'gtk3', 'tar'],
      },
    );
  }

  Future<ToolInstallResult> _installWindowsTools(
    _HostDistribution distribution,
  ) {
    return _toolchainService.installSystemPackages(
      packagesByManager: const {
        'dnf': ['zip'],
        'apt-get': ['zip'],
        'zypper': ['zip'],
        'pacman': ['zip'],
      },
    );
  }

  Future<ToolInstallResult> _installAndroidTools(
    _HostDistribution distribution,
  ) async {
    final results = <String>[];
    _setToolInstallProgress(
      ToolchainInstallTarget.android,
      20,
      'Checking git, unzip and Java.',
      remainingSeconds: 120,
    );
    final systemToolsReady = await _toolchainService.allCommandsAvailable([
      const CommandCheck('git', ['--version']),
      const CommandCheck('unzip', ['-v']),
      const CommandCheck('java', ['-version']),
    ]);
    final systemResult = systemToolsReady
        ? const ToolInstallResult.success(
            'Required system packages are already installed.',
          )
        : await _toolchainService.installSystemPackages(
            packagesByManager: const {
              'dnf': ['git', 'unzip', 'java-latest-openjdk-devel'],
              'apt-get': ['git', 'unzip', 'openjdk-17-jdk'],
              'zypper': ['git', 'unzip', 'java-17-openjdk-devel'],
              'pacman': ['git', 'unzip', 'jdk17-openjdk'],
            },
          );
    if (!systemResult.success) {
      return systemResult;
    }
    results.add(systemResult.message);

    _setToolInstallProgress(
      ToolchainInstallTarget.android,
      40,
      'Checking Flutter SDK.',
      remainingSeconds: 90,
    );
    final flutterResult = await _installFlutterSdkIfNeeded();
    if (!flutterResult.success) {
      return flutterResult;
    }
    results.add(flutterResult.message);

    if (_androidSdkStatus != ToolAvailability.installed) {
      _setToolInstallProgress(
        ToolchainInstallTarget.android,
        65,
        'Downloading Android command line tools and SDK packages.',
        remainingSeconds: 180,
      );
      final androidResult = await _toolchainService.installAndroidSdk();
      if (!androidResult.success) {
        return androidResult;
      }
      results.add(androidResult.message);
    }

    _setToolInstallProgress(
      ToolchainInstallTarget.android,
      95,
      'Android tools are ready.',
      remainingSeconds: 5,
    );
    return ToolInstallResult.success(results.join('\n'));
  }

  Future<ToolInstallResult> _installAppImageTools(
    _HostDistribution distribution,
  ) async {
    ToolInstallResult? systemResult;
    if (_flutterStatus != ToolAvailability.installed ||
        _linuxToolchainStatus != ToolAvailability.installed) {
      systemResult = await _installFlutterAndSystemPackages(
        packagesByManager: const {
          'dnf': ['git', 'clang', 'cmake', 'ninja-build', 'gtk3-devel'],
          'apt-get': ['git', 'clang', 'cmake', 'ninja-build', 'libgtk-3-dev'],
          'zypper': ['git', 'clang', 'cmake', 'ninja', 'gtk3-devel'],
          'pacman': ['git', 'clang', 'cmake', 'ninja', 'gtk3'],
        },
      );
      if (!systemResult.success) {
        return systemResult;
      }
    }

    if (_appImageToolStatus == ToolAvailability.installed) {
      return systemResult ??
          const ToolInstallResult.success(
            'Required tools are already installed.',
          );
    }

    final appImageToolResult = await _toolchainService.installAppImageTool();
    if (!appImageToolResult.success) {
      return appImageToolResult;
    }

    if (systemResult != null) {
      return ToolInstallResult.success(
        '${systemResult.message}\n${appImageToolResult.message}',
      );
    }
    return appImageToolResult;
  }

  Future<ToolInstallResult> _installBuilderEnvironment(
    BuilderEnvironment builder,
  ) async {
    if (_containerRuntimeStatus != ToolAvailability.installed) {
      final runtimeResult = await _installDockerTools();
      if (!runtimeResult.success) {
        return runtimeResult;
      }
    }

    ToolInstallResult? result;
    await for (final event in _builderService.installBuilder(builder)) {
      final eventResult = event.result;
      if (eventResult != null) {
        result = eventResult;
        continue;
      }
      if (!mounted) {
        continue;
      }
      setState(() {
        _installProgress = ToolInstallProgress(
          target: builder.id == BuilderEnvironmentId.debBookworm
              ? ToolchainInstallTarget.deb
              : ToolchainInstallTarget.rpm,
          progress: event.progress ?? 0,
          remainingSeconds: event.remainingSeconds ?? 0,
          detail: event.detail ?? '',
        );
      });
    }

    return result ??
        const ToolInstallResult.failure('Builder installation did not finish.');
  }

  Future<ToolInstallResult> _installFlutterAndSystemPackages({
    required Map<String, List<String>> packagesByManager,
  }) async {
    final results = <String>[];
    final systemResult = await _installSystemPackagesIfNeeded(
      packagesByManager: packagesByManager,
    );
    if (!systemResult.success) {
      return systemResult;
    }
    results.add(systemResult.message);

    final flutterResult = await _installFlutterSdkIfNeeded();
    if (!flutterResult.success) {
      return flutterResult;
    }
    results.add(flutterResult.message);

    return ToolInstallResult.success(results.join('\n'));
  }

  Future<ToolInstallResult> _installSystemPackagesIfNeeded({
    required Map<String, List<String>> packagesByManager,
    bool force = false,
  }) async {
    final hasMissingCommonTools =
        _flutterStatus != ToolAvailability.installed ||
        _linuxToolchainStatus != ToolAvailability.installed;
    if (!force && !hasMissingCommonTools) {
      return const ToolInstallResult.success(
        'Required system packages are already installed.',
      );
    }
    return _toolchainService.installSystemPackages(
      packagesByManager: packagesByManager,
    );
  }

  Future<ToolInstallResult> _installFlutterSdkIfNeeded() {
    if (_flutterStatus == ToolAvailability.installed) {
      return Future.value(
        const ToolInstallResult.success('Flutter SDK is already installed.'),
      );
    }
    return _toolchainService.installFlutterSdk();
  }

  Future<ToolInstallResult> _installDockerTools() async {
    final installResult = await _toolchainService.installSystemPackages(
      packagesByManager: const {
        'dnf': ['moby-engine', 'docker-cli', 'containerd'],
        'apt-get': ['docker.io'],
        'zypper': ['docker'],
        'pacman': ['docker'],
      },
    );
    if (!installResult.success) {
      return installResult;
    }

    final serviceResult = await _toolchainService.enableDockerService();
    if (!serviceResult.success) {
      return serviceResult;
    }

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
    _runningProjectProcess?.kill(ProcessSignal.sigterm);
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
    _packageMetadataController.dispose();
    _packageDependenciesController.dispose();
    super.dispose();
  }

  Future<void> _runBuild() async {
    if (_isBuilding) {
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
            hadWarning = hadWarning || logEntry.state == BuildLogState.warning;
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
    } finally {
      if (mounted) {
        setState(() {
          _isBuilding = false;
          _buildProgress = 0;
          _replaceRoadmapWithPreview();
        });
        if (shouldShowSuccess) {
          await _showBuildSuccessDialog();
        }
      }
    }
  }

  Future<void> _runProjectWithoutBuild() async {
    if (_isBuilding || _isRunningProject) {
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

  Future<Process> _startFlutterRun(String projectPath) async {
    ProcessException? lastError;
    for (final executable in _flutterExecutableCandidates()) {
      try {
        return await Process.start(
          executable,
          ['run', '-d', 'linux'],
          workingDirectory: projectPath,
          runInShell: true,
          environment: _runEnvironment(),
        );
      } on ProcessException catch (error) {
        lastError = error;
      }
    }

    throw lastError ??
        const ProcessException('flutter', [
          'run',
          '-d',
          'linux',
        ], 'Flutter executable was not found.');
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

  List<String> _flutterExecutableCandidates() {
    final managedFlutter = _managedFlutterExecutable();
    return ['flutter', if (managedFlutter.existsSync()) managedFlutter.path];
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

  void _setProjectPath(String path) {
    final windowSize = _readFlutterWindowSize(path);
    final projectMetadata = _readProjectMetadata(path);
    final projectAppName = projectMetadata.name;

    setState(() {
      _projectPath = path;
      _projectChecks
        ..clear()
        ..addAll(_buildProjectChecks(path, projectMetadata));
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

  Future<void> _importProjectConfig() async {
    if (_isBuilding) {
      return;
    }

    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(label: context.l10n.configFileType, extensions: ['json']),
      ],
      confirmButtonText: context.l10n.importConfig,
    );
    if (file == null || !mounted) {
      return;
    }

    try {
      final config = await _projectConfigService.load(file.path);
      if (!mounted) {
        return;
      }
      _applyProjectConfig(config);
      _showSnackBar(context.l10n.configImported);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.configImportFailed(error.toString()));
    }
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
      if (!mounted) {
        return;
      }
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

  List<ProjectCheck> _buildProjectChecks(
    String projectPath,
    _ProjectMetadata metadata,
  ) {
    final l10n = context.l10n;
    final hasPubspec = File(
      _joinPath(projectPath, 'pubspec.yaml'),
    ).existsSync();
    final hasLinuxRunner = File(
      _joinPath(projectPath, 'linux/runner/my_application.cc'),
    ).existsSync();
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
      if (!hasLinuxRunner && !hasWindowsRunner)
        ProjectCheck(label: l10n.desktopRunnersMissing, tone: ChipTone.warning),
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

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset('assets/icon.png'),
        ),
        title: Text(l10n.appTitle),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final content = _WorkspaceContent(
              index: _workspaceIndex,
              themeMode: widget.themeMode,
              localeMode: widget.localeMode,
              toolGroups: toolGroups,
              installingToolTarget: _installingToolTarget,
              projectPath: _projectPath,
              projectChecks: _projectChecks,
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
              debAdditionalDependenciesController:
                  _debAdditionalDependenciesController,
              rpmAdditionalDependenciesController:
                  _rpmAdditionalDependenciesController,
              packageInspection: _packageInspection,
              packageMetadataController: _packageMetadataController,
              packageDependenciesController: _packageDependenciesController,
              isInspectingPackage: _isInspectingPackage,
              targets: _targets,
              selectedTargets: selectedTargets,
              isBuilding: _isBuilding,
              isRunningProject: _isRunningProject,
              progress: _buildProgress,
              roadmapSteps: _roadmapSteps,
              log: _buildLog,
              onThemeModeChanged: widget.onThemeModeChanged,
              onLocaleModeChanged: widget.onLocaleModeChanged,
              onInstallTools: _installTools,
              onRemoveTools: _removeTools,
              onCancelInstall: _cancelToolInstall,
              onChooseProject: _chooseProjectFolder,
              onImportConfig: _importProjectConfig,
              onExportConfig: _exportProjectConfig,
              onChooseIcon: _chooseIconFile,
              onChooseOutput: _chooseOutputFolder,
              onChoosePackage: _choosePackageFile,
              onTargetChanged: _setTargetSelection,
              onSaveEditedPackage: _saveEditedPackage,
              onBuild: _runBuild,
              onRunProject: _runProjectWithoutBuild,
              onStopProject: _stopRunningProject,
            );

            if (isWide) {
              return Row(
                children: [
                  NavigationRail(
                    selectedIndex: _workspaceIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _workspaceIndex = index;
                      });
                    },
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final workspace in workspaces)
                        NavigationRailDestination(
                          icon: Icon(workspace.icon),
                          selectedIcon: Icon(workspace.selectedIcon),
                          label: Text(workspace.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              );
            }

            return Column(
              children: [
                Expanded(child: content),
                NavigationBar(
                  selectedIndex: _workspaceIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _workspaceIndex = index;
                    });
                  },
                  destinations: [
                    for (final workspace in workspaces)
                      NavigationDestination(
                        icon: Icon(workspace.icon),
                        selectedIcon: Icon(workspace.selectedIcon),
                        label: workspace.label,
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
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

enum _LinuxDistributionFamily { deb, rpm, unsupportedRpm, unknown }

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
    required this.projectChecks,
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
    required this.packageInspection,
    required this.packageMetadataController,
    required this.packageDependenciesController,
    required this.isInspectingPackage,
    required this.targets,
    required this.selectedTargets,
    required this.isBuilding,
    required this.isRunningProject,
    required this.progress,
    required this.roadmapSteps,
    required this.log,
    required this.onThemeModeChanged,
    required this.onLocaleModeChanged,
    required this.onInstallTools,
    required this.onRemoveTools,
    required this.onCancelInstall,
    required this.onChooseProject,
    required this.onImportConfig,
    required this.onExportConfig,
    required this.onChooseIcon,
    required this.onChooseOutput,
    required this.onChoosePackage,
    required this.onTargetChanged,
    required this.onSaveEditedPackage,
    required this.onBuild,
    required this.onRunProject,
    required this.onStopProject,
  });

  final int index;
  final ThemeMode themeMode;
  final AppLocaleMode localeMode;
  final List<ToolchainGroup> toolGroups;
  final ToolchainInstallTarget? installingToolTarget;
  final String? projectPath;
  final List<ProjectCheck> projectChecks;
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
  final PackageInspection? packageInspection;
  final TextEditingController packageMetadataController;
  final TextEditingController packageDependenciesController;
  final bool isInspectingPackage;
  final List<BuildTarget> targets;
  final int selectedTargets;
  final bool isBuilding;
  final bool isRunningProject;
  final int progress;
  final List<BuildRoadmapStep> roadmapSteps;
  final List<BuildLogEntry> log;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<AppLocaleMode> onLocaleModeChanged;
  final ValueChanged<ToolchainInstallTarget> onInstallTools;
  final ValueChanged<ToolchainInstallTarget> onRemoveTools;
  final VoidCallback onCancelInstall;
  final VoidCallback onChooseProject;
  final VoidCallback onImportConfig;
  final VoidCallback onExportConfig;
  final VoidCallback onChooseIcon;
  final VoidCallback onChooseOutput;
  final VoidCallback onChoosePackage;
  final void Function(BuildTarget target, bool selected) onTargetChanged;
  final VoidCallback onSaveEditedPackage;
  final VoidCallback onBuild;
  final VoidCallback onRunProject;
  final VoidCallback onStopProject;

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
          projectPath: projectPath,
          checks: projectChecks,
          onChooseProject: onChooseProject,
          onImportConfig: onImportConfig,
          onExportConfig: onExportConfig,
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
        ),
      ],
      2 => [
        BuildPanel(
          selectedTargets: selectedTargets,
          isBuilding: isBuilding,
          isRunning: isRunningProject,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
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
