import 'chip_tone.dart';

class ToolchainGroup {
  const ToolchainGroup({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.tools,
    required this.installTarget,
    this.canRemove = false,
    this.installProgress,
    this.installSizeLabel,
    this.guideSteps = const [],
  });

  final String title;
  final String subtitle;
  final ToolAvailability status;
  final List<ToolStatus> tools;
  final ToolchainInstallTarget installTarget;
  final bool canRemove;
  final ToolInstallProgress? installProgress;
  final String? installSizeLabel;
  final List<String> guideSteps;

  ChipTone get chipTone {
    return switch (status) {
      ToolAvailability.installed => ChipTone.good,
      ToolAvailability.available => ChipTone.neutral,
      ToolAvailability.missing => ChipTone.warning,
    };
  }
}

class ToolStatus {
  const ToolStatus({
    required this.name,
    required this.command,
    required this.status,
    required this.note,
    this.showCommand = true,
  });

  final String name;
  final String command;
  final ToolAvailability status;
  final String note;
  final bool showCommand;

  String get statusLabel {
    return switch (status) {
      ToolAvailability.installed => 'Installed',
      ToolAvailability.available => 'Installable',
      ToolAvailability.missing => 'Missing',
    };
  }

  ChipTone get chipTone {
    return switch (status) {
      ToolAvailability.installed => ChipTone.good,
      ToolAvailability.available => ChipTone.neutral,
      ToolAvailability.missing => ChipTone.warning,
    };
  }
}

class ToolInstallProgress {
  const ToolInstallProgress({
    required this.target,
    required this.progress,
    required this.remainingSeconds,
    required this.detail,
  });

  final ToolchainInstallTarget target;
  final int progress;
  final int remainingSeconds;
  final String detail;
}

enum ToolAvailability { installed, available, missing }

enum ToolchainInstallTarget { rpm, deb, appImage, tarGz, exe }
