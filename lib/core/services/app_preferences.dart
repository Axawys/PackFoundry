import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _themeModeKey = 'themeMode';
  static const _hideWelcomeKey = 'hideWelcome';

  Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return AppSettings(
      themeMode: _themeModeFromName(preferences.getString(_themeModeKey)),
      showWelcome: !(preferences.getBool(_hideWelcomeKey) ?? false),
    );
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, themeMode.name);
  }

  Future<void> saveHideWelcome(bool hideWelcome) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hideWelcomeKey, hideWelcome);
  }

  ThemeMode _themeModeFromName(String? name) {
    return switch (name) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

class AppSettings {
  const AppSettings({required this.themeMode, required this.showWelcome});

  final ThemeMode themeMode;
  final bool showWelcome;
}
