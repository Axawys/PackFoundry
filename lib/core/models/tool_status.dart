import 'chip_tone.dart';

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
