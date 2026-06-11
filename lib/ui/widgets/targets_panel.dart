import 'package:flutter/material.dart';

import '../../core/models/build_target.dart';
import '../../l10n/app_localizations.dart';
import 'section.dart';

class TargetsPanel extends StatelessWidget {
  const TargetsPanel({
    required this.targets,
    required this.onChanged,
    super.key,
  });

  final List<BuildTarget> targets;
  final void Function(BuildTarget target, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Section(
      title: l10n.installers,
      icon: Icons.checklist_outlined,
      child: Column(
        children: [
          for (final target in targets)
            CheckboxListTile(
              value: target.selected,
              onChanged: target.canSelect
                  ? (value) => onChanged(target, value ?? false)
                  : null,
              secondary: Icon(_targetIcon(target)),
              title: Text(l10n.targetTitle(target.platform, target.artifact)),
              subtitle: Text(l10n.targetStatusLabel(target.status.name)),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  IconData _targetIcon(BuildTarget target) {
    return switch (target.platform) {
      'Android' => Icons.android_outlined,
      'Windows' => Icons.window_outlined,
      'macOS' => Icons.laptop_mac_outlined,
      'iOS' => Icons.phone_iphone_outlined,
      _ when target.artifact == 'AppImage' => Icons.apps,
      _ when target.artifact.contains('tar.gz') => Icons.archive_outlined,
      _ => Icons.inventory_2_outlined,
    };
  }
}
