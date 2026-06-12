import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'section.dart';

class AppSettingsPanel extends StatelessWidget {
  const AppSettingsPanel({
    required this.widthController,
    required this.heightController,
    required this.releaseTagController,
    required this.developerEmailController,
    required this.publisherNameController,
    required this.homepageUrlController,
    required this.licenseController,
    required this.descriptionController,
    required this.iconPath,
    required this.onChooseIcon,
    super.key,
  });

  final TextEditingController widthController;
  final TextEditingController heightController;
  final TextEditingController releaseTagController;
  final TextEditingController developerEmailController;
  final TextEditingController publisherNameController;
  final TextEditingController homepageUrlController;
  final TextEditingController licenseController;
  final TextEditingController descriptionController;
  final String? iconPath;
  final VoidCallback onChooseIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Section(
      title: l10n.applicationSettings,
      icon: Icons.tune_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 150,
                child: TextField(
                  controller: widthController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.windowWidth),
                ),
              ),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.windowHeight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.releaseMetadata,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: releaseTagController,
                  decoration: InputDecoration(
                    labelText: l10n.releaseTag,
                    hintText: 'v1.0.0',
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: developerEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.developerEmail),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: publisherNameController,
                  decoration: InputDecoration(labelText: l10n.publisherName),
                ),
              ),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: homepageUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(labelText: l10n.homepageUrl),
                ),
              ),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: licenseController,
                  decoration: InputDecoration(labelText: l10n.license),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: TextField(
              controller: descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.packageDescription),
            ),
          ),
          const SizedBox(height: 16),
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
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(buttonIcon),
          label: Text(buttonLabel),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(path ?? placeholder, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
