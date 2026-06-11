import 'package:flutter/material.dart';

import '../../core/models/chip_tone.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.tone, super.key});

  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      ChipTone.good => (
        foreground: const Color(0xFF166534),
        background: const Color(0xFFDCFCE7),
      ),
      ChipTone.warning => (
        foreground: const Color(0xFF92400E),
        background: const Color(0xFFFEF3C7),
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
