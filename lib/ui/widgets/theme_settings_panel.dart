import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'section.dart';

class ThemeSettingsPanel extends StatelessWidget {
  const ThemeSettingsPanel({
    required this.themeMode,
    required this.onChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Section(
      title: l10n.themeChoice,
      icon: Icons.palette_outlined,
      child: SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment(
            value: ThemeMode.system,
            icon: const Icon(Icons.brightness_auto_outlined),
            label: Text(l10n.themeSystem),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            icon: const Icon(Icons.light_mode_outlined),
            label: Text(l10n.themeLight),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: const Icon(Icons.dark_mode_outlined),
            label: Text(l10n.themeDark),
          ),
        ],
        selected: {themeMode},
        onSelectionChanged: (selection) => onChanged(selection.single),
      ),
    );
  }
}
