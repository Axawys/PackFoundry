import 'package:flutter/material.dart';

import '../../core/models/chip_tone.dart';
import '../../l10n/app_localizations.dart';
import 'section.dart';
import 'status_chip.dart';

class ProjectPanel extends StatelessWidget {
  const ProjectPanel({
    required this.projectPath,
    required this.checks,
    required this.onChooseProject,
    required this.onImportConfig,
    required this.onExportConfig,
    super.key,
  });

  final String? projectPath;
  final List<ProjectCheck> checks;
  final VoidCallback onChooseProject;
  final VoidCallback onImportConfig;
  final VoidCallback onExportConfig;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Section(
      title: l10n.project,
      icon: Icons.folder_open_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onChooseProject,
                icon: const Icon(Icons.folder_outlined),
                label: Text(l10n.chooseFolder),
              ),
              OutlinedButton.icon(
                onPressed: onImportConfig,
                icon: const Icon(Icons.file_open_outlined),
                label: Text(l10n.importConfig),
              ),
              OutlinedButton.icon(
                onPressed: onExportConfig,
                icon: const Icon(Icons.save_alt_outlined),
                label: Text(l10n.exportConfig),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  projectPath ?? l10n.noProjectSelected,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (checks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final check in checks)
                  StatusChip(label: check.label, tone: check.tone),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ProjectCheck {
  const ProjectCheck({required this.label, required this.tone});

  final String label;
  final ChipTone tone;
}
