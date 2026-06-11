import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'section.dart';

class AppSettingsPanel extends StatelessWidget {
  const AppSettingsPanel({
    required this.appNameController,
    required this.widthController,
    required this.heightController,
    required this.iconPath,
    required this.onChooseIcon,
    super.key,
  });

  final TextEditingController appNameController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final String? iconPath;
  final VoidCallback onChooseIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Section(
      title: l10n.applicationSettings,
      icon: Icons.tune_outlined,
      child: Column(
        children: [
          TextField(
            controller: appNameController,
            decoration: InputDecoration(labelText: l10n.applicationName),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widthController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.windowWidth),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.windowHeight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PathPickerRow(
            icon: Icons.image_outlined,
            path: iconPath,
            placeholder: l10n.noIconSelected,
            buttonIcon: Icons.upload_file_outlined,
            buttonLabel: l10n.icon,
            onPressed: onChooseIcon,
          ),
        ],
      ),
    );
  }
}

class _PathPickerRow extends StatelessWidget {
  const _PathPickerRow({
    required this.icon,
    required this.path,
    required this.placeholder,
    required this.buttonIcon,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String? path;
  final String placeholder;
  final IconData buttonIcon;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(path ?? placeholder, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(buttonIcon),
          label: Text(buttonLabel),
        ),
      ],
    );
  }
}
