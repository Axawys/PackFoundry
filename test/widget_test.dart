import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pack_foundry/core/models/build_log_entry.dart';
import 'package:pack_foundry/l10n/app_localizations.dart';
import 'package:pack_foundry/main.dart';
import 'package:pack_foundry/ui/widgets/build_panel.dart';

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
    expect(find.text('Toolchain'), findsOneWidget);
    await tester.ensureVisible(find.text('Preferences'));
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Interface theme'), findsOneWidget);

    await tester.tap(find.text('Build'));
    await tester.pump();
    expect(find.text('Package export'), findsOneWidget);
    expect(find.text('0 selected targets'), findsOneWidget);
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

  testWidgets('applies language selection immediately', (tester) async {
    await tester.pumpWidget(
      const PackFoundryApp(enableToolchainDiagnostics: false),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.ensureVisible(find.text('Interface language'));
    expect(find.text('Interface language'), findsOneWidget);

    await tester.ensureVisible(find.text('Russian'));
    await tester.tap(find.text('Russian'));
    await tester.pump();

    expect(find.text('Язык интерфейса'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
  });

  testWidgets('localizes build roadmap in Russian', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: BuildPanel(
              selectedTargets: 1,
              isBuilding: true,
              progress: 25,
              roadmapSteps: const [
                BuildRoadmapStep(
                  id: 'cleanup',
                  number: 1,
                  title: 'Cleanup',
                  description:
                      'Remove temporary workspaces. Docker builds may contain many generated files.',
                  state: BuildRoadmapStepState.running,
                  progress: 40,
                  estimatedSeconds: 180,
                  detail: 'Temporary files were removed.',
                ),
              ],
              log: const [],
              onBuild: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Очистка'), findsOneWidget);
    expect(
      find.text(
        'Удаление временных рабочих папок. Docker-сборки могут создавать много файлов.',
      ),
      findsOneWidget,
    );
    expect(find.text('Временные файлы удалены.'), findsOneWidget);
    expect(find.text('Обычно: ~3 мин'), findsWidgets);
  });

  testWidgets('shows estimated remaining build time', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BuildPanel(
              selectedTargets: 1,
              isBuilding: true,
              progress: 25,
              roadmapSteps: const [
                BuildRoadmapStep(
                  id: 'project',
                  number: 1,
                  title: 'Project',
                  description:
                      'Check pubspec.yaml, app metadata and export folder.',
                  state: BuildRoadmapStepState.success,
                  progress: 100,
                  estimatedSeconds: 10,
                ),
                BuildRoadmapStep(
                  id: 'local-build',
                  number: 2,
                  title: 'Flutter build',
                  description: 'Compile the Linux release bundle on the host.',
                  state: BuildRoadmapStepState.running,
                  progress: 50,
                  estimatedSeconds: 120,
                ),
                BuildRoadmapStep(
                  id: 'cleanup',
                  number: 3,
                  title: 'Cleanup',
                  description:
                      'Remove temporary workspaces. Docker builds may contain many generated files.',
                  state: BuildRoadmapStepState.pending,
                  progress: 0,
                  estimatedSeconds: 180,
                ),
              ],
              log: const [],
              onBuild: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Overall progress: 25%'), findsOneWidget);
    expect(find.text('Remaining: ~4 min'), findsOneWidget);
  });

  testWidgets('auto-expands the current running roadmap card', (tester) async {
    Widget buildPanel(List<BuildRoadmapStep> steps) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BuildPanel(
              selectedTargets: 1,
              isBuilding: true,
              progress: 25,
              roadmapSteps: steps,
              log: const [],
              onBuild: () {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      buildPanel(const [
        BuildRoadmapStep(
          id: 'local-build',
          number: 1,
          title: 'Flutter build',
          description: 'Compile the Linux release bundle on the host.',
          state: BuildRoadmapStepState.running,
          progress: 20,
          estimatedSeconds: 120,
        ),
        BuildRoadmapStep(
          id: 'cleanup',
          number: 2,
          title: 'Cleanup',
          description:
              'Remove temporary workspaces. Docker builds may contain many generated files.',
          state: BuildRoadmapStepState.pending,
          progress: 0,
          estimatedSeconds: 180,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('What happens'), findsOneWidget);
    expect(
      find.textContaining('The host runs flutter build linux --release'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      buildPanel(const [
        BuildRoadmapStep(
          id: 'local-build',
          number: 1,
          title: 'Flutter build',
          description: 'Compile the Linux release bundle on the host.',
          state: BuildRoadmapStepState.success,
          progress: 100,
          estimatedSeconds: 120,
        ),
        BuildRoadmapStep(
          id: 'cleanup',
          number: 2,
          title: 'Cleanup',
          description:
              'Remove temporary workspaces. Docker builds may contain many generated files.',
          state: BuildRoadmapStepState.running,
          progress: 30,
          estimatedSeconds: 180,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('What happens'), findsOneWidget);
    expect(
      find.textContaining('temporary project copy and packaging intermediates'),
      findsOneWidget,
    );
    expect(
      find.textContaining('The host runs flutter build linux --release'),
      findsNothing,
    );
  });

  testWidgets('expands one roadmap card at a time', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BuildPanel(
              selectedTargets: 1,
              isBuilding: true,
              progress: 25,
              roadmapSteps: const [
                BuildRoadmapStep(
                  id: 'cleanup',
                  number: 1,
                  title: 'Cleanup',
                  description:
                      'Remove temporary workspaces. Docker builds may contain many generated files.',
                  state: BuildRoadmapStepState.running,
                  progress: 40,
                  estimatedSeconds: 180,
                ),
                BuildRoadmapStep(
                  id: 'rpm',
                  number: 2,
                  title: 'RPM',
                  description: 'Generate spec metadata and run rpmbuild.',
                  state: BuildRoadmapStepState.pending,
                  progress: 0,
                  estimatedSeconds: 25,
                ),
              ],
              log: const [],
              onBuild: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('What happens'), findsOneWidget);
    expect(
      find.textContaining('temporary project copy and packaging intermediates'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cleanup'));
    await tester.pumpAndSettle();
    expect(find.text('What happens'), findsNothing);

    await tester.ensureVisible(find.text('RPM'));
    await tester.tap(find.text('RPM'));
    await tester.pumpAndSettle();
    expect(find.text('What happens'), findsOneWidget);
    expect(
      find.textContaining('rpmbuild tree, desktop file, icon, and spec file'),
      findsOneWidget,
    );
    expect(
      find.textContaining('temporary project copy and packaging intermediates'),
      findsNothing,
    );

    await tester.tap(find.text('RPM'));
    await tester.pumpAndSettle();
    expect(find.text('What happens'), findsNothing);
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
