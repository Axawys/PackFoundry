import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../core/models/build_configuration.dart';
import '../../core/models/build_log_entry.dart';
import '../../core/models/build_target.dart';
import '../../core/models/tool_status.dart';
import '../../core/services/build_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_settings_panel.dart';
import '../widgets/build_destination_panel.dart';
import '../widgets/build_panel.dart';
import '../widgets/project_panel.dart';
import '../widgets/targets_panel.dart';
import '../widgets/theme_settings_panel.dart';
import '../widgets/toolchain_panel.dart';
import '../widgets/welcome_dialog.dart';

class PackFoundryHomePage extends StatefulWidget {
  const PackFoundryHomePage({
    required this.themeMode,
    required this.showWelcome,
    required this.onThemeModeChanged,
    required this.onWelcomeCompleted,
    super.key,
  });

  final ThemeMode themeMode;
  final bool showWelcome;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final WelcomeCompleted onWelcomeCompleted;

  @override
  State<PackFoundryHomePage> createState() => _PackFoundryHomePageState();
}

class _PackFoundryHomePageState extends State<PackFoundryHomePage> {
  final _buildService = BuildService();
  final _appNameController = TextEditingController(text: 'My Flutter App');
  final _widthController = TextEditingController(text: '1280');
  final _heightController = TextEditingController(text: '800');
  final _buildLog = <BuildLogEntry>[];

  String? _projectPath;
  String? _iconPath;
  String? _outputPath;
  bool _isBuilding = false;
  int _buildProgress = 0;
  bool _welcomeDialogShown = false;
  int _workspaceIndex = 1;

  final List<BuildTarget> _targets = [
    BuildTarget(
      platform: 'Linux',
      artifact: 'AppImage',
      status: TargetStatus.ready,
      selected: true,
    ),
    BuildTarget(
      platform: 'Linux',
      artifact: 'deb package',
      status: TargetStatus.ready,
      selected: true,
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

  List<ToolStatus> _tools(AppLocalizations l10n) {
    return [
      ToolStatus(
        name: 'Flutter SDK',
        command: 'flutter',
        status: ToolAvailability.installed,
        note: l10n.flutterSdkNote,
      ),
      ToolStatus(
        name: 'Linux toolchain',
        command: 'clang, cmake, ninja, GTK',
        status: ToolAvailability.installed,
        note: l10n.linuxToolchainNote,
      ),
      ToolStatus(
        name: 'Docker',
        command: 'docker',
        status: ToolAvailability.missing,
        note: l10n.dockerNote,
      ),
      ToolStatus(
        name: 'Inno Setup',
        command: 'iscc.exe',
        status: ToolAvailability.available,
        note: l10n.innoSetupNote,
      ),
      ToolStatus(
        name: 'Android SDK',
        command: 'sdkmanager, gradle',
        status: ToolAvailability.missing,
        note: l10n.androidSdkNote,
      ),
    ];
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
        if (logEntry != null) {
          _buildLog.add(logEntry);
        }
        if (progress != null) {
          _buildProgress = progress.clamp(0, 100);
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

  Future<void> _chooseProjectFolder() async {
    final path = await getDirectoryPath(
      confirmButtonText: context.l10n.chooseProject,
    );
    if (path == null || !mounted) {
      return;
    }

    final windowSize = _readFlutterWindowSize(path);

    setState(() {
      _projectPath = path;
      if (windowSize != null) {
        _widthController.text = windowSize.width.toString();
        _heightController.text = windowSize.height.toString();
      }
    });
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
    final tools = _tools(l10n);
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
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final content = _WorkspaceContent(
              index: _workspaceIndex,
              themeMode: widget.themeMode,
              tools: tools,
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
              log: _buildLog,
              onThemeModeChanged: widget.onThemeModeChanged,
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

class _WindowSize {
  const _WindowSize({required this.width, required this.height});

  final int width;
  final int height;
}

class _WorkspaceContent extends StatelessWidget {
  const _WorkspaceContent({
    required this.index,
    required this.themeMode,
    required this.tools,
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
    required this.log,
    required this.onThemeModeChanged,
    required this.onChooseProject,
    required this.onChooseIcon,
    required this.onChooseOutput,
    required this.onTargetChanged,
    required this.onBuild,
  });

  final int index;
  final ThemeMode themeMode;
  final List<ToolStatus> tools;
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
  final List<BuildLogEntry> log;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onChooseProject;
  final VoidCallback onChooseIcon;
  final VoidCallback onChooseOutput;
  final void Function(BuildTarget target, bool selected) onTargetChanged;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    final children = switch (index) {
      0 => [
        ThemeSettingsPanel(themeMode: themeMode, onChanged: onThemeModeChanged),
        const SizedBox(height: 16),
        ToolchainPanel(tools: tools),
      ],
      1 => [
        ProjectPanel(
          projectPath: projectPath,
          onChooseProject: onChooseProject,
        ),
        const SizedBox(height: 16),
        AppSettingsPanel(
          appNameController: appNameController,
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
          outputPath: outputPath,
          onChooseOutput: onChooseOutput,
        ),
        const SizedBox(height: 16),
        BuildPanel(
          selectedTargets: selectedTargets,
          isBuilding: isBuilding,
          progress: progress,
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
