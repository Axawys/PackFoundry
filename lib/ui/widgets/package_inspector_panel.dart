import 'package:flutter/material.dart';

import '../../core/models/package_inspection.dart';
import '../../l10n/app_localizations.dart';
import 'section.dart';

class PackageInspectorPanel extends StatelessWidget {
  const PackageInspectorPanel({
    required this.inspection,
    required this.metadataController,
    required this.dependenciesController,
    required this.isBusy,
    required this.onChoosePackage,
    required this.onSaveEditedPackage,
    super.key,
  });

  final PackageInspection? inspection;
  final TextEditingController metadataController;
  final TextEditingController dependenciesController;
  final bool isBusy;
  final VoidCallback onChoosePackage;
  final VoidCallback onSaveEditedPackage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inspection = this.inspection;

    return Section(
      title: l10n.packageInspector,
      icon: Icons.inventory_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: isBusy ? null : onChoosePackage,
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(l10n.choosePackage),
            ),
          ),
          const SizedBox(height: 14),
          if (isBusy) const LinearProgressIndicator(),
          if (inspection == null && !isBusy)
            Text(
              l10n.noPackageSelected,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else if (inspection != null) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DataChip(label: l10n.packageFormat, value: inspection.format),
                _DataChip(
                  label: l10n.packageFileName,
                  value: inspection.fileName,
                ),
                _DataChip(
                  label: l10n.packageSize,
                  value: _formatBytes(inspection.sizeBytes),
                ),
                _DataChip(
                  label: l10n.packageEditMode,
                  value: inspection.saveSupported
                      ? l10n.packageEditable
                      : l10n.packageReadonly,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PathBox(label: l10n.packagePath, value: inspection.path),
            if (inspection.note != null) ...[
              const SizedBox(height: 12),
              _NoteBox(text: inspection.note!),
            ],
            const SizedBox(height: 14),
            _Editor(
              controller: metadataController,
              enabled: inspection.editable,
              label: l10n.packageMetadata,
              helper: inspection.editable
                  ? l10n.packageMetadataHelp
                  : l10n.packageReadonlyHelp,
              minLines: 6,
            ),
            const SizedBox(height: 12),
            _Editor(
              controller: dependenciesController,
              enabled: inspection.editable,
              label: l10n.packageDependencies,
              helper: inspection.editable
                  ? l10n.packageDependenciesHelp
                  : l10n.packageReadonlyHelp,
              minLines: 4,
            ),
            if (inspection.saveSupported) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onSaveEditedPackage,
                  icon: const Icon(Icons.save_as_outlined),
                  label: Text(l10n.saveEditedPackage),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kib = bytes / 1024;
    if (kib < 1024) {
      return '${kib.toStringAsFixed(1)} KiB';
    }
    final mib = kib / 1024;
    if (mib < 1024) {
      return '${mib.toStringAsFixed(1)} MiB';
    }
    return '${(mib / 1024).toStringAsFixed(1)} GiB';
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.helper,
    required this.minLines,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String helper;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: TextField(
        controller: controller,
        enabled: enabled,
        minLines: minLines,
        maxLines: minLines + 5,
        style: const TextStyle(fontFamily: 'monospace'),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({required this.label, required this.value});

  final String label;
  final String value;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PathBox extends StatelessWidget {
  const _PathBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(value),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(padding: const EdgeInsets.all(10), child: Text(text)),
      ),
    );
  }
}
