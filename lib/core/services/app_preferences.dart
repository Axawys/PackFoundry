import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _themeModeKey = 'themeMode';
  static const _localeModeKey = 'localeMode';
  static const _hideWelcomeKey = 'hideWelcome';
  static const _releaseTagKey = 'releaseTag';
  static const _developerEmailKey = 'developerEmail';
  static const _publisherNameKey = 'publisherName';
  static const _homepageUrlKey = 'homepageUrl';
  static const _projectDescriptionKey = 'projectDescription';

  Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return AppSettings(
      themeMode: _themeModeFromName(preferences.getString(_themeModeKey)),
      localeMode: _localeModeFromName(preferences.getString(_localeModeKey)),
      showWelcome: !(preferences.getBool(_hideWelcomeKey) ?? false),
    );
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, themeMode.name);
  }

  Future<void> saveLocaleMode(AppLocaleMode localeMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeModeKey, localeMode.name);
  }

  Future<void> saveHideWelcome(bool hideWelcome) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hideWelcomeKey, hideWelcome);
  }

  Future<SavedReleaseMetadata> loadReleaseMetadata() async {
    final preferences = await SharedPreferences.getInstance();
    return SavedReleaseMetadata(
      releaseTag: preferences.getString(_releaseTagKey) ?? '',
      developerEmail: preferences.getString(_developerEmailKey) ?? '',
      publisherName: preferences.getString(_publisherNameKey) ?? '',
      homepageUrl: preferences.getString(_homepageUrlKey) ?? '',
      description: preferences.getString(_projectDescriptionKey) ?? '',
    );
  }

  Future<void> saveReleaseMetadata(SavedReleaseMetadata metadata) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_releaseTagKey, metadata.releaseTag),
      preferences.setString(_developerEmailKey, metadata.developerEmail),
      preferences.setString(_publisherNameKey, metadata.publisherName),
      preferences.setString(_homepageUrlKey, metadata.homepageUrl),
      preferences.setString(_projectDescriptionKey, metadata.description),
    ]);
  }

  ThemeMode _themeModeFromName(String? name) {
    return switch (name) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  AppLocaleMode _localeModeFromName(String? name) {
    return switch (name) {
      'english' => AppLocaleMode.english,
      'russian' => AppLocaleMode.russian,
      _ => AppLocaleMode.system,
    };
  }
}

enum AppLocaleMode {
  system,
  english,
  russian;

  Locale? get locale {
    return switch (this) {
      AppLocaleMode.system => null,
      AppLocaleMode.english => const Locale('en'),
      AppLocaleMode.russian => const Locale('ru'),
    };
  }
}

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.localeMode,
    required this.showWelcome,
  });

  final ThemeMode themeMode;
  final AppLocaleMode localeMode;
  final bool showWelcome;
}

class SavedReleaseMetadata {
  const SavedReleaseMetadata({
    required this.releaseTag,
    required this.developerEmail,
    required this.publisherName,
    required this.homepageUrl,
    required this.description,
  });

  final String releaseTag;
  final String developerEmail;
  final String publisherName;
  final String homepageUrl;
  final String description;
}
