import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/build_configuration.dart';
import '../../core/models/build_log_entry.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'section.dart';

/// Build workspace: the step plan on one side and, on the other, the shell
/// commands of the selected step together with the live process log.
class BuildPanel extends StatefulWidget {
  const BuildPanel({
    required this.selectedTargets,
    required this.isBuilding,
    required this.progress,
    required this.roadmapSteps,
    required this.log,
    required this.onBuild,
    required this.isRunning,
    required this.canRun,
    required this.onRun,
    required this.onStop,
    this.configuration,
    super.key,
  });

  final int selectedTargets;
  final bool isBuilding;
  final int progress;
  final List<BuildRoadmapStep> roadmapSteps;
  final List<BuildLogEntry> log;
  final VoidCallback onBuild;
  final bool isRunning;
  final bool canRun;
  final VoidCallback onRun;
  final VoidCallback onStop;
  final BuildConfiguration? configuration;

  @override
  State<BuildPanel> createState() => _BuildPanelState();
}

class _BuildPanelState extends State<BuildPanel> {
  /// Height of the split view when the panel is placed in a scrollable parent
  /// and cannot simply fill the viewport.
  static const _fallbackBodyHeight = 640.0;
  static const _sideBySideMinWidth = 860.0;

  String? _selectedStepId;
  String? _lastRunningStepId;

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  @override
  void didUpdateWidget(BuildPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelection();
  }

