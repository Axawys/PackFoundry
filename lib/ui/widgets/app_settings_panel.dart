import 'package:flutter/material.dart';

import 'section.dart';

class AppSettingsPanel extends StatelessWidget {
  const AppSettingsPanel({
    required this.appNameController,
    required this.widthController,
    required this.heightController,
    required this.iconPath,
    required this.outputPath,
    required this.onChooseIcon,
    required this.onChooseOutput,
    super.key,
  });

  final TextEditingController appNameController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final String? iconPath;
  final String? outputPath;
  final VoidCallback onChooseIcon;
  final VoidCallback onChooseOutput;

  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'Application settings',
      icon: Icons.tune_outlined,
      child: Column(
        children: [
          TextField(
            controller: appNameController,
            decoration: const InputDecoration(labelText: 'Application name'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widthController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Window width'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Window height'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PathPickerRow(
            icon: Icons.image_outlined,
            path: iconPath,
            placeholder: 'No icon selected',
            buttonIcon: Icons.upload_file_outlined,
            buttonLabel: 'Icon',
            onPressed: onChooseIcon,
          ),
          const SizedBox(height: 12),
          _PathPickerRow(
            icon: Icons.drive_folder_upload_outlined,
            path: outputPath,
            placeholder: 'Default: build/pack_foundry',
            buttonIcon: Icons.folder_special_outlined,
            buttonLabel: 'Output folder',
            onPressed: onChooseOutput,
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
