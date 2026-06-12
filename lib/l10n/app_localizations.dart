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
  String get preferences => _isRu ? 'Установки' : 'Preferences';
  String get themeChoice => _isRu ? 'Тема интерфейса' : 'Interface theme';
  String get themeSystem => _isRu ? 'Системная' : 'System';
  String get themeLight => _isRu ? 'Светлая' : 'Light';
  String get themeDark => _isRu ? 'Тёмная' : 'Dark';
  String get languageChoice => _isRu ? 'Язык интерфейса' : 'Interface language';
  String get languageSystem => _isRu ? 'Системный' : 'System';
  String get languageEnglish => _isRu ? 'English' : 'English';
  String get languageRussian => _isRu ? 'Русский' : 'Russian';
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
  String get technicalLog => _isRu ? 'Технический лог' : 'Technical log';
  String get roadmapRunning => _isRu ? 'Выполняется' : 'Running';
  String overallProgressLabel(int progress) {
    return _isRu
        ? 'Общий прогресс: $progress%'
        : 'Overall progress: $progress%';
  }

  String buildRemainingTime(int seconds) {
    if (seconds <= 0) {
      return _isRu
          ? 'Осталось: меньше минуты'
          : 'Remaining: less than a minute';
    }
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) {
      return _isRu ? 'Осталось: ~$minutes мин' : 'Remaining: ~$minutes min';
    }
    final hours = minutes ~/ 60;
    final restMinutes = minutes % 60;
    if (restMinutes == 0) {
      return _isRu ? 'Осталось: ~$hours ч' : 'Remaining: ~$hours h';
    }
    return _isRu
        ? 'Осталось: ~$hours ч $restMinutes мин'
        : 'Remaining: ~$hours h $restMinutes min';
  }

  String roadmapUsuallySeconds(int seconds) {
    return _isRu ? 'Обычно: ~$seconds сек' : 'Usually: ~$seconds sec';
  }

  String roadmapUsuallyMinutes(int minutes) {
    return _isRu ? 'Обычно: ~$minutes мин' : 'Usually: ~$minutes min';
  }

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

  String roadmapStepTitle(String id, String fallback) {
    return switch (id) {
      'project' => _isRu ? 'Проект' : 'Project',
      'workspace' => _isRu ? 'Workspace' : 'Workspace',
      'local-build' => _isRu ? 'Flutter build' : 'Flutter build',
      'bundle' => _isRu ? 'Linux bundle' : 'Linux bundle',
      'rpm' => 'RPM',
      'appimage' => 'APPIMAGE',
      'targz' => 'TAR.GZ',
      'deb-container' => _isRu ? 'DEB контейнер' : 'DEB container',
      'deb-build' => _isRu ? 'DEB сборка' : 'DEB build',
      'deb-package' => _isRu ? 'DEB пакет' : 'DEB package',
      'summary' => _isRu ? 'Экспорт' : 'Export',
      'cleanup' => _isRu ? 'Очистка' : 'Cleanup',
      _ => fallback,
    };
  }

  String roadmapStepDescription(String id, String fallback) {
    return switch (id) {
      'project' =>
        _isRu
            ? 'Проверка pubspec.yaml, метаданных приложения и папки экспорта.'
            : 'Check pubspec.yaml, app metadata and export folder.',
      'workspace' =>
        _isRu
            ? 'Копирование проекта и применение настроек без изменения исходников.'
            : 'Copy the project and apply settings without touching sources.',
      'local-build' =>
        _isRu
            ? 'Сборка Linux release bundle на хосте.'
            : 'Compile the Linux release bundle on the host.',
      'bundle' =>
        _isRu
            ? 'Поиск release bundle и исполняемого файла.'
            : 'Find the release bundle and executable file.',
      'rpm' =>
        _isRu
            ? 'Генерация spec-файла и запуск rpmbuild.'
            : 'Generate spec metadata and run rpmbuild.',
      'appimage' =>
        _isRu
            ? 'Создание AppDir, AppRun и упаковка через appimagetool.'
            : 'Create AppDir, AppRun and package it with appimagetool.',
      'targz' =>
        _isRu
            ? 'Архивация Linux release bundle.'
            : 'Archive the Linux release bundle.',
      'deb-container' =>
        _isRu
            ? 'Запуск Debian Docker builder и установка инструментов сборки.'
            : 'Start Debian Docker builder and install build tools.',
      'deb-build' =>
        _isRu
            ? 'Сборка Linux release bundle внутри Debian.'
            : 'Build the Linux release bundle inside Debian.',
      'deb-package' =>
        _isRu
            ? 'Создание DEBIAN/control и запуск dpkg-deb.'
            : 'Create DEBIAN/control and run dpkg-deb.',
      'summary' =>
        _isRu
            ? 'Проверка и вывод списка созданных артефактов.'
            : 'Verify and report generated artifacts.',
      'cleanup' =>
        _isRu
            ? 'Удаление временных рабочих папок. Docker-сборки могут создавать много файлов.'
            : 'Remove temporary workspaces. Docker builds may contain many generated files.',
      _ => fallback,
    };
  }

  String roadmapDetail(String detail) {
    if (!_isRu) {
      return detail;
    }
    return switch (detail) {
      'Checking project folder and pubspec.yaml.' =>
        'Проверяем папку проекта и pubspec.yaml.',
      'Project metadata and output folder are ready.' =>
        'Метаданные проекта и папка экспорта готовы.',
      'Copying project into a disposable workspace.' =>
        'Копируем проект во временное рабочее окружение.',
      'Temporary project copy is ready.' => 'Временная копия проекта готова.',
      'Running flutter build linux --release.' =>
        'Запускаем flutter build linux --release.',
      'Linux release bundle was compiled.' =>
        'Linux release bundle успешно собран.',
      'Looking for release/bundle and executable file.' =>
        'Ищем release/bundle и исполняемый файл.',
      'Expected build/linux/<arch>/release/bundle.' =>
        'Ожидалась папка build/linux/<arch>/release/bundle.',
      'Bundle and executable are ready for packaging.' =>
        'Bundle и исполняемый файл готовы к упаковке.',
      'Starting Debian Docker builder.' => 'Запускаем Debian Docker builder.',
      'Selected artifacts were written to the export folder.' =>
        'Выбранные артефакты записаны в папку экспорта.',
      'Removing temporary Flutter and packaging workspaces. Docker builds can leave a large cache here.' =>
        'Удаляем временные папки Flutter и упаковки. Docker-сборка может оставить здесь большой кеш.',
      'Temporary files were removed.' => 'Временные файлы удалены.',
      'Temporary files were already removed.' => 'Временные файлы уже удалены.',
      'Step completed.' => 'Этап завершён.',
      'Preparing AppDir and appimagetool package.' =>
        'Готовим AppDir и пакет appimagetool.',
      'Preparing rpmbuild tree and package metadata.' =>
        'Готовим дерево rpmbuild и метаданные пакета.',
      'Creating compressed release bundle.' => 'Создаём сжатый release bundle.',
      'apt-get update inside debian:bookworm.' =>
        'Выполняем apt-get update внутри debian:bookworm.',
      'clang, cmake, ninja, GTK and dpkg tools.' =>
        'Устанавливаем clang, cmake, ninja, GTK и инструменты dpkg.',
      'Cloning the stable Flutter channel inside Debian.' =>
        'Клонируем стабильный канал Flutter внутри Debian.',
      'Enabling Linux desktop support in the container.' =>
        'Включаем поддержку Linux desktop в контейнере.',
      'Running flutter pub get in the copied project.' =>
        'Запускаем flutter pub get в скопированном проекте.',
      'Running flutter build linux --release inside Debian.' =>
        'Запускаем flutter build linux --release внутри Debian.',
      'Creating DEBIAN/control, desktop entry and icon directories.' =>
        'Создаём DEBIAN/control, desktop-файл и папки для иконок.',
      'Running dpkg-deb --build.' => 'Запускаем dpkg-deb --build.',
      _ => detail,
    };
  }

  String get roadmapDetailsTitle => _isRu ? 'Что происходит' : 'What happens';
  String get roadmapExpandHint => _isRu ? 'Развернуть этап' : 'Expand step';
  String get roadmapCollapseHint => _isRu ? 'Свернуть этап' : 'Collapse step';

  String roadmapProgressLabel(int progress) {
    return _isRu ? 'Прогресс: $progress%' : 'Progress: $progress%';
  }

  String roadmapStatusLabel(String statusName) {
    return switch (statusName) {
      'pending' => _isRu ? 'Ожидает' : 'Pending',
      'running' => _isRu ? 'Выполняется' : 'Running',
      'success' => _isRu ? 'Готово' : 'Done',
      'warning' => _isRu ? 'Ошибка или предупреждение' : 'Error or warning',
      'skipped' => _isRu ? 'Пропущено' : 'Skipped',
      _ => statusName,
    };
  }

  String roadmapStepExpandedDetail(String id) {
    return switch (id) {
      'project' =>
        _isRu
            ? 'PackFoundry проверяет, что выбранная папка похожа на Flutter-проект: есть pubspec.yaml, понятна папка экспорта и можно прочитать базовые настройки приложения.'
            : 'PackFoundry checks that the selected folder looks like a Flutter project: pubspec.yaml exists, the export folder is usable, and basic app metadata can be read.',
      'workspace' =>
        _isRu
            ? 'Проект копируется во временную папку. Все изменения для сборки, например временный размер окна, применяются только к этой копии, поэтому исходники проекта не меняются.'
            : 'The project is copied into a temporary folder. Build-only changes, such as temporary window size overrides, are applied only to that copy, so source files are not modified.',
      'local-build' =>
        _isRu
            ? 'На хосте запускается flutter build linux --release. Flutter компилирует приложение, плагины и native runner в release bundle для текущей Linux-системы.'
            : 'The host runs flutter build linux --release. Flutter compiles the app, plugins, and native runner into a release bundle for the current Linux system.',
      'bundle' =>
        _isRu
            ? 'После сборки PackFoundry ищет папку release/bundle и основной исполняемый файл. Именно этот bundle становится основой для RPM, AppImage и tar.gz.'
            : 'After the build, PackFoundry locates the release/bundle folder and the main executable. That bundle becomes the source for RPM, AppImage, and tar.gz packaging.',
      'rpm' =>
        _isRu
            ? 'Создаётся дерево rpmbuild, desktop-файл, иконка и spec-файл. Затем rpmbuild упаковывает приложение в RPM с установкой в /opt и ярлыком в системном меню.'
            : 'PackFoundry creates the rpmbuild tree, desktop file, icon, and spec file. Then rpmbuild packages the app into an RPM installed under /opt with a desktop launcher.',
      'appimage' =>
        _isRu
            ? 'Создаётся AppDir: внутрь кладутся исполняемый файл, библиотеки, AppRun, desktop-файл и иконка. После этого appimagetool собирает один запускаемый AppImage-файл.'
            : 'PackFoundry creates an AppDir containing the executable, libraries, AppRun, desktop file, and icon. appimagetool then produces one runnable AppImage file.',
      'targz' =>
        _isRu
            ? 'Release bundle сжимается в tar.gz. Это не системный установщик, а переносимый архив, который удобно передавать или распаковывать вручную.'
            : 'The release bundle is compressed into tar.gz. This is not a system installer, but a portable archive that is easy to share or unpack manually.',
      'deb-container' =>
        _isRu
            ? 'Для DEB на не-Debian системах запускается Debian-контейнер. Внутри него обновляется apt и устанавливаются инструменты, чтобы пакет собирался в совместимом окружении.'
            : 'For DEB on non-Debian systems, PackFoundry starts a Debian container. Inside it, apt is updated and build tools are installed so the package is produced in a compatible environment.',
      'deb-build' =>
        _isRu
            ? 'Внутри Debian-контейнера выполняются flutter pub get и flutter build linux --release. Так Linux bundle собирается так, как если бы проект собирали на Debian.'
            : 'Inside the Debian container, flutter pub get and flutter build linux --release run. The Linux bundle is produced as if the project were built on Debian.',
      'deb-package' =>
        _isRu
            ? 'PackFoundry создаёт структуру Debian-пакета: DEBIAN/control, /opt с приложением, desktop-файл и иконки. Затем dpkg-deb собирает итоговый .deb.'
            : 'PackFoundry creates the Debian package layout: DEBIAN/control, /opt app files, desktop file, and icons. Then dpkg-deb builds the final .deb.',
      'summary' =>
        _isRu
            ? 'На этом этапе PackFoundry подтверждает, что выбранные артефакты записаны в папку экспорта, и завершает общий прогресс сборки.'
            : 'At this step, PackFoundry confirms that selected artifacts were written to the export folder and completes the overall build progress.',
      'cleanup' =>
        _isRu
            ? 'Удаляется временная копия проекта и промежуточные файлы упаковки. После Docker-сборок это может занять дольше, потому что внутри workspace много сгенерированных файлов.'
            : 'The temporary project copy and packaging intermediates are removed. After Docker builds this can take longer because the workspace contains many generated files.',
      _ =>
        _isRu
            ? 'PackFoundry выполняет технический этап сборки и обновляет прогресс по мере получения событий.'
            : 'PackFoundry runs a technical build step and updates progress as events arrive.',
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
