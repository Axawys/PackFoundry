import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/models/config_preset.dart';
import '../../l10n/app_localizations.dart';
import 'section.dart';

class ConfigPresetsPanel extends StatelessWidget {
  const ConfigPresetsPanel({
    required this.presets,
    required this.activePath,
    required this.isBusy,
    required this.isRunning,
    required this.canRun,
    required this.canSendToDevice,
    required this.isSendingToDevice,
    required this.sendToDeviceStatus,
    required this.onAddConfig,
    required this.onSaveCurrentConfig,
    required this.onApplyPreset,
    required this.onRemovePreset,
    required this.onRun,
    required this.onStop,
    required this.onSendToDevice,
    required this.onCancelSendToDevice,
    super.key,
  });

  final List<ConfigPreset> presets;
  final String? activePath;
  final bool isBusy;
  final bool isRunning;
  final bool canRun;

  /// Set when the APK target is selected: only then can anything be sent to an
  /// Android device.
  final bool canSendToDevice;
  final bool isSendingToDevice;

  /// Progress line for the send action, since its log lives on the Build tab.
  final String? sendToDeviceStatus;
  final VoidCallback onAddConfig;
  final VoidCallback onSaveCurrentConfig;
  final ValueChanged<ConfigPreset> onApplyPreset;
  final ValueChanged<ConfigPreset> onRemovePreset;
  final VoidCallback onRun;
  final VoidCallback onStop;
  final VoidCallback onSendToDevice;
  final VoidCallback onCancelSendToDevice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Section(
      title: l10n.configPresets,
      icon: Icons.bookmarks_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: isBusy ? null : onAddConfig,
                icon: const Icon(Icons.playlist_add_outlined),
                label: Text(l10n.addConfig),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onSaveCurrentConfig,
                icon: const Icon(Icons.save_alt_outlined),
                label: Text(l10n.saveCurrentConfig),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            presets.isEmpty ? l10n.noConfigPresets : l10n.configPresetsHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (presets.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final preset in presets)
                  _ConfigPresetCard(
                    preset: preset,
                    isActive: preset.path == activePath,
                    isBusy: isBusy,
                    onApply: () => onApplyPreset(preset),
                    onRemove: () => onRemovePreset(preset),
                  ),
              ],
            ),
          ],
          if (canRun || canSendToDevice) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (canRun)
                  OutlinedButton.icon(
                    onPressed: isBusy || isSendingToDevice
                        ? null
                        : (isRunning ? onStop : onRun),
                    icon: Icon(
                      isRunning
                          ? Icons.stop_circle_outlined
                          : Icons.play_arrow_outlined,
                    ),
                    label: Text(
                      isRunning ? l10n.stopRunningApp : l10n.runWithoutBuild,
                    ),
                  ),
                if (canSendToDevice)
                  Tooltip(
                    message: l10n.sendToDeviceHint,
                    child: OutlinedButton.icon(
                      onPressed: isBusy || isRunning
                          ? null
                          : (isSendingToDevice
                                ? onCancelSendToDevice
                                : onSendToDevice),
                      icon: Icon(
                        isSendingToDevice
                            ? Icons.stop_circle_outlined
                            : Icons.smartphone_outlined,
                      ),
                      label: Text(
                        isSendingToDevice
                            ? l10n.cancelSendToDevice
                            : l10n.sendToDevice,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (sendToDeviceStatus != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    sendToDeviceStatus!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfigPresetCard extends StatelessWidget {
  const _ConfigPresetCard({
    required this.preset,
    required this.isActive,
    required this.isBusy,
    required this.onApply,
    required this.onRemove,
  });

  final ConfigPreset preset;
  final bool isActive;
  final bool isBusy;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final subtitle = [
      if (isActive) l10n.activeConfig,
      if (preset.isBroken)
        l10n.configPresetBroken
      else if (preset.packageTypes.isNotEmpty)
        preset.packageTypes.join(', '),
    ].join(' · ');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Material(
        color: isActive ? colors.secondaryContainer : colors.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isBusy ? null : onApply,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? colors.primary : colors.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ConfigPresetIcon(preset: preset, isActive: isActive),
                const SizedBox(width: 10),
                Flexible(
                  child: Tooltip(
                    message: preset.path,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          preset.name,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isBusy ? null : onRemove,
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.removeConfigPreset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the application icon declared by the config. Configs without a usable
/// icon file fall back to a state icon, so every card keeps a leading glyph.
class _ConfigPresetIcon extends StatelessWidget {
  const _ConfigPresetIcon({required this.preset, required this.isActive});

  static const _size = 24.0;

  final ConfigPreset preset;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final iconPath = preset.isBroken ? null : preset.bitmapIconPath;
    if (iconPath == null) {
      return SizedBox(
        width: _size,
        height: _size,
        child: Center(child: _fallbackIcon(context)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.file(
        File(iconPath),
        width: _size,
        height: _size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: _size,
          height: _size,
          child: Center(child: _fallbackIcon(context)),
        ),
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Icon(
      preset.isBroken
          ? Icons.error_outline
          : isActive
          ? Icons.check_circle_outline
          : Icons.description_outlined,
      size: 20,
      color: preset.isBroken ? colors.error : colors.onSurfaceVariant,
    );
  }
}
