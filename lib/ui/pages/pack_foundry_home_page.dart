import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../core/models/build_configuration.dart';
import '../../core/models/build_log_entry.dart';
import '../../core/models/build_target.dart';
import '../../core/models/tool_status.dart';
import '../../core/services/build_service.dart';
import '../widgets/app_settings_panel.dart';
import '../widgets/build_panel.dart';
import '../widgets/project_panel.dart';
import '../widgets/targets_panel.dart';
import '../widgets/toolchain_panel.dart';

class PackFoundryHomePage extends StatefulWidget {
  const PackFoundryHomePage({super.key});

  @override
  State<PackFoundryHomePage> createState() => _PackFoundryHomePageState();
}

class _PackFoundryHomePageState extends State<PackFoundryHomePage> {
  final _buildService = BuildService();
  final _appNameController = TextEditingController(text: 'My Flutter App');
  final _widthController = TextEditingController(text: '1280');
  final _heightController = TextEditingController(text: '800');
  final _buildLog = <BuildLogEntry>[
    const BuildLogEntry(
      title: 'Ready',
      detail: 'Choose a project and select target installers to begin.',
      state: BuildLogState.idle,
    ),
  ];

  String? _projectPath;
  String? _iconPath;
  String? _outputPath;
  bool _isBuilding = false;
  int _buildProgress = 0;

  final List<ToolStatus> _tools = const [
    ToolStatus(
      name: 'Flutter SDK',
      command: 'flutter',
      status: ToolAvailability.installed,
      note: 'Required for every build target.',
    ),
    ToolStatus(
      name: 'Linux toolchain',
      command: 'clang, cmake, ninja, GTK',
      status: ToolAvailability.installed,
      note: 'Builds AppImage, deb, rpm and tar.gz on Linux hosts.',
    ),
    ToolStatus(
      name: 'Docker',
      command: 'docker',
      status: ToolAvailability.missing,
      note: 'Adds repeatable package builders and isolated build images.',
    ),
    ToolStatus(
      name: 'Inno Setup',
      command: 'iscc.exe',
      status: ToolAvailability.available,
      note: 'Can be installed for Windows .exe installers through Wine.',
    ),
    ToolStatus(
      name: 'Android SDK',
      command: 'sdkmanager, gradle',
      status: ToolAvailability.missing,
      note: 'Enables APK and AAB release artifacts.',
    ),
  ];

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
        const BuildLogEntry(
          title: 'Project is not selected',
          detail: 'Choose a Flutter project folder before building installers.',
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
    final path = await getDirectoryPath(confirmButtonText: 'Choose project');
    if (path == null || !mounted) {
      return;
    }

    setState(() {
      _projectPath = path;
    });
  }

  Future<void> _chooseOutputFolder() async {
    final path = await getDirectoryPath(confirmButtonText: 'Choose output');
    if (path == null || !mounted) {
      return;
    }

    setState(() {
      _outputPath = path;
    });
  }

  Future<void> _chooseIconFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Application icons', extensions: ['png', 'svg']),
      ],
      confirmButtonText: 'Choose icon',
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
    final selectedTargets = _targets.where((target) => target.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PackFoundry'),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined),
            label: const Text('Install tools'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _LeftColumn(
                      projectPath: _projectPath,
                      iconPath: _iconPath,
                      outputPath: _outputPath,
                      appNameController: _appNameController,
                      widthController: _widthController,
                      heightController: _heightController,
                      targets: _targets,
                      onChooseProject: _chooseProjectFolder,
                      onChooseIcon: _chooseIconFile,
                      onChooseOutput: _chooseOutputFolder,
                      onTargetChanged: _setTargetSelection,
                      padding: const EdgeInsets.fromLTRB(24, 16, 12, 24),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: _RightColumn(
                      tools: _tools,
                      selectedTargets: selectedTargets,
                      isBuilding: _isBuilding,
                      progress: _buildProgress,
                      log: _buildLog,
                      onBuild: _runBuild,
                      padding: const EdgeInsets.fromLTRB(12, 16, 24, 24),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  _LeftColumn(
                    projectPath: _projectPath,
                    iconPath: _iconPath,
                    outputPath: _outputPath,
                    appNameController: _appNameController,
                    widthController: _widthController,
                    heightController: _heightController,
                    targets: _targets,
                    onChooseProject: _chooseProjectFolder,
                    onChooseIcon: _chooseIconFile,
                    onChooseOutput: _chooseOutputFolder,
                    onTargetChanged: _setTargetSelection,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  ),
                  _RightColumn(
                    tools: _tools,
                    selectedTargets: selectedTargets,
                    isBuilding: _isBuilding,
                    progress: _buildProgress,
                    log: _buildLog,
                    onBuild: _runBuild,
                    padding: const EdgeInsets.all(24),
                  ),
                ],
              ),
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

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({
    required this.projectPath,
    required this.iconPath,
    required this.outputPath,
    required this.appNameController,
    required this.widthController,
    required this.heightController,
    required this.targets,
    required this.onChooseProject,
    required this.onChooseIcon,
    required this.onChooseOutput,
    required this.onTargetChanged,
    required this.padding,
  });

  final String? projectPath;
  final String? iconPath;
  final String? outputPath;
  final TextEditingController appNameController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final List<BuildTarget> targets;
  final VoidCallback onChooseProject;
  final VoidCallback onChooseIcon;
  final VoidCallback onChooseOutput;
  final void Function(BuildTarget target, bool selected) onTargetChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            outputPath: outputPath,
            onChooseIcon: onChooseIcon,
            onChooseOutput: onChooseOutput,
          ),
          const SizedBox(height: 16),
          TargetsPanel(targets: targets, onChanged: onTargetChanged),
        ],
      ),
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({
    required this.tools,
    required this.selectedTargets,
    required this.isBuilding,
    required this.progress,
    required this.log,
    required this.onBuild,
    required this.padding,
  });

  final List<ToolStatus> tools;
  final int selectedTargets;
  final bool isBuilding;
  final int progress;
  final List<BuildLogEntry> log;
  final VoidCallback onBuild;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolchainPanel(tools: tools),
          const SizedBox(height: 16),
          BuildPanel(
            selectedTargets: selectedTargets,
            isBuilding: isBuilding,
            progress: progress,
            log: log,
            onBuild: onBuild,
          ),
        ],
      ),
    );
  }
}