  /// Follows the running step, but keeps a step the user picked until the
  /// build moves on to the next one.
  void _syncSelection() {
    final steps = widget.roadmapSteps;
    String? runningStepId;
    for (final step in steps) {
      if (step.state == BuildRoadmapStepState.running) {
        runningStepId = step.id;
        break;
      }
    }
    if (runningStepId != null && runningStepId != _lastRunningStepId) {
      _selectedStepId = runningStepId;
    }
    _lastRunningStepId = runningStepId;

    final selectionExists = steps.any((step) => step.id == _selectedStepId);
    if (!selectionExists) {
      _selectedStepId = steps.isEmpty ? null : steps.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        final body = _buildBody(constraints.maxWidth);
        return Section(
          title: context.l10n.build,
          icon: Icons.play_circle_outline,
          expand: bounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolbar(context),
              const SizedBox(height: 16),
              if (bounded)
                Expanded(child: body)
              else
                SizedBox(height: _fallbackBodyHeight, child: body),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final l10n = context.l10n;
    final remainingSeconds = _estimatedRemainingSeconds(widget.roadmapSteps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed:
                  widget.isBuilding ||
                      widget.isRunning ||
                      widget.selectedTargets == 0
                  ? null
                  : widget.onBuild,
              icon: Icon(
                widget.isBuilding
                    ? Icons.hourglass_top_outlined
                    : Icons.rocket_launch_outlined,
              ),
              label: Text(
                widget.isBuilding ? l10n.building : l10n.buildInstallers,
              ),
            ),
            if (widget.canRun)
              OutlinedButton.icon(
                onPressed: widget.isBuilding
                    ? null
                    : widget.isRunning
                    ? widget.onStop
                    : widget.onRun,
                icon: Icon(
                  widget.isRunning
                      ? Icons.stop_circle_outlined
                      : Icons.play_arrow_outlined,
                ),
                label: Text(
                  widget.isRunning ? l10n.stopRunningApp : l10n.runWithoutBuild,
                ),
              ),
            if (widget.isRunning)
              _BuildStatusChip(
                icon: Icons.play_circle_outline,
                label: l10n.runningApp,
              ),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                l10n.selectedTargets(widget.selectedTargets),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        if (widget.isBuilding || widget.progress > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: widget.progress / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              _BuildStatusChip(
                icon: Icons.percent,
                label: l10n.overallProgressLabel(widget.progress),
              ),
              if (widget.isBuilding && remainingSeconds != null) ...[
                const SizedBox(width: 8),
                _BuildStatusChip(
                  icon: Icons.schedule_outlined,
                  label: l10n.buildRemainingTime(remainingSeconds),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBody(double width) {
    final steps = widget.roadmapSteps;
    BuildRoadmapStep? selectedStep;
    for (final step in steps) {
      if (step.id == _selectedStepId) {
        selectedStep = step;
      }
    }
    final configuration = widget.configuration;
    final commandPlan =
        configuration == null || configuration.projectPath.trim().isEmpty
        ? null
        : _BuildCommandPlan(configuration, steps);

    final plan = _BuildPlanPane(
      steps: steps,
      selectedStepId: _selectedStepId,
      onSelect: (stepId) => setState(() => _selectedStepId = stepId),
    );
    final console = _BuildConsole(
      steps: steps,
      selectedStep: selectedStep,
      commandPlan: commandPlan,
      log: widget.log,
    );

    if (width >= _sideBySideMinWidth) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: plan),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: console),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: plan),
        const SizedBox(height: 12),
        Expanded(flex: 3, child: console),
      ],
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

/// Shared frame of the two halves: a titled, bordered pane.
class _Pane extends StatelessWidget {
  const _Pane({required this.header, required this.child});

  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Divider(height: 1, color: colorScheme.outlineVariant),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _PaneHeader extends StatelessWidget {
  const _PaneHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _PaneMessage extends StatelessWidget {
  const _PaneMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _BuildPlanPane extends StatefulWidget {
  const _BuildPlanPane({
    required this.steps,
    required this.selectedStepId,
    required this.onSelect,
  });

  final List<BuildRoadmapStep> steps;
  final String? selectedStepId;
  final ValueChanged<String> onSelect;

  @override
  State<_BuildPlanPane> createState() => _BuildPlanPaneState();
}

class _BuildPlanPaneState extends State<_BuildPlanPane> {
  static const _minimumStepDisplayDuration = Duration(seconds: 1);
  static const _nextStepDelay = Duration(milliseconds: 180);

  late List<BuildRoadmapStep> _displayedSteps;
  late List<BuildRoadmapStep> _targetSteps;
  final _stepKeys = <String, GlobalKey>{};
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    _displayedSteps = List.of(widget.steps);
    _targetSteps = List.of(widget.steps);
  }

  @override
  void didUpdateWidget(_BuildPlanPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStepId != widget.selectedStepId) {
      _revealSelectedStep();
    }
    if (!_sameStepIds(_targetSteps, widget.steps)) {
      _transitionTimer?.cancel();
      _transitionTimer = null;
      _targetSteps = List.of(widget.steps);
      _displayedSteps = List.of(widget.steps);
      return;
    }

    _targetSteps = List.of(widget.steps);
    _advanceDisplayedSteps();
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    super.dispose();
  }

  void _revealSelectedStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stepContext = _stepKeys[widget.selectedStepId]?.currentContext;
      if (stepContext == null || !stepContext.mounted) {
        return;
      }
      Scrollable.ensureVisible(
        stepContext,
        alignment: 0.3,
        duration: const Duration(milliseconds: 200),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  /// Fast steps would flash by unnoticed, so each finished step is held in
  /// its running state for a moment before it switches to the final state.
  void _advanceDisplayedSteps() {
    if (_transitionTimer?.isActive ?? false) {
      return;
    }
    if (_stepsMatch(_displayedSteps, _targetSteps)) {
      return;
    }

    for (var index = 0; index < _displayedSteps.length; index++) {
      final displayed = _displayedSteps[index];
      final target = _targetSteps[index];
      if (_stepMatches(displayed, target)) {
        continue;
      }

      if (_shouldHoldBeforeFinalState(displayed, target)) {
        setState(() {
          _displayedSteps[index] = displayed.copyWith(
            state: BuildRoadmapStepState.running,
            progress: 100,
            detail: target.detail,
          );
        });
        _transitionTimer = Timer(_minimumStepDisplayDuration, () {
          if (!mounted) {
            return;
          }
          setState(() {
            _displayedSteps[index] = _targetSteps[index];
          });
          _transitionTimer = Timer(_nextStepDelay, () {
            _transitionTimer = null;
            if (mounted) {
              _advanceDisplayedSteps();
            }
          });
        });
        return;
      }

      setState(() {
        _displayedSteps[index] = target;
      });
      _advanceDisplayedSteps();
      return;
    }
  }

  bool _shouldHoldBeforeFinalState(
    BuildRoadmapStep displayed,
    BuildRoadmapStep target,
  ) {
    final targetIsFinal = switch (target.state) {
      BuildRoadmapStepState.success ||
      BuildRoadmapStepState.warning ||
      BuildRoadmapStepState.skipped => true,
      BuildRoadmapStepState.pending || BuildRoadmapStepState.running => false,
    };
    return targetIsFinal &&
        displayed.state != target.state &&
        displayed.state != BuildRoadmapStepState.skipped;
  }

  bool _sameStepIds(
    List<BuildRoadmapStep> first,
    List<BuildRoadmapStep> second,
  ) {
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index++) {
      if (first[index].id != second[index].id) {
        return false;
      }
    }
    return true;
  }

  bool _stepsMatch(
    List<BuildRoadmapStep> first,
    List<BuildRoadmapStep> second,
  ) {
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index++) {
      if (!_stepMatches(first[index], second[index])) {
        return false;
      }
    }
    return true;
  }

  bool _stepMatches(BuildRoadmapStep first, BuildRoadmapStep second) {
    return first.id == second.id &&
        first.state == second.state &&
        first.progress == second.progress &&
        first.detail == second.detail;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finished = _displayedSteps
        .where(
          (step) =>
              step.state == BuildRoadmapStepState.success ||
              step.state == BuildRoadmapStepState.skipped,
        )
        .length;

    return _Pane(
      header: _PaneHeader(
        icon: Icons.account_tree_outlined,
        title: l10n.buildPlanTitle,
        actions: [
          if (_displayedSteps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '$finished / ${_displayedSteps.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
      child: _displayedSteps.isEmpty
          ? _PaneMessage(l10n.noBuildPlan)
          : ListView(
              padding: const EdgeInsets.all(6),
              children: [
                for (final step in _displayedSteps)
                  _PlanStepTile(
                    key: _stepKeys.putIfAbsent(step.id, GlobalKey.new),
                    step: step,
                    selected: step.id == widget.selectedStepId,
                    onTap: () => widget.onSelect(step.id),
                  ),
              ],
            ),
    );
  }
}

class _PlanStepTile extends StatelessWidget {
  const _PlanStepTile({
    required this.step,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final BuildRoadmapStep step;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final running = step.state == BuildRoadmapStepState.running;
    final failed = step.state == BuildRoadmapStepState.warning;
    final detail = step.detail;
    final showDetail =
        (running || failed || selected) && detail != null && detail.isNotEmpty;

    return Semantics(
      selected: selected,
      label: l10n.roadmapStatusLabel(step.state.name),
      child: Material(
        color: selected
            ? colorScheme.surfaceContainerHighest
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StepIndicator(step: step),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.roadmapStepTitle(step.id, step.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: running || selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: step.state == BuildRoadmapStepState.pending
                              ? colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                    if (running)
                      Text(
                        '${step.progress}%',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
                if (running) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: LinearProgressIndicator(
                      value: step.progress.clamp(0, 100) / 100,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
                if (showDetail) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      l10n.roadmapDetail(detail),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: failed
                            ? context.status.problem
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final BuildRoadmapStep step;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indicator = switch (step.state) {
      BuildRoadmapStepState.pending => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outline, width: 1.5),
        ),
        child: Center(
          child: Text(
            step.number.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      BuildRoadmapStepState.running => Padding(
        padding: const EdgeInsets.all(2),
        child: CircularProgressIndicator(
          value: step.progress.clamp(0, 100) / 100,
          strokeWidth: 2.5,
          backgroundColor: colorScheme.outlineVariant,
        ),
      ),
      BuildRoadmapStepState.success => Icon(
        Icons.check_circle,
        size: 22,
        color: context.status.success,
      ),
      BuildRoadmapStepState.warning => Icon(
        Icons.error,
        size: 22,
        color: context.status.problem,
      ),
      BuildRoadmapStepState.skipped => Icon(
        Icons.remove_circle_outline,
        size: 22,
        color: colorScheme.outline,
      ),
    };
    return SizedBox.square(dimension: 22, child: indicator);
  }
}

class _BuildConsole extends StatefulWidget {
  const _BuildConsole({
    required this.steps,
    required this.selectedStep,
    required this.commandPlan,
    required this.log,
  });

  final List<BuildRoadmapStep> steps;
  final BuildRoadmapStep? selectedStep;

  /// Null until a project is selected, because commands need real paths.
  final _BuildCommandPlan? commandPlan;
  final List<BuildLogEntry> log;

  @override
  State<_BuildConsole> createState() => _BuildConsoleState();
}

class _BuildConsoleState extends State<_BuildConsole> {
  final _logController = ScrollController();

  @override
  void didUpdateWidget(_BuildConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    final logChanged =
        oldWidget.log.length != widget.log.length ||
        (widget.log.isNotEmpty &&
            !identical(oldWidget.log.last, widget.log.last));
    if (!logChanged) {
      return;
    }
    // Stick to the newest entry unless the user scrolled up to read history.
    final followTail =
        !_logController.hasClients ||
        _logController.position.pixels >=
            _logController.position.maxScrollExtent - 48;
    if (followTail) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logController.hasClients) {
          _logController.jumpTo(_logController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _logController.dispose();
    super.dispose();
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.copiedToClipboard)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final step = widget.selectedStep;
    final plan = widget.commandPlan;
    final commands = step == null || plan == null
        ? const <String>[]
        : plan.commandsFor(step.id);

    return _Pane(
      header: _PaneHeader(
        icon: Icons.terminal_outlined,
        title: step == null
            ? l10n.buildCommandsTitle
            : '${l10n.buildCommandsTitle} · ${l10n.roadmapStepTitle(step.id, step.title)}',
        subtitle: step == null
            ? null
            : _withUsualDuration(
                l10n,
                l10n.roadmapStepDescription(step.id, step.description),
                step.estimatedSeconds,
              ),
        actions: [
          if (step != null)
            Tooltip(
              message: l10n.roadmapStepExpandedDetail(step.id),
              constraints: const BoxConstraints(maxWidth: 420),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.info_outline, size: 18),
              ),
            ),
          IconButton(
            tooltip: l10n.copyStepCommands,
            onPressed: commands.isEmpty
                ? null
                : () => _copy(commands.join('\n')),
            icon: const Icon(Icons.copy_outlined, size: 18),
          ),
          TextButton.icon(
            onPressed: plan == null || widget.steps.isEmpty
                ? null
                : () => _copy(plan.script(widget.steps, l10n)),
            icon: const Icon(Icons.description_outlined, size: 18),
            label: Text(l10n.copyFullScript),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildCommands(context, step, plan)),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          _PaneHeader(
            icon: Icons.receipt_long_outlined,
            title: l10n.processLogTitle,
            actions: [
              IconButton(
                tooltip: l10n.copyLog,
                onPressed: widget.log.isEmpty
                    ? null
                    : () => _copy(
                        widget.log
                            .map((entry) => '${entry.title}\n${entry.detail}')
                            .join('\n\n'),
                      ),
                icon: const Icon(Icons.copy_outlined, size: 18),
              ),
            ],
          ),
          Expanded(
            flex: 2,
            // One selection area lets a whole error be selected and copied.
            child: SelectionArea(
              child: ListView.builder(
                controller: _logController,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                itemCount: widget.log.length,
                itemBuilder: (context, index) =>
                    _LogEntryTile(entry: widget.log[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommands(
    BuildContext context,
    BuildRoadmapStep? step,
    _BuildCommandPlan? plan,
  ) {
    final l10n = context.l10n;
    if (step == null) {
      return _PaneMessage(l10n.noBuildCommands);
    }
    if (plan == null) {
      return _PaneMessage(l10n.selectProjectForCommands);
    }
    final commands = plan.commandsFor(step.id);
    if (commands.isEmpty) {
      return _PaneMessage(l10n.noStepCommands);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final firstNumber = plan.firstNumberFor(step.id);
    return ListView.separated(
      // A new step starts at its first command instead of the old offset.
      key: PageStorageKey('commands:${step.id}'),
      padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
      itemCount: commands.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${firstNumber + index}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                color: colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              commands[index],
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.35,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _withUsualDuration(
    AppLocalizations l10n,
    String description,
    int? seconds,
  ) {
    if (seconds == null || seconds <= 0) {
      return description;
    }
    final usual = seconds < 60
        ? l10n.roadmapUsuallySeconds(seconds)
        : l10n.roadmapUsuallyMinutes((seconds / 60).round());
    return '$description · $usual';
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

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final BuildLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final warning = entry.state == BuildLogState.warning;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              _entryIcon(entry.state),
              color: _entryColor(context),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: warning ? context.status.problem : null,
                  ),
                ),
                if (entry.detail.isNotEmpty)
                  Text(
                    entry.detail,
                    // Errors stay readable in full; routine entries are kept
                    // short so the log does not crowd the commands.
                    maxLines: warning ? null : 3,
                    overflow: warning ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.35,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
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
      BuildLogState.running => Theme.of(context).colorScheme.onSurfaceVariant,
      BuildLogState.success => context.status.success,
      BuildLogState.warning => context.status.problem,
    };
  }
}

/// Shell commands equivalent to the build plan, with real project values, so
/// the build can be understood, reproduced or debugged by hand.
class _BuildCommandPlan {
  _BuildCommandPlan(this.configuration, List<BuildRoadmapStep> steps) {
    var nextNumber = 1;
    for (final step in steps) {
      final commands = _commandsForStep(
        step.id,
        configuration,
      ).map(_normalizeCommand).toList();
      _commands[step.id] = commands;
      _firstNumbers[step.id] = nextNumber;
      nextNumber += commands.length;
    }
  }

  final BuildConfiguration configuration;
  final _commands = <String, List<String>>{};
  final _firstNumbers = <String, int>{};

  List<String> commandsFor(String stepId) => _commands[stepId] ?? const [];

  int firstNumberFor(String stepId) => _firstNumbers[stepId] ?? 1;

  String script(List<BuildRoadmapStep> steps, AppLocalizations l10n) {
    final buffer = StringBuffer('#!/usr/bin/env bash\n');
    for (final step in steps) {
      final commands = commandsFor(step.id);
      if (commands.isEmpty) {
        continue;
      }
      buffer
        ..writeln()
        ..writeln(
          '# ${step.number}. ${l10n.roadmapStepTitle(step.id, step.title)}',
        );
      for (final command in commands) {
        buffer.writeln(command);
      }
    }
    return buffer.toString();
  }

  List<String> _commandsForStep(
    String stepId,
    BuildConfiguration configuration,
  ) {
    final project = configuration.projectPath;
    final output = configuration.outputPath?.trim().isNotEmpty == true
        ? configuration.outputPath!.trim()
        : '$project/build/pack_foundry';
    final appName = configuration.appName.trim().isEmpty
        ? 'Flutter App'
        : configuration.appName.trim();
    final packageName = _slugify(appName);
    final version = _releaseVersion(configuration.releaseTag);
    final icon = configuration.iconPath?.trim() ?? '';
    final maintainer = configuration.developerEmail.trim().isEmpty
        ? 'PackFoundry User <user@localhost>'
        : configuration.developerEmail.trim();
    final description = configuration.description.trim().isEmpty
        ? '$appName packaged with PackFoundry'
        : configuration.description.trim();
    final debDepends = _packageDependencies(
      configuration,
      type: 'deb',
      defaults: const ['libgtk-3-0', 'libstdc++6', 'liblzma5'],
    );
    final rpmRequires = _packageDependencies(
      configuration,
      type: 'rpm',
      defaults: const ['gtk3', 'libstdc++', 'xz-libs'],
    );
    final desktopId = 'dev.packfoundry.${packageName.replaceAll('-', '_')}';

    if (stepId == 'workspace') {
      final commands = <String>[
        r'mkdir -p "$WORKSPACE"',
        r'cp -a "$PROJECT/." "$WORKSPACE/"',
        r'rm -rf "$WORKSPACE/build" "$WORKSPACE/.dart_tool" "$WORKSPACE/.git"',
        r'''sed -Ei "s/set\\(APPLICATION_ID[[:space:]]+[^)]*\\)/set(APPLICATION_ID $DESKTOP_ID)/" "$WORKSPACE/linux/CMakeLists.txt"''',
      ];
      final width = configuration.windowWidth;
      final height = configuration.windowHeight;
      if (width != null && height != null && width > 0 && height > 0) {
        commands.add(
          '''sed -Ei 's/gtk_window_set_default_size\\([^;]+/gtk_window_set_default_size(window, $width, $height)/' "\$WORKSPACE/linux/runner/my_application.cc"''',
        );
      }
      if (icon.isNotEmpty) {
        final extension = icon.toLowerCase().endsWith('.svg') ? 'svg' : 'png';
        commands.addAll([
          r'mkdir -p "$WORKSPACE/.pack_foundry"',
          'cp "\$ICON" "\$WORKSPACE/.pack_foundry/icon.$extension"',
          'WORKSPACE_ICON=${_shellQuote('.pack_foundry/icon.$extension')}',
        ]);
      } else {
        commands.add("WORKSPACE_ICON=''");
      }
      commands.add(r'cd "$WORKSPACE"');
      return commands;
    }

    if (stepId == 'rpm') {
      return [
        r'RPM_TOP="$WORK_ROOT/rpmbuild"; RPM_ASSETS="$WORK_ROOT/rpm-assets"; RPM_SPEC="$RPM_TOP/SPECS/$PACKAGE_NAME.spec"',
        'RPM_REQUIRES=${_shellQuote(rpmRequires)}',
        r'mkdir -p "$RPM_TOP/SPECS" "$RPM_TOP/RPMS" "$RPM_ASSETS"',
        r'''cat > "$RPM_ASSETS/$DESKTOP_ID.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=/opt/$PACKAGE_NAME/$EXECUTABLE_NAME
Icon=$DESKTOP_ID
StartupWMClass=$PACKAGE_NAME
Categories=Utility;
Terminal=false
EOF''',
        r'''if [ -n "$ICON" ]; then
  case "$ICON" in
    *.svg|*.SVG) RPM_ICON="$RPM_ASSETS/$DESKTOP_ID.svg"; RPM_ICON_DEST="/usr/share/icons/hicolor/scalable/apps/$DESKTOP_ID.svg" ;;
    *) RPM_ICON="$RPM_ASSETS/$DESKTOP_ID.png"; RPM_ICON_DEST="/usr/share/icons/hicolor/256x256/apps/$DESKTOP_ID.png" ;;
  esac
  cp "$ICON" "$RPM_ICON"
else
  RPM_ICON="$RPM_ASSETS/$DESKTOP_ID.svg"
  RPM_ICON_DEST="/usr/share/icons/hicolor/scalable/apps/$DESKTOP_ID.svg"
  printf '%s
' '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><rect width="256" height="256" rx="48" fill="#0EA5A4"/></svg>' > "$RPM_ICON"
fi''',
        r'''cat > "$RPM_SPEC" <<EOF
%global __brp_check_rpaths %{nil}
Name: $PACKAGE_NAME
Version: $VERSION
Release: 1%{?dist}
Summary: $APP_NAME
License: GPL-2.0-only
Requires: $RPM_REQUIRES

%description
$APP_NAME packaged manually from the PackFoundry command plan.

%prep
%build
%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt/$PACKAGE_NAME
cp -a "$BUNDLE"/. %{buildroot}/opt/$PACKAGE_NAME/
chmod 755 %{buildroot}/opt/$PACKAGE_NAME/$EXECUTABLE_NAME
install -Dm0644 "$RPM_ASSETS/$DESKTOP_ID.desktop" %{buildroot}/usr/share/applications/$DESKTOP_ID.desktop
install -Dm0644 "$RPM_ICON" %{buildroot}$RPM_ICON_DEST

%files
/opt/$PACKAGE_NAME
/usr/share/applications/$DESKTOP_ID.desktop
/usr/share/icons/hicolor/*/apps/$DESKTOP_ID.*
EOF''',
        r'rpmbuild -bb --define "_topdir $RPM_TOP" "$RPM_SPEC"',
        r'RPM_FILE="$(find "$RPM_TOP/RPMS" -type f -name "*.rpm" | head -n 1)"',
        r'cp -f "$RPM_FILE" "$EXPORT/${APP_NAME}_linux_${VERSION}-1_${LINUX_ARTIFACT_ARCH}.rpm"',
      ];
    }

    if (stepId == 'appimage') {
      return const [
        r'APPDIR="$WORK_ROOT/$DESKTOP_ID.AppDir"; rm -rf "$APPDIR"; mkdir -p "$APPDIR/usr/bin"',
        r'cp -a "$BUNDLE/." "$APPDIR/usr/bin/"',
        r'''cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
EXECUTABLE="$(find "$HERE/usr/bin" -maxdepth 1 -type f -perm /111 ! -name '*.so' | head -n 1)"
exec "$EXECUTABLE" "$@"
EOF
chmod +x "$APPDIR/AppRun"''',
        r'''cat > "$APPDIR/$DESKTOP_ID.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=AppRun
Icon=$DESKTOP_ID
StartupWMClass=$PACKAGE_NAME
Categories=Utility;
Terminal=false
EOF''',
        r'''if [ -n "$ICON" ]; then
  case "$ICON" in
    *.svg|*.SVG) APPIMAGE_ICON="$APPDIR/$DESKTOP_ID.svg" ;;
    *) APPIMAGE_ICON="$APPDIR/$DESKTOP_ID.png" ;;
  esac
  cp "$ICON" "$APPIMAGE_ICON"
  cp "$ICON" "$APPDIR/.DirIcon"
else
  APPIMAGE_ICON="$APPDIR/$DESKTOP_ID.svg"
  printf '%s
' '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><rect width="256" height="256" rx="48" fill="#0EA5A4"/></svg>' > "$APPIMAGE_ICON"
  cp "$APPIMAGE_ICON" "$APPDIR/.DirIcon"
fi''',
        r'APPIMAGETOOL="$(command -v appimagetool || true)"',
        r'''if [ -z "$APPIMAGETOOL" ]; then
  APPIMAGE_ARCH="$(uname -m)"
  case "$APPIMAGE_ARCH" in
    x86_64|amd64) APPIMAGE_ARCH=x86_64 ;;
    aarch64|arm64) APPIMAGE_ARCH=aarch64 ;;
  esac
  APPIMAGETOOL="$WORK_ROOT/appimagetool-$APPIMAGE_ARCH.AppImage"
  curl -fL "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$APPIMAGE_ARCH.AppImage" -o "$APPIMAGETOOL"
  chmod +x "$APPIMAGETOOL"
fi''',
        r'ARCH="$(uname -m)" APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" "$APPDIR" "$EXPORT/${APP_NAME}_linux_${VERSION}_${LINUX_ARTIFACT_ARCH}.AppImage"',
        r'chmod +x "$EXPORT/${APP_NAME}_linux_${VERSION}_${LINUX_ARTIFACT_ARCH}.AppImage"',
      ];
    }

    if (stepId == 'deb-container') {
      return [
        'DEB_DEPENDS=${_shellQuote(debDepends)}',
        r'''DEB_BUILD_SCRIPT='set -euo pipefail
export PATH=/opt/flutter/bin:$PATH
cd /work
rm -rf build/linux
flutter pub get
flutter build linux --release
BUNDLE=$(find build/linux -type d -path "*/release/bundle" | head -n 1)
ARCH=$(dpkg --print-architecture)
ROOT=/tmp/packfoundry-package
rm -rf "$ROOT"
mkdir -p "$ROOT/DEBIAN" "$ROOT/opt/$PACKFOUNDRY_PACKAGE_NAME" "$ROOT/usr/share/applications" "$ROOT/usr/share/icons/hicolor/256x256/apps" "$ROOT/usr/share/icons/hicolor/scalable/apps"
cp -a "$BUNDLE/." "$ROOT/opt/$PACKFOUNDRY_PACKAGE_NAME/"
EXECUTABLE=$(find "$ROOT/opt/$PACKFOUNDRY_PACKAGE_NAME" -maxdepth 1 -type f -perm /111 ! -name "*.so" | head -n 1)
printf "Package: %s
Version: %s
Section: utils
Priority: optional
Architecture: %s
Maintainer: %s
Depends: %s
Description: %s
" "$PACKFOUNDRY_PACKAGE_NAME" "$PACKFOUNDRY_VERSION" "$ARCH" "$PACKFOUNDRY_MAINTAINER" "$PACKFOUNDRY_DEB_DEPENDS" "$PACKFOUNDRY_DESCRIPTION" > "$ROOT/DEBIAN/control"
printf "[Desktop Entry]
Type=Application
Name=%s
Exec=/opt/%s/%s
Icon=%s
StartupWMClass=%s
Categories=Utility;
Terminal=false
" "$PACKFOUNDRY_APP_NAME" "$PACKFOUNDRY_PACKAGE_NAME" "$(basename "$EXECUTABLE")" "$PACKFOUNDRY_DESKTOP_ID" "$PACKFOUNDRY_PACKAGE_NAME" > "$ROOT/usr/share/applications/$PACKFOUNDRY_DESKTOP_ID.desktop"
if [ -n "$PACKFOUNDRY_ICON_PATH" ] && [ -f "/work/$PACKFOUNDRY_ICON_PATH" ]; then
  case "$PACKFOUNDRY_ICON_PATH" in
    *.svg) cp "/work/$PACKFOUNDRY_ICON_PATH" "$ROOT/usr/share/icons/hicolor/scalable/apps/$PACKFOUNDRY_DESKTOP_ID.svg" ;;
    *) cp "/work/$PACKFOUNDRY_ICON_PATH" "$ROOT/usr/share/icons/hicolor/256x256/apps/$PACKFOUNDRY_DESKTOP_ID.png" ;;
  esac
fi
case "$ARCH" in
  amd64|x86_64) OUTPUT_ARCH=x64 ;;
  arm64|aarch64) OUTPUT_ARCH=arm64 ;;
  *) OUTPUT_ARCH="$ARCH" ;;
esac
dpkg-deb --build --root-owner-group "$ROOT" "/out/${PACKFOUNDRY_APP_NAME}_linux_${PACKFOUNDRY_VERSION}_${OUTPUT_ARCH}.deb"' ''',
        r'RUNTIME="$(command -v docker || command -v podman)"',
        r'"$RUNTIME" image inspect packfoundry/deb-builder:bookworm-flutter-stable-v1',
        r'''"$RUNTIME" run --rm -v "$WORKSPACE:/work" -v "$EXPORT:/out" -v packfoundry-pub-cache:/root/.pub-cache -e PACKFOUNDRY_APP_NAME="$APP_NAME" -e PACKFOUNDRY_PACKAGE_NAME="$PACKAGE_NAME" -e PACKFOUNDRY_DESKTOP_ID="$DESKTOP_ID" -e PACKFOUNDRY_VERSION="$VERSION" -e PACKFOUNDRY_MAINTAINER="$MAINTAINER" -e PACKFOUNDRY_DESCRIPTION="$DESCRIPTION" -e PACKFOUNDRY_DEB_DEPENDS="$DEB_DEPENDS" -e PACKFOUNDRY_ICON_PATH="$WORKSPACE_ICON" packfoundry/deb-builder:bookworm-flutter-stable-v1 bash -lc "$DEB_BUILD_SCRIPT"''',
      ];
    }

    if (stepId == 'deb-build') {
      return const [
        r'# Executed inside the DEB container: flutter pub get',
        r'# Executed inside the DEB container: flutter build linux --release',
      ];
    }

    if (stepId == 'deb-package') {
      return const [
        r'# Executed inside the DEB container: dpkg-deb --build --root-owner-group',
      ];
    }

    if (stepId == 'targz') {
      return const [
        r'tar -czf "$EXPORT/${APP_NAME}_linux_${VERSION}_${LINUX_ARTIFACT_ARCH}.tar.gz" -C "$(dirname "$BUNDLE")" "$(basename "$BUNDLE")"',
      ];
    }

    if (stepId == 'windows-kit') {
      return const [
        r'WINDOWS_KIT="$WORK_ROOT/${PACKAGE_NAME}_windows_build_kit"',
        r'mkdir -p "$WINDOWS_KIT/project" "$WINDOWS_KIT/scripts" "$WINDOWS_KIT/inno" "$WINDOWS_KIT/assets"',
        r'cp -a "$WORKSPACE/." "$WINDOWS_KIT/project/"',
        r'printf "%s" "$APP_NAME" > "$WINDOWS_KIT/app_name.txt"; printf "%s" "$PACKAGE_NAME" > "$WINDOWS_KIT/package_name.txt"; printf "%s" "$VERSION" > "$WINDOWS_KIT/version.txt"',
        r'''cat > "$WINDOWS_KIT/scripts/build_windows.ps1" <<'POWERSHELL'
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Project = Join-Path $Root 'project'
$Output = Join-Path $Root 'output'
$AppName = Get-Content (Join-Path $Root 'app_name.txt') -Raw
$PackageName = Get-Content (Join-Path $Root 'package_name.txt') -Raw
$AppVersion = Get-Content (Join-Path $Root 'version.txt') -Raw
New-Item -ItemType Directory -Force -Path $Output | Out-Null
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter SDK is not available in PATH.' }
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'winget is required to install missing Windows build tools.' }
winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --silent --accept-source-agreements --accept-package-agreements --override "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools;includeRecommended"
winget install --id JRSoftware.InnoSetup --exact --silent --accept-source-agreements --accept-package-agreements
Push-Location $Project
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }
  flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw 'flutter build windows failed.' }
} finally { Pop-Location }
$Release = Join-Path $Project 'build\windows\x64\runner\Release'
$Exe = Get-ChildItem $Release -Filter '*.exe' | Select-Object -First 1
if ($null -eq $Exe) { throw 'Windows executable was not found.' }
$Iscc = Get-ChildItem ${env:ProgramFiles(x86)},$env:ProgramFiles -Filter ISCC.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $Iscc) { throw 'Inno Setup compiler was not found.' }
& $Iscc.FullName "/DMyAppName=$AppName" "/DMyAppExeName=$($Exe.Name)" "/DMyPackageName=$PackageName" "/DMyAppVersion=$AppVersion" (Join-Path $Root 'inno\setup.iss')
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compilation failed.' }
POWERSHELL''',
        r'''cat > "$WINDOWS_KIT/inno/setup.iss" <<'INNO'
#ifndef MyAppName
#define MyAppName "Flutter App"
#endif
#ifndef MyAppExeName
#define MyAppExeName "app.exe"
#endif
#ifndef MyPackageName
#define MyPackageName "flutter-app"
#endif
#ifndef MyAppVersion
#define MyAppVersion "1.0.0"
#endif
[Setup]
AppId={{#MyPackageName}-packfoundry}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\{#MyAppName}
OutputDir=..\output
OutputBaseFilename={#MyPackageName}-setup
Compression=lzma
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
[Files]
Source: "..\project\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
INNO''',
        r'cd "$WORK_ROOT" && zip -qr "$EXPORT/${APP_NAME}_windows_${VERSION}_x64_build_kit.zip" "$(basename "$WINDOWS_KIT")"',
        r'# On Windows: powershell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1',
      ];
    }

    if (stepId == 'android-build') {
      return const [r'flutter pub get', r'flutter build apk --release'];
    }

    if (stepId == 'apk-export') {
      return const [
        r'APK="$(find "$WORKSPACE/build/app/outputs" -type f -name "*release*.apk" | head -n 1)"',
        r'test -f "$APK"',
        r'cp -f "$APK" "$EXPORT/${APP_NAME}_android_${VERSION}_universal.apk"',
      ];
    }

    if (stepId == 'summary') {
      return const [r'find "$EXPORT" -maxdepth 1 -type f -print'];
    }

    if (stepId == 'cleanup') {
      return const [r'rm -rf "$WORK_ROOT"'];
    }

    return switch (stepId) {
      'project' => [
        'set -euo pipefail',
        'PROJECT=${_shellQuote(project)}',
        'EXPORT=${_shellQuote(output)}',
        'APP_NAME=${_shellQuote(appName)}',
        'PACKAGE_NAME=${_shellQuote(packageName)}',
        'VERSION=${_shellQuote(version)}',
        'DESKTOP_ID=${_shellQuote(desktopId)}',
        'ICON=${_shellQuote(icon)}',
        'MAINTAINER=${_shellQuote(maintainer)}',
        'DESCRIPTION=${_shellQuote(description)}',
        r'''LINUX_ARCH_RAW="$(uname -m)"
case "$LINUX_ARCH_RAW" in
  x86_64|amd64) LINUX_ARTIFACT_ARCH=x64 ;;
  aarch64|arm64) LINUX_ARTIFACT_ARCH=arm64 ;;
  *) LINUX_ARTIFACT_ARCH="$LINUX_ARCH_RAW" ;;
esac''',
        r'WORK_ROOT="$(mktemp -d -t packfoundry-manual-XXXXXX)"',
        r'WORKSPACE="$WORK_ROOT/project"',
        r'test -f "$PROJECT/pubspec.yaml"',
        r'mkdir -p "$EXPORT"',
      ],
      'local-build' => const [
        r'flutter pub get',
        r'flutter build linux --release',
      ],
      'bundle' => const [
        r'BUNDLE="$(find "$WORKSPACE/build/linux" -type d -path "*/release/bundle" | head -n 1)"',
        r'test -n "$BUNDLE"',
        r'EXECUTABLE="$(find "$BUNDLE" -maxdepth 1 -type f -perm /111 ! -name "*.so" | head -n 1)"',
        r'test -n "$EXECUTABLE"',
        r'EXECUTABLE_NAME="$(basename "$EXECUTABLE")"',
      ],
      _ => const [],
    };
  }

  String _normalizeCommand(String command) {
    return command.replaceAll(r'\"', '"');
  }

  String _shellQuote(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }

  String _packageDependencies(
    BuildConfiguration configuration, {
    required String type,
    required List<String> defaults,
  }) {
    final seen = <String>{};
    final dependencies = <String>[];
    void add(String value) {
      final normalized = value.trim();
      if (normalized.isEmpty || !seen.add(normalized.toLowerCase())) {
        return;
      }
      dependencies.add(normalized);
    }

    for (final dependency in defaults) {
      add(dependency);
    }
    final extra = configuration.additionalDependencies[type] ?? '';
    final withoutFieldName = extra.replaceFirst(
      RegExp(r'^\s*(Depends|Requires)\s*:', caseSensitive: false),
      '',
    );
    for (final part
        in withoutFieldName.replaceAll('\r\n', '\n').split(RegExp(r'[\n,]'))) {
      add(part);
    }
    return dependencies.join(', ');
  }

  String _slugify(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'flutter-app' : slug;
  }

  String _releaseVersion(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '1.0.0';
    }
    if (trimmed.length > 1 &&
        (trimmed.startsWith('v') || trimmed.startsWith('V'))) {
      return trimmed.substring(1);
    }
    return trimmed;
  }
}
