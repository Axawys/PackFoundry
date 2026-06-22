import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pack_foundry/core/models/build_log_entry.dart';
import 'package:pack_foundry/core/models/build_target.dart';
import 'package:pack_foundry/core/models/build_configuration.dart';
import 'package:pack_foundry/core/models/project_config.dart';
import 'package:pack_foundry/core/services/build_service.dart';
import 'package:pack_foundry/core/services/project_config_service.dart';
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
    expect(find.text('0 selected targets'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Build installers'),
      findsOneWidget,
    );
  });

  test('creates a pending roadmap preview from selected targets', () {
    final targets = [
      BuildTarget(
        platform: 'Linux',
        artifact: 'AppImage',
        status: TargetStatus.ready,
        selected: true,
      ),
      BuildTarget(
        platform: 'Linux',
        artifact: 'deb package',
        status: TargetStatus.ready,
        selected: true,
      ),
      BuildTarget(
        platform: 'Linux',
        artifact: 'rpm package',
        status: TargetStatus.ready,
      ),
    ];

    final steps = BuildService().createRoadmapPlan(targets);

    expect(
      steps.map((step) => step.id),
      containsAll(<String>[
        'project',
        'workspace',
        'local-build',
        'bundle',
        'appimage',
        'deb-container',
        'deb-build',
        'deb-package',
        'summary',
        'cleanup',
      ]),
    );
    expect(steps.map((step) => step.id), isNot(contains('rpm')));
    expect(
      steps.every((step) => step.state == BuildRoadmapStepState.pending),
      isTrue,
    );
  });

  test('saves and loads PackFoundry project config', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'pack_foundry_config_test_',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final service = ProjectConfigService();
    final configPath = '${tempDir.path}/packfoundry.json';
    final config = ProjectConfig(
      projectPath: '.',
      outputPath: ProjectConfig.chooseInPackFoundry,
      iconPath: 'assets/icon.png',
      appName: 'HashChecker',
      releaseTag: 'v2.1.1',
      developerEmail: 'dev@example.com',
      publisherName: 'Example Studio',
      homepageUrl: 'https://example.com',
      license: 'GPL-2.0-only',
      description: 'Checks file hashes.',
      windowWidth: 1280,
      windowHeight: 800,
      packageTypes: const ['appimage', 'deb', 'rpm'],
    );

    await service.save(configPath, config);
    final loaded = await service.load(configPath);

    expect(loaded.projectPath, '${tempDir.path}/.');
    expect(loaded.choosesOutput, isTrue);
    expect(loaded.iconPath, '${tempDir.path}/assets/icon.png');
    expect(loaded.releaseTag, 'v2.1.1');
    expect(loaded.packageTypes, ['appimage', 'deb', 'rpm']);
  });

  testWidgets('shows roadmap before starting the selected build', (
    tester,
  ) async {
    await tester.pumpWidget(
      const PackFoundryApp(enableToolchainDiagnostics: false),
    );
    await tester.pump();
    await tester.pump();

    final appImageTarget = find.text('Linux AppImage');
    await tester.ensureVisible(appImageTarget);
    await tester.tap(appImageTarget);
    await tester.pump();

    await tester.tap(find.text('Build'));
    await tester.pump();

    expect(find.text('Full'), findsOneWidget);
    expect(find.text('Simplified'), findsOneWidget);
    expect(find.text('Create AppDir'), findsOneWidget);
    expect(find.text('Create AppRun'), findsOneWidget);
    expect(find.text('Resolve dependencies'), findsOneWidget);
    expect(find.text('Locate bundle'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.ensureVisible(find.text('Simplified'));
    await tester.tap(find.text('Simplified'));
    await tester.pump();

    expect(find.text('Create AppDir'), findsNothing);
    expect(find.text('Create AppRun'), findsNothing);
    expect(find.text('APPIMAGE'), findsOneWidget);
    expect(find.text('Flutter build'), findsOneWidget);

    await tester.ensureVisible(find.text('Commands'));
    await tester.tap(find.text('Commands'));
    await tester.pump();

    expect(
      find.text(
        'Select a Flutter project so PackFoundry can resolve real paths and names.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows executable commands with resolved build values', (
    tester,
  ) async {
    final target = BuildTarget(
      platform: 'Linux',
      artifact: 'AppImage',
      status: TargetStatus.ready,
      selected: true,
    );
    final steps = BuildService().createRoadmapPlan([target]);

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
              isBuilding: false,
              progress: 0,
              roadmapSteps: steps,
              log: const [],
              configuration: BuildConfiguration(
                appName: 'Hash Checker',
                releaseTag: 'v2.1.1',
                developerEmail: 'dev@example.com',
                publisherName: 'Example Studio',
                homepageUrl: 'https://example.com',
                license: 'GPL-2.0-only',
                description: 'Checks file hashes.',
                projectPath: '/home/user/Hash Checker',
                outputPath: '/home/user/Packages',
                iconPath: '/home/user/hashchecker.png',
                windowWidth: 1280,
                windowHeight: 800,
                targets: [target],
              ),
              onBuild: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Commands'));
    await tester.pump();

    expect(find.text("PROJECT='/home/user/Hash Checker'"), findsOneWidget);
    expect(find.text("EXPORT='/home/user/Packages'"), findsOneWidget);
    expect(find.text("APP_NAME='Hash Checker'"), findsOneWidget);
    expect(find.text("VERSION='2.1.1'"), findsOneWidget);
    expect(find.text('flutter build linux --release'), findsOneWidget);
    expect(find.textContaining('<project>'), findsNothing);
    expect(find.textContaining('<app>'), findsNothing);
    final commands = tester
        .widgetList<SelectableText>(find.byType(SelectableText))
        .map((widget) => widget.data ?? '')
        .toList();
    expect(commands.any((command) => command.contains(r'\"')), isFalse);
  });

  testWidgets('remembers release metadata fields', (tester) async {
    Finder field(String label) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
    }

    await tester.pumpWidget(
      const PackFoundryApp(enableToolchainDiagnostics: false),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(field('Release tag'), 'v2.3.0');
    await tester.enterText(field('Developer email'), 'dev@example.com');
    await tester.enterText(field('Developer / publisher'), 'Example Studio');
    await tester.enterText(field('Project homepage'), 'https://example.com');
    await tester.enterText(field('Package description'), 'Saved description');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('releaseTag'), 'v2.3.0');
    expect(preferences.getString('developerEmail'), 'dev@example.com');
    expect(preferences.getString('publisherName'), 'Example Studio');
    expect(preferences.getString('homepageUrl'), 'https://example.com');
    expect(preferences.getString('projectDescription'), 'Saved description');

    await tester.pumpWidget(
      PackFoundryApp(key: UniqueKey(), enableToolchainDiagnostics: false),
    );
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<TextField>(field('Release tag')).controller?.text,
      'v2.3.0',
    );
    expect(
      tester.widget<TextField>(field('Developer email')).controller?.text,
      'dev@example.com',
    );
    expect(
      tester.widget<TextField>(field('Developer / publisher')).controller?.text,
      'Example Studio',
    );
    expect(
      tester.widget<TextField>(field('Project homepage')).controller?.text,
      'https://example.com',
    );
    expect(
      tester.widget<TextField>(field('Package description')).controller?.text,
      'Saved description',
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

    expect(find.text('Подготовка очистки'), findsOneWidget);
    expect(find.text('Удаление workspace'), findsOneWidget);
    expect(find.text('Визуально'), findsOneWidget);
    expect(find.text('Команды'), findsOneWidget);
    expect(find.text('Полное'), findsOneWidget);
    expect(find.text('Упрощенное'), findsOneWidget);
    expect(
      find.text('Возвращаем владельца файлов после контейнерной сборки.'),
      findsOneWidget,
    );
    expect(find.text('Временные файлы удалены.'), findsOneWidget);
    expect(find.text('Обычно: ~2 мин'), findsWidgets);
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
      find.textContaining('PackFoundry tracks this technical action'),
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
      find.textContaining('PackFoundry tracks this technical action'),
      findsOneWidget,
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
      find.textContaining('PackFoundry tracks this technical action'),
      findsOneWidget,
    );

    await tester.tap(find.text('Prepare cleanup'));
    await tester.pumpAndSettle();
    expect(find.text('What happens'), findsNothing);

    await tester.ensureVisible(find.text('RPM tree'));
    await tester.tap(find.text('RPM tree'));
    await tester.pumpAndSettle();
    expect(find.text('What happens'), findsOneWidget);
    expect(
      find.textContaining('Create the rpmbuild directory structure'),
      findsOneWidget,
    );

    await tester.tap(find.text('RPM tree'));
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
    expect(
      find.widgetWithText(FilledButton, 'Собрать установщики'),
      findsOneWidget,
    );
  });
}
