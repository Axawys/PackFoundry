import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'section.dart';

class BuildDestinationPanel extends StatelessWidget {
  const BuildDestinationPanel({
    required this.outputPath,
    required this.onChooseOutput,
    super.key,
  });

  final String? outputPath;
  final VoidCallback onChooseOutput;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Section(
      title: l10n.buildOutput,
      icon: Icons.drive_folder_upload_outlined,
      child: Row(
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
    );
  }
}
