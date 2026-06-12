import 'package:flutter/material.dart';

import '../../core/models/build_log_entry.dart';
import '../../l10n/app_localizations.dart';
import 'section.dart';

class BuildPanel extends StatelessWidget {
  const BuildPanel({
    required this.selectedTargets,
    required this.isBuilding,
    required this.progress,
    required this.roadmapSteps,
    required this.log,
    required this.onBuild,
    super.key,
  });

  final int selectedTargets;
  final bool isBuilding;
  final int progress;
  final List<BuildRoadmapStep> roadmapSteps;
  final List<BuildLogEntry> log;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remainingSeconds = _estimatedRemainingSeconds(roadmapSteps);

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
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _BuildStatusChip(
                  icon: Icons.percent,
                  label: l10n.overallProgressLabel(progress),
                ),
                if (isBuilding && remainingSeconds != null)
                  _BuildStatusChip(
                    icon: Icons.schedule_outlined,
                    label: l10n.buildRemainingTime(remainingSeconds),
                  ),
              ],
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
          if (roadmapSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _BuildRoadmap(steps: roadmapSteps),
          ],
          if (log.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l10n.technicalLog),
              initiallyExpanded: false,
              children: [for (final entry in log) _LogEntryTile(entry: entry)],
            ),
          ],
        ],
      ),
    );
  }

  int? _estimatedRemainingSeconds(List<BuildRoadmapStep> steps) {
    if (steps.isEmpty) {
      return null;
    }

    var total = 0.0;
    for (final step in steps) {
      final estimate = step.estimatedSeconds;
      if (estimate == null || estimate <= 0) {
        continue;
      }

      switch (step.state) {
        case BuildRoadmapStepState.pending:
          total += estimate;
        case BuildRoadmapStepState.running:
          final progressRatio = step.progress.clamp(0, 100) / 100;
          total += estimate * (1 - progressRatio);
        case BuildRoadmapStepState.success:
        case BuildRoadmapStepState.warning:
        case BuildRoadmapStepState.skipped:
          break;
      }
    }

    return total.round();
  }
}

class _BuildStatusChip extends StatelessWidget {
  const _BuildStatusChip({required this.icon, required this.label});

  final IconData icon;
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BuildRoadmap extends StatefulWidget {
  const _BuildRoadmap({required this.steps});

  final List<BuildRoadmapStep> steps;

  @override
  State<_BuildRoadmap> createState() => _BuildRoadmapState();
}

class _BuildRoadmapState extends State<_BuildRoadmap> {
  String? _expandedStepId;
  String? _lastRunningStepId;

  @override
  void initState() {
    super.initState();
    _syncExpandedStepWithRunningStep();
  }

  @override
  void didUpdateWidget(_BuildRoadmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncExpandedStepWithRunningStep();
    if (_expandedStepId == null) {
      return;
    }
    final stillExists = widget.steps.any((step) => step.id == _expandedStepId);
    if (!stillExists) {
      _expandedStepId = null;
    }
  }

  void _syncExpandedStepWithRunningStep() {
    final runningStepId = _runningStepId();
    if (runningStepId != null && runningStepId != _lastRunningStepId) {
      _expandedStepId = runningStepId;
    }
    _lastRunningStepId = runningStepId;
  }

