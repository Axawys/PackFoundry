import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

typedef WelcomeCompleted = Future<void> Function({required bool hideWelcome});

class WelcomeDialog extends StatefulWidget {
  const WelcomeDialog({
    required this.initialThemeMode,
    required this.onThemeModeChanged,
    required this.onCompleted,
    super.key,
  });

  final ThemeMode initialThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final WelcomeCompleted onCompleted;

  @override
  State<WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<WelcomeDialog> {
  late ThemeMode _themeMode = widget.initialThemeMode;
  bool _hideWelcome = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.welcomeTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.welcomeIntro),
              const SizedBox(height: 16),
              _FeatureLine(
                icon: Icons.folder_open_outlined,
                text: l10n.welcomeFeatureProject,
              ),
              _FeatureLine(
                icon: Icons.construction_outlined,
                text: l10n.welcomeFeatureTools,
              ),
              _FeatureLine(
                icon: Icons.rocket_launch_outlined,
                text: l10n.welcomeFeatureBuild,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.themeChoice,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_outlined),
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {_themeMode},
                onSelectionChanged: _isSaving
                    ? null
                    : (selection) {
                        final themeMode = selection.single;
                        setState(() {
                          _themeMode = themeMode;
                        });
                        widget.onThemeModeChanged(themeMode);
                      },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _hideWelcome,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _hideWelcome = value ?? false;
                        });
                      },
                title: Text(l10n.dontShowAgain),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _isSaving ? null : _complete,
          child: Text(l10n.startUsing),
        ),
      ],
    );
  }

  Future<void> _complete() async {
    setState(() {
      _isSaving = true;
    });
    await widget.onCompleted(hideWelcome: _hideWelcome);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
