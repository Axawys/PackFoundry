import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/services/app_preferences.dart';
import 'l10n/app_localizations.dart';
import 'ui/pages/pack_foundry_home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PackFoundryApp());
}

class PackFoundryApp extends StatefulWidget {
  const PackFoundryApp({super.key, this.enableToolchainDiagnostics = true});

  final bool enableToolchainDiagnostics;

  @override
  State<PackFoundryApp> createState() => _PackFoundryAppState();
}

class _PackFoundryAppState extends State<PackFoundryApp> {
  final _preferences = AppPreferences();
  ThemeMode _themeMode = ThemeMode.system;
  bool _showWelcome = false;
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _preferences.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = settings.themeMode;
      _showWelcome = settings.showWelcome;
      _settingsLoaded = true;
    });
  }

  Future<void> _setThemeMode(ThemeMode themeMode) async {
    setState(() {
      _themeMode = themeMode;
    });
    await _preferences.saveThemeMode(themeMode);
  }

  Future<void> _completeWelcome({required bool hideWelcome}) async {
    await _preferences.saveHideWelcome(hideWelcome);
    if (!mounted) {
      return;
    }

    setState(() {
      _showWelcome = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PackFoundry',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: PackFoundryHomePage(
        themeMode: _themeMode,
        showWelcome: _settingsLoaded && _showWelcome,
        onThemeModeChanged: _setThemeMode,
        onWelcomeCompleted: _completeWelcome,
        enableToolchainDiagnostics: widget.enableToolchainDiagnostics,
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0EA5A4),
        brightness: brightness,
      ),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
