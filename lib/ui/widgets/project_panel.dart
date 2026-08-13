import 'package:flutter/material.dart';

import '../../core/models/chip_tone.dart';
import '../../l10n/app_localizations.dart';
import 'section.dart';
import 'status_chip.dart';

class ProjectPanel extends StatelessWidget {
  const ProjectPanel({
    required this.pathController,
    required this.checks,
    required this.onChooseProject,
    required this.onPathSubmitted,
    super.key,
  });

  final TextEditingController pathController;
  final List<ProjectCheck> checks;
  final VoidCallback onChooseProject;
  final VoidCallback onPathSubmitted;

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
              SizedBox(
                width: 520,
                child: Focus(
                  // Typing a path only counts once the field is left or Enter
                  // is pressed, so half-typed paths are not applied.
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) {
                      onPathSubmitted();
                    }
                  },
                  child: TextField(
                    controller: pathController,
                    decoration: InputDecoration(
                      labelText: l10n.projectPath,
                      hintText: l10n.noProjectSelected,
                      prefixIcon: const Icon(Icons.folder_outlined),
                    ),
                    onSubmitted: (_) => onPathSubmitted(),
                  ),
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
