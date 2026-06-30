import 'package:flutter/material.dart';

import '../../core/models/tool_status.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'section.dart';

class ToolchainPanel extends StatelessWidget {
  const ToolchainPanel({
    required this.groups,
    required this.installingTarget,
    required this.onInstallTools,
    required this.onRemoveTools,
    required this.onCancelInstall,
    super.key,
  });

  final List<ToolchainGroup> groups;
  final ToolchainInstallTarget? installingTarget;
  final ValueChanged<ToolchainInstallTarget> onInstallTools;
  final ValueChanged<ToolchainInstallTarget> onRemoveTools;
  final VoidCallback onCancelInstall;

  @override
  Widget build(BuildContext context) {
    return Section(
      title: context.l10n.toolchain,
      icon: Icons.construction_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = switch (constraints.maxWidth) {
            >= 1180 => 3,
            >= 720 => 2,
            _ => 1,
          };
          const spacing = 12.0;
          final columnGroups = [
            for (var column = 0; column < columns; column++)
              [
                for (
                  var index = column;
                  index < groups.length;
                  index += columns
                )
                  groups[index],
              ],
          ];

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < columnGroups.length; column++) ...[
                Expanded(
                  child: Column(
                    children: [
                      for (final group in columnGroups[column]) ...[
                        _ToolchainGroupCard(
                          group: group,
                          installing: installingTarget == group.installTarget,
                          onInstallTools: onInstallTools,
                          onRemoveTools: onRemoveTools,
                          onCancelInstall: onCancelInstall,
                        ),
                        if (group != columnGroups[column].last)
                          const SizedBox(height: spacing),
                      ],
                    ],
                  ),
                ),
                if (column != columnGroups.length - 1)
                  const SizedBox(width: spacing),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ToolchainGroupCard extends StatelessWidget {
  const _ToolchainGroupCard({
    required this.group,
    required this.installing,
    required this.onInstallTools,
    required this.onRemoveTools,
    required this.onCancelInstall,
  });

  final ToolchainGroup group;
  final bool installing;
  final ValueChanged<ToolchainInstallTarget> onInstallTools;
  final ValueChanged<ToolchainInstallTarget> onRemoveTools;
  final VoidCallback onCancelInstall;

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
                      if (group.installProgress != null) ...[
                        const SizedBox(height: 12),
                        _InstallProgress(
                          progress: group.installProgress!,
                          onCancel: onCancelInstall,
                        ),
                      ],
                      if (group.status != ToolAvailability.installed ||
                          group.canRemove) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (group.status != ToolAvailability.installed) ...[
                              OutlinedButton.icon(
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
                              if (group.installSizeLabel != null)
                                _InstallSizeBadge(
                                  label: l10n.builderInstallSize(
                                    group.installSizeLabel!,
                                  ),
                                ),
                            ],
                            if (group.canRemove)
                              OutlinedButton.icon(
                                onPressed: installing
                                    ? null
                                    : () => onRemoveTools(group.installTarget),
                                icon: const Icon(Icons.delete_outline),
                                label: Text(l10n.removeBuilder),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Divider(height: 1, color: colorScheme.outlineVariant),
                      const SizedBox(height: 12),
                      for (final tool in group.tools) ...[
                        _ToolRow(tool: tool),
                        if (tool != group.tools.last) const Divider(height: 20),
                      ],
                      if (group.guideSteps.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ToolchainGuide(steps: group.guideSteps),
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

class _InstallSizeBadge extends StatelessWidget {
  const _InstallSizeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sd_storage_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _InstallProgress extends StatelessWidget {
  const _InstallProgress({required this.progress, required this.onCancel});

  final ToolInstallProgress progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.builderInstallProgress(progress.progress),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  l10n.buildRemainingTime(progress.remainingSeconds),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(l10n.cancel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.progress.clamp(0, 100) / 100,
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
            if (progress.detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                progress.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolchainGuide extends StatelessWidget {
  const _ToolchainGuide({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.miniGuide,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < steps.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${index + 1}.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(child: Text(steps[index])),
                ],
              ),
              if (index != steps.length - 1) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
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
              if (tool.showCommand)
                Text(
                  tool.command,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
    ToolAvailability.installed => context.status.success,
    ToolAvailability.available =>
      Theme.of(context).colorScheme.onSurfaceVariant,
    ToolAvailability.missing => context.status.problem,
  };
}
