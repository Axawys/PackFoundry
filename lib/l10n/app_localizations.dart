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

  String get debBuildGroupTitle => 'DEB';
  String get rpmBuildGroupTitle => 'RPM';
  String get appImageBuildGroupTitle => 'APPIMAGE';
  String get windowsBuildGroupTitle => 'EXE';
  String get installMissingTools =>
      _isRu ? 'Установить недостающие инструменты' : 'Install missing tools';
  String get installingTools => _isRu ? 'Установка...' : 'Installing...';
  String toolInstallSuccess(String detail) {
    return _isRu
        ? 'Инструменты установлены. $detail'
        : 'Tools installed. $detail';
  }

  String toolInstallFailed(String detail) {
    return _isRu
        ? 'Не удалось установить инструменты. $detail'
        : 'Could not install tools. $detail';
  }

  String get exeInstallUnsupported => _isRu
      ? 'EXE-сборка требует Windows build host или будущий remote builder.'
      : 'EXE builds require a Windows build host or a future remote builder.';
  String get rpmHostInstallUnsupported => _isRu
      ? 'Host rpm-сборка для этой rpm-based системы пока отключена из-за несовместимости с Fedora/RHEL пакетами.'
      : 'Host rpm builds for this rpm-based system are disabled until Fedora/RHEL package compatibility is handled.';

  String debBuildNativeSubtitle(String distribution) {
    return _isRu
        ? 'Нативная deb-сборка для $distribution.'
        : 'Native deb packaging for $distribution.';
  }

  String debBuildDockerSubtitle(String distribution) {
    return _isRu
        ? 'Deb-сборка через Debian Docker builder на $distribution.'
        : 'Deb packaging through the Debian Docker builder on $distribution.';
  }

  String rpmBuildNativeSubtitle(String distribution) {
    return _isRu
        ? 'Нативная rpm-сборка для $distribution/Fedora-like окружения.'
        : 'Native rpm packaging for $distribution/Fedora-like environments.';
  }

  String rpmBuildDockerSubtitle(String distribution) {
    return _isRu
        ? 'Будущая rpm-сборка через Fedora Docker builder на $distribution.'
        : 'Future rpm packaging through the Fedora Docker builder on $distribution.';
  }

  String rpmBuildUnsupportedSubtitle(String distribution) {
    return _isRu
        ? '$distribution использует rpm, но пакеты Fedora/RHEL для неё пока не считаются совместимыми.'
        : '$distribution uses rpm, but Fedora/RHEL packages are not treated as compatible yet.';
  }

  String get appImageBuildGroupSubtitle => _isRu
      ? 'Сборка переносимого AppImage для Linux.'
      : 'Build a portable AppImage for Linux.';
  String get windowsBuildGroupSubtitle => _isRu
      ? 'Сборка EXE требует Windows build host или будущий remote builder.'
      : 'EXE builds require a Windows build host or a future remote builder.';
  String get hostSystemToolName => _isRu ? 'Система хоста' : 'Host system';
  String get hostSystemToolNote => _isRu
      ? 'Определяет, какие пакеты можно собрать нативно без контейнера.'
      : 'Defines which packages can be built natively without a container.';
  String get hostRpmCompatibilityToolName =>
      _isRu ? 'Совместимость rpm' : 'RPM compatibility';
  String get hostRpmCompatibilityToolNote => _isRu
      ? 'Host rpm-сборка пока доступна только для Fedora/RHEL-like систем.'
      : 'Host rpm builds are currently enabled only for Fedora/RHEL-like systems.';

  String get flutterSdkNote => _isRu
      ? 'Нужен для сборки под любую платформу.'
      : 'Required for every build target.';
  String get linuxToolchainNote => _isRu
      ? 'Собирает Linux-пакеты на Linux-хостах.'
      : 'Builds Linux packages on Linux hosts.';
  String get hostLinuxToolchainNote => _isRu
      ? 'Нужен для нативной сборки Linux bundle, AppImage и tar.gz.'
      : 'Required for native Linux bundle, AppImage and tar.gz builds.';
  String get appImageToolNote => _isRu
      ? 'Упаковывает AppImage. Если отсутствует, PackFoundry может скачать его в кеш.'
      : 'Packages AppImage. If missing, PackFoundry can download it to the cache.';
  String get dockerNote => _isRu
      ? 'Нужен для сборки пакетов в контейнерах, например deb на Fedora.'
      : 'Required for container builds, such as deb packaging on Fedora.';
  String get dockerDebNote => _isRu
      ? 'Нужен для deb-сборки на не-Debian системах.'
      : 'Required for deb packaging on non-Debian systems.';
  String get dockerRpmNote => _isRu
      ? 'Будет нужен для rpm-сборки вне Fedora/RHEL-like систем.'
      : 'Will be required for rpm packaging outside Fedora/RHEL-like systems.';
  String get debianBuilderNote => _isRu
      ? 'Образ скачивается Docker автоматически при первой deb-сборке.'
      : 'Docker downloads this image automatically on the first deb build.';
  String get rpmBuilderNote => _isRu
      ? 'Будущий контейнер для сборки rpm вне Fedora/RHEL окружения.'
      : 'Future container builder for rpm outside Fedora/RHEL environments.';
  String get dpkgDebNote => _isRu
      ? 'Создаёт deb-пакет на Debian/Ubuntu-like хостах.'
      : 'Creates deb packages on Debian/Ubuntu-like hosts.';
  String get rpmBuildToolNote => _isRu
      ? 'Создаёт rpm-пакет на Fedora/RHEL-like хостах.'
      : 'Creates rpm packages on Fedora/RHEL-like hosts.';
  String get windowsBuildHostNote => _isRu
      ? 'Flutter Windows build требует Windows toolchain; Wine сам по себе этого не заменяет.'
      : 'Flutter Windows builds require the Windows toolchain; Wine alone does not replace it.';
  String get wineNote => _isRu
      ? 'Может пригодиться для запуска упаковщика, но не заменяет Windows build host.'
      : 'May help run a packager, but does not replace a Windows build host.';
  String get innoSetupNote => _isRu
      ? 'Упаковывает уже собранное Windows-приложение в установщик.'
      : 'Packages an already-built Windows app into an installer.';
  String get androidSdkNote => _isRu
      ? 'Включает сборку APK и AAB артефактов.'
      : 'Enables APK and AAB release artifacts.';
  String get flutterAndroidNote => _isRu
      ? 'Flutter нужен для Android-сборки так же, как и для desktop.'
      : 'Flutter is required for Android builds as well as desktop builds.';
  String get javaNote => _isRu
      ? 'Нужна Android Gradle toolchain для сборки APK/AAB.'
      : 'Required by the Android Gradle toolchain for APK/AAB builds.';

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

  String buildCapabilityLabel(String statusName) {
    return switch (statusName) {
      'installed' => _isRu ? 'Можно собирать' : 'Ready',
      'available' => _isRu ? 'Нужны инструменты' : 'Needs tools',
      'missing' => _isRu ? 'Недоступно' : 'Unavailable',
      _ => statusName,
    };
  }

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
