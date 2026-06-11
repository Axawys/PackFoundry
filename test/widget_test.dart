import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pack_foundry/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'hideWelcome': true});
  });

  testWidgets('shows PackFoundry workspaces', (tester) async {
    await tester.pumpWidget(
      const PackFoundryApp(enableToolchainDiagnostics: false),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('PackFoundry'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Project'), findsWidgets);
    expect(find.text('Build'), findsOneWidget);
    expect(find.text('Application settings'), findsOneWidget);
    expect(find.text('Installers'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Interface theme'), findsOneWidget);
    expect(find.text('Toolchain'), findsOneWidget);

    await tester.tap(find.text('Build'));
    await tester.pump();
    expect(find.text('Package export'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Build installers'),
      findsOneWidget,
    );
  });

  testWidgets('shows welcome dialog by default', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const PackFoundryApp(enableToolchainDiagnostics: false),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Welcome to PackFoundry'), findsOneWidget);
    expect(find.text('Interface theme'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Do not show again'), findsOneWidget);
  });

  testWidgets('applies welcome theme selection immediately', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const PackFoundryApp(enableToolchainDiagnostics: false),
    );
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('uses Russian system locale when available', (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      const PackFoundryApp(enableToolchainDiagnostics: false),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Проект'), findsWidgets);
    expect(find.text('Сборка'), findsOneWidget);
    expect(find.text('Настройки приложения'), findsOneWidget);
    expect(find.text('Установщики'), findsOneWidget);

    await tester.tap(find.text('Сборка'));
    await tester.pump();
    expect(find.text('Экспорт пакетов'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Собрать установщики'),
      findsOneWidget,
    );
  });
}
