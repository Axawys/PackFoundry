import 'package:flutter/material.dart';

import '../../core/models/build_log_entry.dart';
import '../../l10n/app_localizations.dart';
import 'section.dart';

class BuildPanel extends StatelessWidget {
  const BuildPanel({
    required this.selectedTargets,
    required this.isBuilding,
    required this.progress,
    required this.log,
    required this.onBuild,
    super.key,
  });

  final int selectedTargets;
  final bool isBuilding;
  final int progress;
  final List<BuildLogEntry> log;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Section(
      title: l10n.build,
      icon: Icons.play_circle_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.selectedTargets(selectedTargets),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (isBuilding || progress > 0) ...[
            LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: isBuilding || selectedTargets == 0 ? null : onBuild,
              icon: Icon(
                isBuilding
                    ? Icons.hourglass_top_outlined
                    : Icons.rocket_launch_outlined,
              ),
              label: Text(isBuilding ? l10n.building : l10n.buildInstallers),
            ),
          ),
          const SizedBox(height: 16),
          for (final entry in log) _LogEntryTile(entry: entry),
        ],
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final BuildLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_entryIcon(entry.state), color: _entryColor(context), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(entry.detail),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _entryIcon(BuildLogState state) {
    return switch (state) {
      BuildLogState.idle => Icons.radio_button_unchecked,
      BuildLogState.running => Icons.sync,
      BuildLogState.success => Icons.check_circle_outline,
      BuildLogState.warning => Icons.warning_amber_outlined,
    };
  }

  Color _entryColor(BuildContext context) {
    return switch (entry.state) {
      BuildLogState.idle => Theme.of(context).colorScheme.onSurfaceVariant,
      BuildLogState.running => Theme.of(context).colorScheme.primary,
      BuildLogState.success => const Color(0xFF16A34A),
      BuildLogState.warning => const Color(0xFFF59E0B),
    };
  }
}
