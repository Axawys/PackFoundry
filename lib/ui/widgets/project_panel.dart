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
    super.key,
  });

  final String? projectPath;
  final List<ProjectCheck> checks;
  final VoidCallback onChooseProject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Section(
      title: l10n.project,
      icon: Icons.folder_open_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  projectPath ?? l10n.noProjectSelected,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onChooseProject,
                icon: const Icon(Icons.folder_outlined),
                label: Text(l10n.chooseFolder),
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
