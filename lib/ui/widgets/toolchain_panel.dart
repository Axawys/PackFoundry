import 'package:flutter/material.dart';

import '../../core/models/tool_status.dart';
import '../../l10n/app_localizations.dart';
import 'section.dart';
import 'status_chip.dart';

class ToolchainPanel extends StatelessWidget {
  const ToolchainPanel({required this.tools, super.key});

  final List<ToolStatus> tools;

  @override
  Widget build(BuildContext context) {
    return Section(
      title: context.l10n.toolchain,
      icon: Icons.construction_outlined,
      child: Column(
        children: [
          for (final tool in tools) ...[
            _ToolRow(tool: tool),
            if (tool != tools.last) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.tool});

  final ToolStatus tool;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_toolIcon(tool.status), color: _toolColor(context, tool.status)),
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
        const SizedBox(width: 12),
        StatusChip(
          label: l10n.toolAvailabilityLabel(tool.status.name),
          tone: tool.chipTone,
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

  Color _toolColor(BuildContext context, ToolAvailability status) {
    return switch (status) {
      ToolAvailability.installed => const Color(0xFF16A34A),
      ToolAvailability.available => Theme.of(context).colorScheme.primary,
      ToolAvailability.missing => const Color(0xFFF59E0B),
    };
  }
}
