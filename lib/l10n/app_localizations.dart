import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ru')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get _isRu => locale.languageCode == 'ru';

  String get appTitle => 'PackFoundry';
  String get settings => _isRu ? 'Настройки' : 'Settings';
  String get softwareTools => _isRu ? 'Инструменты сборки' : 'Build tools';
  String get buildOutput => _isRu ? 'Экспорт пакетов' : 'Package export';
  String get chooseExportFolder =>
      _isRu ? 'Выбрать папку экспорта' : 'Choose export folder';
  String get installTools => _isRu ? 'Установить инструменты' : 'Install tools';
  String get welcomeTitle =>
      _isRu ? 'Добро пожаловать в PackFoundry' : 'Welcome to PackFoundry';
  String get welcomeIntro => _isRu
      ? 'PackFoundry помогает собрать Flutter-проект и подготовить установщики без ручной рутины.'
      : 'PackFoundry helps build Flutter projects and prepare installers without repetitive release chores.';
  String get welcomeFeatureProject => _isRu
      ? 'Выберите папку Flutter-проекта, и приложение проверит доступные цели сборки.'
      : 'Choose a Flutter project folder and the app will check available build targets.';
  String get welcomeFeatureTools => _isRu
      ? 'Следите за SDK, Docker, Android SDK и другими инструментами в одном окне.'
      : 'Track Flutter SDK, Docker, Android SDK and other tools in one workspace.';
  String get welcomeFeatureBuild => _isRu
      ? 'Запускайте сборку, смотрите прогресс, логи и понятные сообщения об ошибках.'
      : 'Run builds with visible progress, logs and clear failure messages.';
  String get themeChoice => _isRu ? 'Тема интерфейса' : 'Interface theme';
  String get themeSystem => _isRu ? 'Системная' : 'System';
  String get themeLight => _isRu ? 'Светлая' : 'Light';
  String get themeDark => _isRu ? 'Тёмная' : 'Dark';
  String get dontShowAgain =>
      _isRu ? 'Больше не показывать' : 'Do not show again';
  String get startUsing => _isRu ? 'Начать' : 'Start';
  String get readyTitle => _isRu ? 'Готово' : 'Ready';
  String get readyDetail => _isRu
      ? 'Выберите проект и нужные установщики, чтобы начать.'
      : 'Choose a project and select target installers to begin.';
  String get projectNotSelectedTitle =>
      _isRu ? 'Проект не выбран' : 'Project is not selected';
  String get projectNotSelectedDetail => _isRu
      ? 'Выберите папку Flutter-проекта перед сборкой установщиков.'
      : 'Choose a Flutter project folder before building installers.';

  String get project => _isRu ? 'Проект' : 'Project';
  String get noProjectSelected =>
      _isRu ? 'Проект не выбран' : 'No project selected';
  String get chooseFolder => _isRu ? 'Выбрать папку' : 'Choose folder';
  String get chooseProject => _isRu ? 'Выбрать проект' : 'Choose project';
  String get chooseOutput => _isRu ? 'Выбрать папку экспорта' : 'Choose output';
  String get iconTypeGroup => _isRu ? 'Иконки приложения' : 'Application icons';
  String get chooseIcon => _isRu ? 'Выбрать иконку' : 'Choose icon';
  String get pubspecYaml => 'pubspec.yaml';
  String get desktopEnabled => _isRu ? 'desktop включён' : 'desktop enabled';
  String get releaseSigningUnknown =>
      _isRu ? 'подпись релиза не настроена' : 'release signing unknown';

  String get applicationSettings =>
      _isRu ? 'Настройки приложения' : 'Application settings';
  String get applicationName =>
      _isRu ? 'Название приложения' : 'Application name';
  String get windowWidth => _isRu ? 'Ширина окна' : 'Window width';
  String get windowHeight => _isRu ? 'Высота окна' : 'Window height';
  String get noIconSelected => _isRu ? 'Иконка не выбрана' : 'No icon selected';
  String get icon => _isRu ? 'Иконка' : 'Icon';
  String get defaultOutput => _isRu
      ? 'По умолчанию: build/pack_foundry'
      : 'Default: build/pack_foundry';
  String get outputFolder => _isRu ? 'Папка экспорта' : 'Output folder';

  String get flutterSdkNote => _isRu
      ? 'Нужен для сборки под любую платформу.'
      : 'Required for every build target.';
  String get linuxToolchainNote => _isRu
      ? 'Собирает AppImage, deb, rpm и tar.gz на Linux-хостах.'
      : 'Builds AppImage, deb, rpm and tar.gz on Linux hosts.';
  String get dockerNote => _isRu
      ? 'Добавляет воспроизводимые сборочные окружения и изоляцию.'
      : 'Adds repeatable package builders and isolated build images.';
  String get innoSetupNote => _isRu
      ? 'Может использоваться для Windows .exe установщиков через Wine.'
      : 'Can be installed for Windows .exe installers through Wine.';
  String get androidSdkNote => _isRu
      ? 'Включает сборку APK и AAB артефактов.'
      : 'Enables APK and AAB release artifacts.';

  String get installers => _isRu ? 'Установщики' : 'Installers';
  String get toolchain => _isRu ? 'Инструменты' : 'Toolchain';
  String get build => _isRu ? 'Сборка' : 'Build';
  String selectedTargets(int count) {
    if (!_isRu) {
      return '$count selected target${count == 1 ? '' : 's'}';
    }
    return 'Выбрано целей: $count';
  }

  String get building => _isRu ? 'Сборка...' : 'Building...';
  String get buildInstallers =>
      _isRu ? 'Собрать установщики' : 'Build installers';

  String toolAvailabilityLabel(String statusName) {
    return switch (statusName) {
      'installed' => _isRu ? 'Установлено' : 'Installed',
      'available' => _isRu ? 'Можно установить' : 'Installable',
      'missing' => _isRu ? 'Отсутствует' : 'Missing',
      _ => statusName,
    };
  }

  String targetStatusLabel(String statusName) {
    return switch (statusName) {
      'ready' =>
        _isRu
            ? 'Готово к сборке на этом компьютере'
            : 'Ready to build on this machine',
      'installable' =>
        _isRu
            ? 'Нужны дополнительные инструменты'
            : 'Install extra tools to enable',
      'blocked' =>
        _isRu
            ? 'Заблокировано до установки SDK/toolchain'
            : 'Blocked until SDK/toolchain is installed',
      'hostLimited' =>
        _isRu
            ? 'Нужен нативный хост или удалённый сборщик'
            : 'Requires native host or remote builder',
      _ => statusName,
    };
  }

  String targetTitle(String platform, String artifact) {
    if (!_isRu) {
      return '$platform $artifact';
    }
    final translatedArtifact = switch (artifact) {
      'deb package' => 'deb пакет',
      'rpm package' => 'rpm пакет',
      'tar.gz bundle' => 'tar.gz архив',
      'Inno Setup exe' => 'Inno Setup exe',
      _ => artifact,
    };
    return '$platform $translatedArtifact';
  }
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
