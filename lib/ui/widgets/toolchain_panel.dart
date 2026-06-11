import 'package:flutter/material.dart';

import '../../core/models/tool_status.dart';
import '../../l10n/app_localizations.dart';
import 'section.dart';

class ToolchainPanel extends StatelessWidget {
  const ToolchainPanel({
    required this.groups,
    required this.installingTarget,
    required this.onInstallTools,
    super.key,
  });

  final List<ToolchainGroup> groups;
  final ToolchainInstallTarget? installingTarget;
  final ValueChanged<ToolchainInstallTarget> onInstallTools;

  @override
  Widget build(BuildContext context) {
    return Section(
      title: context.l10n.toolchain,
      icon: Icons.construction_outlined,
      child: Column(
        children: [
          for (final group in groups) ...[
            _ToolchainGroupCard(
              group: group,
              installing: installingTarget == group.installTarget,
              onInstallTools: onInstallTools,
            ),
            if (group != groups.last) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _ToolchainGroupCard extends StatelessWidget {
  const _ToolchainGroupCard({
    required this.group,
    required this.installing,
    required this.onInstallTools,
  });

  final ToolchainGroup group;
  final bool installing;
  final ValueChanged<ToolchainInstallTarget> onInstallTools;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: _statusColor(context, group.status),
                child: const SizedBox(width: 5),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _groupIcon(group.status),
                            color: _statusColor(context, group.status),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.title,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(group.subtitle),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (group.status != ToolAvailability.installed) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: installing
                                ? null
                                : () => onInstallTools(group.installTarget),
                            icon: Icon(
                              installing
                                  ? Icons.hourglass_top_outlined
                                  : Icons.download_outlined,
                            ),
                            label: Text(
                              installing
                                  ? l10n.installingTools
                                  : l10n.installMissingTools,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Divider(height: 1, color: colorScheme.outlineVariant),
                      const SizedBox(height: 12),
                      for (final tool in group.tools) ...[
                        _ToolRow(tool: tool),
                        if (tool != group.tools.last) const Divider(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _groupIcon(ToolAvailability status) {
    return switch (status) {
      ToolAvailability.installed => Icons.task_alt_outlined,
      ToolAvailability.available => Icons.build_circle_outlined,
      ToolAvailability.missing => Icons.report_problem_outlined,
    };
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.tool});

  final ToolStatus tool;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_toolIcon(tool.status), color: _statusColor(context, tool.status)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tool.name, style: Theme.of(context).textTheme.titleSmall),
              Text(tool.command, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(tool.note),
            ],
          ),
        ),
      ],
    );
  }

  IconData _toolIcon(ToolAvailability status) {
    return switch (status) {
      ToolAvailability.installed => Icons.check_circle_outline,
      ToolAvailability.available => Icons.add_circle_outline,
      ToolAvailability.missing => Icons.error_outline,
    };
  }
}

Color _statusColor(BuildContext context, ToolAvailability status) {
  return switch (status) {
    ToolAvailability.installed => const Color(0xFF16A34A),
    ToolAvailability.available => Theme.of(context).colorScheme.primary,
    ToolAvailability.missing => const Color(0xFFF59E0B),
  };
}
