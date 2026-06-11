import 'chip_tone.dart';

class ToolchainGroup {
  const ToolchainGroup({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.tools,
  });

  final String title;
  final String subtitle;
  final ToolAvailability status;
  final List<ToolStatus> tools;

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
  });

  final String name;
  final String command;
  final ToolAvailability status;
  final String note;

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

enum ToolAvailability { installed, available, missing }
