import 'package:flutter/material.dart';

import '../../core/models/chip_tone.dart';
import 'section.dart';
import 'status_chip.dart';

class ProjectPanel extends StatelessWidget {
  const ProjectPanel({
    required this.projectPath,
    required this.onChooseProject,
    super.key,
  });

  final String? projectPath;
  final VoidCallback onChooseProject;

  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'Project',
      icon: Icons.folder_open_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  projectPath ?? 'No project selected',
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onChooseProject,
                icon: const Icon(Icons.folder_outlined),
                label: const Text('Choose folder'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(label: 'pubspec.yaml', tone: ChipTone.good),
              StatusChip(label: 'desktop enabled', tone: ChipTone.good),
              StatusChip(
                label: 'release signing unknown',
                tone: ChipTone.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
