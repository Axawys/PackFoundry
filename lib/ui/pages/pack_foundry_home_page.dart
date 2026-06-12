import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../core/models/build_configuration.dart';
import '../../core/models/build_log_entry.dart';
import '../../core/models/build_target.dart';
import '../../core/models/tool_status.dart';
import '../../core/services/app_preferences.dart';
import '../../core/services/build_service.dart';
import '../../core/services/toolchain_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_settings_panel.dart';
import '../widgets/build_destination_panel.dart';
import '../widgets/build_panel.dart';
import '../widgets/preferences_panel.dart';
import '../widgets/project_panel.dart';
import '../widgets/targets_panel.dart';
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
  final _appNameController = TextEditingController(text: _defaultAppName);
  final _widthController = TextEditingController(text: '1280');
  final _heightController = TextEditingController(text: '800');
  final _buildLog = <BuildLogEntry>[];
  final _roadmapSteps = <BuildRoadmapStep>[];

  String? _projectPath;
  String? _iconPath;
  String? _outputPath;
  bool _isBuilding = false;
  ToolchainInstallTarget? _installingToolTarget;
  int _buildProgress = 0;
  bool _welcomeDialogShown = false;
  int _workspaceIndex = 1;
  ToolAvailability _flutterStatus = ToolAvailability.available;
  ToolAvailability _linuxToolchainStatus = ToolAvailability.available;
  ToolAvailability _dockerStatus = ToolAvailability.available;
  ToolAvailability _appImageToolStatus = ToolAvailability.available;
  ToolAvailability _debToolStatus = ToolAvailability.available;
  ToolAvailability _rpmToolStatus = ToolAvailability.available;
  ToolAvailability _wineStatus = ToolAvailability.available;
  ToolAvailability _innoSetupStatus = ToolAvailability.available;

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
      status: TargetStatus.blocked,
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
    if (widget.enableToolchainDiagnostics) {
      _refreshToolchainStatus();
    }
  }

  Future<void> _refreshToolchainStatus() async {
    final results = await Future.wait([
      _toolchainService.commandAvailability('flutter', ['--version']),
      _linuxToolchainAvailable(),
      _toolchainService.commandAvailability('docker', ['--version']),
      _toolchainService.appImageToolAvailability(),
      _toolchainService.commandAvailability('dpkg-deb', ['--version']),
      _toolchainService.commandAvailability('rpmbuild', ['--version']),
      _toolchainService.commandAvailability('wine', ['--version']),
      _toolchainService.commandAvailability('iscc', ['--version']),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _flutterStatus = results[0];
      _linuxToolchainStatus = results[1];
      _dockerStatus = results[2];
      _appImageToolStatus = results[3];
      _debToolStatus = results[4];
      _rpmToolStatus = results[5];
      _wineStatus = results[6];
      _innoSetupStatus = results[7];
    });
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
      _windowsBuildGroup(l10n),
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
              name: 'Docker',
              command: 'docker',
              status: _dockerStatus,
              note: l10n.dockerDebNote,
            ),
            ToolStatus(
              name: 'Debian builder',
              command: 'debian:bookworm',
              status: _dockerStatus == ToolAvailability.installed
                  ? ToolAvailability.installed
                  : ToolAvailability.available,
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
            name: 'Docker',
            command: 'docker',
            status: _dockerStatus,
            note: l10n.dockerRpmNote,
          ),
          ToolStatus(
            name: 'Fedora builder',
            command: 'fedora container',
            status: ToolAvailability.available,
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

  ToolchainGroup _windowsBuildGroup(AppLocalizations l10n) {
    return ToolchainGroup(
      title: l10n.windowsBuildGroupTitle,
      subtitle: l10n.windowsBuildGroupSubtitle,
      status: ToolAvailability.missing,
      installTarget: ToolchainInstallTarget.exe,
      tools: [
        ToolStatus(
          name: 'Windows build host',
          command: 'windows runner toolchain',
          status: ToolAvailability.missing,
          note: l10n.windowsBuildHostNote,
        ),
        ToolStatus(
          name: 'Wine',
          command: 'wine',
          status: _wineStatus,
          note: l10n.wineNote,
        ),
        ToolStatus(
          name: 'Inno Setup',
          command: 'iscc.exe',
          status: _innoSetupStatus,
          note: l10n.innoSetupNote,
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
    return _dockerStatus == ToolAvailability.installed
        ? ToolAvailability.installed
        : ToolAvailability.available;
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
    return _dockerStatus == ToolAvailability.installed
        ? ToolAvailability.available
        : ToolAvailability.available;
  }

  ToolAvailability get _appImageBuildStatus {
    if (_flutterStatus == ToolAvailability.installed &&
        _linuxToolchainStatus == ToolAvailability.installed &&
        _appImageToolStatus == ToolAvailability.installed) {
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
    });

    final l10n = context.l10n;
    final result = await _runToolInstall(target);

    if (!mounted) {
      return;
    }

    setState(() {
      _installingToolTarget = null;
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

  Future<ToolInstallResult> _runToolInstall(
    ToolchainInstallTarget target,
  ) async {
    final distribution = _hostDistribution;
    return switch (target) {
      ToolchainInstallTarget.rpm => _installRpmTools(distribution),
      ToolchainInstallTarget.deb => _installDebTools(distribution),
      ToolchainInstallTarget.appImage => _installAppImageTools(distribution),
      ToolchainInstallTarget.exe => ToolInstallResult.failure(
        context.l10n.exeInstallUnsupported,
      ),
    };
  }

  Future<ToolInstallResult> _installRpmTools(_HostDistribution distribution) {
    if (distribution.family == _LinuxDistributionFamily.rpm) {
      return _toolchainService.installSystemPackages(
        packagesByManager: const {
          'dnf': ['clang', 'cmake', 'ninja-build', 'gtk3-devel', 'rpm-build'],
          'apt-get': ['clang', 'cmake', 'ninja-build', 'libgtk-3-dev', 'rpm'],
          'zypper': ['clang', 'cmake', 'ninja', 'gtk3-devel', 'rpm-build'],
          'pacman': ['clang', 'cmake', 'ninja', 'gtk3', 'rpm-tools'],
        },
      );
    }

    if (distribution.family == _LinuxDistributionFamily.unsupportedRpm) {
      return Future.value(
        ToolInstallResult.failure(context.l10n.rpmHostInstallUnsupported),
      );
    }

    return _installDockerTools();
  }

  Future<ToolInstallResult> _installDebTools(_HostDistribution distribution) {
    if (distribution.family == _LinuxDistributionFamily.deb) {
      return _toolchainService.installSystemPackages(
        packagesByManager: const {
          'dnf': ['clang', 'cmake', 'ninja-build', 'gtk3-devel', 'dpkg-dev'],
          'apt-get': [
            'clang',
            'cmake',
            'ninja-build',
            'libgtk-3-dev',
            'dpkg-dev',
          ],
          'zypper': ['clang', 'cmake', 'ninja', 'gtk3-devel', 'dpkg'],
          'pacman': ['clang', 'cmake', 'ninja', 'gtk3', 'dpkg'],
        },
      );
    }

    return _installDockerTools();
  }

  Future<ToolInstallResult> _installAppImageTools(
    _HostDistribution distribution,
  ) async {
    ToolInstallResult? systemResult;
    if (_flutterStatus != ToolAvailability.installed ||
        _linuxToolchainStatus != ToolAvailability.installed) {
      systemResult = await _toolchainService.installSystemPackages(
        packagesByManager: const {
          'dnf': ['clang', 'cmake', 'ninja-build', 'gtk3-devel'],
          'apt-get': ['clang', 'cmake', 'ninja-build', 'libgtk-3-dev'],
          'zypper': ['clang', 'cmake', 'ninja', 'gtk3-devel'],
          'pacman': ['clang', 'cmake', 'ninja', 'gtk3'],
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

  Future<ToolInstallResult> _installDockerTools() {
    return _toolchainService.installSystemPackages(
      packagesByManager: const {
        'dnf': ['moby-engine', 'docker-cli', 'containerd'],
        'apt-get': ['docker.io'],
        'zypper': ['docker'],
        'pacman': ['docker'],
      },
    );
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
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
      _roadmapSteps.clear();
    });

    final configuration = BuildConfiguration(
      appName: _appNameController.text,
      projectPath: projectPath,
      outputPath: _outputPath,
      iconPath: _iconPath,
      windowWidth: int.tryParse(_widthController.text),
      windowHeight: int.tryParse(_heightController.text),
      targets: _targets,
    );

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

    if (!mounted) {
      return;
    }
    setState(() {
      _isBuilding = false;
    });
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

    final windowSize = _readFlutterWindowSize(path);
    final projectAppName = _readProjectAppName(path);

    setState(() {
      _projectPath = path;
      if (windowSize != null) {
        _widthController.text = windowSize.width.toString();
        _heightController.text = windowSize.height.toString();
      }
      if (projectAppName != null && _shouldAutofillAppName) {
        _appNameController.text = projectAppName;
      }
    });
  }

  bool get _shouldAutofillAppName {
    final currentName = _appNameController.text.trim();
    return currentName.isEmpty || currentName == _defaultAppName;
  }

  String? _readProjectAppName(String projectPath) {
    final file = File(_joinPath(projectPath, 'pubspec.yaml'));
    if (!file.existsSync()) {
      return null;
    }

    final match = RegExp(
      r'^name:\s*([^\s#]+)',
      multiLine: true,
    ).firstMatch(file.readAsStringSync());
    final rawName = match?.group(1)?.trim();
    if (rawName == null || rawName.isEmpty) {
      return null;
    }

    return rawName
        .split(RegExp(r'[-_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join();
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
              iconPath: _iconPath,
              outputPath: _outputPath,
              appNameController: _appNameController,
              widthController: _widthController,
              heightController: _heightController,
              targets: _targets,
              selectedTargets: selectedTargets,
              isBuilding: _isBuilding,
              progress: _buildProgress,
              roadmapSteps: _roadmapSteps,
              log: _buildLog,
              onThemeModeChanged: widget.onThemeModeChanged,
              onLocaleModeChanged: widget.onLocaleModeChanged,
              onInstallTools: _installTools,
              onChooseProject: _chooseProjectFolder,
              onChooseIcon: _chooseIconFile,
              onChooseOutput: _chooseOutputFolder,
              onTargetChanged: _setTargetSelection,
              onBuild: _runBuild,
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
    setState(() {
      target.selected = selected;
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
    required this.iconPath,
    required this.outputPath,
    required this.appNameController,
    required this.widthController,
    required this.heightController,
    required this.targets,
    required this.selectedTargets,
    required this.isBuilding,
    required this.progress,
    required this.roadmapSteps,
    required this.log,
    required this.onThemeModeChanged,
    required this.onLocaleModeChanged,
    required this.onInstallTools,
    required this.onChooseProject,
    required this.onChooseIcon,
    required this.onChooseOutput,
    required this.onTargetChanged,
    required this.onBuild,
  });

  final int index;
  final ThemeMode themeMode;
  final AppLocaleMode localeMode;
  final List<ToolchainGroup> toolGroups;
  final ToolchainInstallTarget? installingToolTarget;
  final String? projectPath;
  final String? iconPath;
  final String? outputPath;
  final TextEditingController appNameController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final List<BuildTarget> targets;
  final int selectedTargets;
  final bool isBuilding;
  final int progress;
  final List<BuildRoadmapStep> roadmapSteps;
  final List<BuildLogEntry> log;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<AppLocaleMode> onLocaleModeChanged;
  final ValueChanged<ToolchainInstallTarget> onInstallTools;
  final VoidCallback onChooseProject;
  final VoidCallback onChooseIcon;
  final VoidCallback onChooseOutput;
  final void Function(BuildTarget target, bool selected) onTargetChanged;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    final children = switch (index) {
      0 => [
        ToolchainPanel(
          groups: toolGroups,
          installingTarget: installingToolTarget,
          onInstallTools: onInstallTools,
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
          onChooseProject: onChooseProject,
        ),
        const SizedBox(height: 16),
        AppSettingsPanel(
          widthController: widthController,
          heightController: heightController,
          iconPath: iconPath,
          onChooseIcon: onChooseIcon,
        ),
        const SizedBox(height: 16),
        TargetsPanel(targets: targets, onChanged: onTargetChanged),
      ],
      _ => [
        BuildDestinationPanel(
          appNameController: appNameController,
          outputPath: outputPath,
          onChooseOutput: onChooseOutput,
        ),
        const SizedBox(height: 16),
        BuildPanel(
          selectedTargets: selectedTargets,
          isBuilding: isBuilding,
          progress: progress,
          roadmapSteps: roadmapSteps,
          log: log,
          onBuild: onBuild,
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
