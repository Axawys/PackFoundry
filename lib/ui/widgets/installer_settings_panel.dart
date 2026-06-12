import 'package:flutter/material.dart';

import '../../core/models/build_target.dart';
import '../../l10n/app_localizations.dart';
import 'section.dart';

class InstallerSettingsPanel extends StatelessWidget {
  const InstallerSettingsPanel({
    required this.appNameController,
    required this.outputPath,
    required this.targets,
    required this.onChooseOutput,
    required this.onChanged,
    super.key,
  });

  final TextEditingController appNameController;
  final String? outputPath;
  final List<BuildTarget> targets;
  final VoidCallback onChooseOutput;
  final void Function(BuildTarget target, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Section(
      title: l10n.installers,
      icon: Icons.checklist_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: appNameController,
            decoration: InputDecoration(labelText: l10n.applicationName),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  outputPath ?? l10n.defaultOutput,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onChooseOutput,
                icon: const Icon(Icons.folder_special_outlined),
                label: Text(l10n.chooseExportFolder),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 8),
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
