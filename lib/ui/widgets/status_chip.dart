import 'package:flutter/material.dart';

import '../../core/models/chip_tone.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.tone, super.key});

  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    final colors = switch (tone) {
      ChipTone.good => (
        foreground: status.onSuccessContainer,
        background: status.successContainer,
      ),
      ChipTone.warning => (
        foreground: status.onProblemContainer,
        background: status.problemContainer,
      ),
      ChipTone.neutral => (
        foreground: Theme.of(context).colorScheme.onSurfaceVariant,
        background: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    };

    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: colors.foreground),
      backgroundColor: colors.background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
