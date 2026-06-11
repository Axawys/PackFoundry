import 'package:flutter/material.dart';

import 'ui/pages/pack_foundry_home_page.dart';

void main() {
  runApp(const PackFoundryApp());
}

class PackFoundryApp extends StatelessWidget {
  const PackFoundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PackFoundry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const PackFoundryHomePage(),
    );
  }
}
