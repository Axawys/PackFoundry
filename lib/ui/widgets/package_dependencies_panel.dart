import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'section.dart';

class PackageDependenciesPanel extends StatelessWidget {
  const PackageDependenciesPanel({
    required this.debController,
    required this.rpmController,
    super.key,
  });

  final TextEditingController debController;
  final TextEditingController rpmController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Section(
      title: l10n.additionalPackageDependencies,
      icon: Icons.account_tree_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.additionalPackageDependenciesHelp,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _DependencyField(
                controller: debController,
                title: 'DEB Depends',
                hint: 'libgtk-3-0 | libgtk-3-0t64',
                helper: l10n.debAdditionalDependenciesHelp,
              ),
              _DependencyField(
                controller: rpmController,
                title: 'RPM Requires',
                hint: 'webkit2gtk4.1',
                helper: l10n.rpmAdditionalDependenciesHelp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DependencyField extends StatelessWidget {
  const _DependencyField({
    required this.controller,
    required this.title,
    required this.hint,
    required this.helper,
  });

  final TextEditingController controller;
  final String title;
  final String hint;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 330,
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: title,
          hintText: hint,
          helperText: helper,
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}