  String? _runningStepId() {
    for (final step in widget.steps) {
      if (step.state == BuildRoadmapStepState.running) {
        return step.id;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedWidth = constraints.maxWidth < 520
            ? constraints.maxWidth
            : 520.0;

        return Wrap(
          spacing: 10,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var index = 0; index < widget.steps.length; index++) ...[
              _RoadmapStepCard(
                step: widget.steps[index],
                expanded: widget.steps[index].id == _expandedStepId,
                expandedWidth: expandedWidth,
                onTap: () {
                  setState(() {
                    final stepId = widget.steps[index].id;
                    _expandedStepId = _expandedStepId == stepId ? null : stepId;
                  });
                },
              ),
              if (index != widget.steps.length - 1)
                Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _RoadmapStepCard extends StatelessWidget {
  const _RoadmapStepCard({
    required this.step,
    required this.expanded,
    required this.expandedWidth,
    required this.onTap,
  });

  final BuildRoadmapStep step;
  final bool expanded;
  final double expandedWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(context);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final running = step.state == BuildRoadmapStepState.running;

    return Semantics(
      button: true,
      label: expanded ? l10n.roadmapCollapseHint : l10n.roadmapExpandHint,
      child: AnimatedContainer(
        width: expanded ? expandedWidth : 235,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: expanded ? 0.15 : 0.10),
                border: Border.all(color: color.withValues(alpha: 0.55)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.all(expanded ? 14 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: color,
                          child: Text(
                            step.number.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.roadmapStepTitle(step.id, step.title),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Icon(_stepIcon(), color: color, size: 18),
                        const SizedBox(width: 4),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.roadmapStepDescription(step.id, step.description),
                    ),
                    if (step.detail != null && step.detail!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.roadmapDetail(step.detail!),
                        maxLines: expanded ? null : 2,
                        overflow: expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (running) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: step.progress.clamp(0, 100) / 100,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _estimateText(context),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    AnimatedSize(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: expanded
                          ? _ExpandedRoadmapDetails(
                              step: step,
                              running: running,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _estimateText(BuildContext context) {
    final seconds = step.estimatedSeconds;
    if (seconds == null) {
      return context.l10n.roadmapRunning;
    }
    if (seconds < 60) {
      return context.l10n.roadmapUsuallySeconds(seconds);
    }
    return context.l10n.roadmapUsuallyMinutes((seconds / 60).round());
  }

  IconData _stepIcon() {
    return switch (step.state) {
      BuildRoadmapStepState.pending => Icons.radio_button_unchecked,
      BuildRoadmapStepState.running => Icons.sync,
      BuildRoadmapStepState.success => Icons.check_circle_outline,
      BuildRoadmapStepState.warning => Icons.error_outline,
      BuildRoadmapStepState.skipped => Icons.skip_next_outlined,
    };
  }

  Color _stepColor(BuildContext context) {
    return switch (step.state) {
      BuildRoadmapStepState.pending => Theme.of(context).colorScheme.outline,
      BuildRoadmapStepState.running => Theme.of(context).colorScheme.primary,
      BuildRoadmapStepState.success => const Color(0xFF16A34A),
      BuildRoadmapStepState.warning => const Color(0xFFDC2626),
      BuildRoadmapStepState.skipped => const Color(0xFFF59E0B),
    };
  }
}

class _ExpandedRoadmapDetails extends StatelessWidget {
  const _ExpandedRoadmapDetails({required this.step, required this.running});

  final BuildRoadmapStep step;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 6),
          Text(
            l10n.roadmapDetailsTitle,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(l10n.roadmapStepExpandedDetail(step.id)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RoadmapInfoChip(
                icon: Icons.flag_outlined,
                label: l10n.roadmapStatusLabel(step.state.name),
              ),
              _RoadmapInfoChip(
                icon: Icons.percent,
                label: l10n.roadmapProgressLabel(step.progress),
              ),
              if (running)
                _RoadmapInfoChip(
                  icon: Icons.timer_outlined,
                  label: _estimateText(context),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _estimateText(BuildContext context) {
    final seconds = step.estimatedSeconds;
    if (seconds == null) {
      return context.l10n.roadmapRunning;
    }
    if (seconds < 60) {
      return context.l10n.roadmapUsuallySeconds(seconds);
    }
    return context.l10n.roadmapUsuallyMinutes((seconds / 60).round());
  }
}

class _RoadmapInfoChip extends StatelessWidget {
  const _RoadmapInfoChip({required this.icon, required this.label});

  final IconData icon;
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
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
