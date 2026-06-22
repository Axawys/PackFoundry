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
  String get cancel => _isRu ? 'Отменить' : 'Cancel';
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
  String get importConfig => _isRu ? 'Импорт конфига' : 'Import config';
  String get exportConfig => _isRu ? 'Экспорт конфига' : 'Export config';
  String get configFileType =>
      _isRu ? 'PackFoundry config' : 'PackFoundry config';
  String get iconTypeGroup => _isRu ? 'Иконки приложения' : 'Application icons';
  String get chooseIcon => _isRu ? 'Выбрать иконку' : 'Choose icon';
  String get pubspecFound =>
      _isRu ? 'pubspec.yaml найден' : 'pubspec.yaml found';
  String get pubspecMissing =>
      _isRu ? 'pubspec.yaml не найден' : 'pubspec.yaml missing';
  String get linuxRunnerFound =>
      _isRu ? 'Linux runner найден' : 'Linux runner found';
  String get windowsRunnerFound =>
      _isRu ? 'Windows runner найден' : 'Windows runner found';
  String get desktopRunnersMissing =>
      _isRu ? 'Desktop runners не найдены' : 'Desktop runners missing';
  String get projectVersionFound => _isRu ? 'Версия найдена' : 'Version found';
  String get projectVersionMissing =>
      _isRu ? 'Версия не указана' : 'Version missing';
  String get projectDescriptionFound =>
      _isRu ? 'Описание найдено' : 'Description found';
  String get projectDescriptionMissing =>
      _isRu ? 'Описание не указано' : 'Description missing';
  String get configImported => _isRu
      ? 'Конфиг PackFoundry применён.'
      : 'PackFoundry config was applied.';
  String get configExported =>
      _isRu ? 'Конфиг PackFoundry сохранён.' : 'PackFoundry config was saved.';

  String configImportFailed(String detail) {
    return _isRu
        ? 'Не удалось импортировать конфиг: $detail'
        : 'Could not import config: $detail';
  }

  String configExportFailed(String detail) {
    return _isRu
        ? 'Не удалось экспортировать конфиг: $detail'
        : 'Could not export config: $detail';
  }

  String get applicationSettings =>
      _isRu ? 'Настройки приложения' : 'Application settings';
  String get applicationName =>
      _isRu ? 'Название приложения' : 'Application name';
  String get releaseMetadata =>
      _isRu ? 'Метаданные релиза' : 'Release metadata';
  String get releaseTag => _isRu ? 'Тег релиза' : 'Release tag';
  String get developerEmail => _isRu ? 'Почта разработчика' : 'Developer email';
  String get publisherName =>
      _isRu ? 'Разработчик / издатель' : 'Developer / publisher';
  String get homepageUrl => _isRu ? 'Сайт проекта' : 'Project homepage';
  String get license => _isRu ? 'Лицензия' : 'License';
  String get packageDescription =>
      _isRu ? 'Описание пакета' : 'Package description';
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
  String get tarGzBuildGroupTitle => 'TAR.GZ';
  String get windowsBuildGroupTitle => 'EXE';
  String get androidBuildGroupTitle => 'APK';
  String get installMissingTools =>
      _isRu ? 'Установить недостающие инструменты' : 'Install missing tools';
  String get installingTools => _isRu ? 'Установка...' : 'Installing...';
  String get removeBuilder => _isRu ? 'Удалить builder' : 'Remove builder';
  String builderInstallSize(String size) {
    return _isRu ? 'Размер: $size' : 'Size: $size';
  }

  String builderInstallProgress(int progress) {
    return _isRu
        ? 'Установка builder: $progress%'
        : 'Builder install: $progress%';
  }

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

  String toolRemoveSuccess(String detail) {
    return _isRu ? 'Инструменты удалены. $detail' : 'Tools removed. $detail';
  }

  String toolRemoveFailed(String detail) {
    return _isRu
        ? 'Не удалось удалить инструменты. $detail'
        : 'Could not remove tools. $detail';
  }

  String get exeInstallUnsupported => _isRu
      ? 'EXE-сборка экспортируется как Windows build kit zip.'
      : 'EXE builds are exported as a Windows build kit zip.';
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
  String get tarGzBuildGroupSubtitle => _isRu
      ? 'Сборка переносимого tar.gz архива с Linux release bundle.'
      : 'Build a portable tar.gz archive with the Linux release bundle.';
  String get windowsBuildGroupSubtitle => _isRu
      ? 'PackFoundry создаёт zip-набор: проект, Inno Setup config и скрипт сборки для Windows.'
      : 'PackFoundry creates a zip kit with the project, Inno Setup config and Windows build script.';
  String get androidBuildGroupSubtitle => _isRu
      ? 'Сборка Android APK через Flutter и локальный Android SDK.'
      : 'Build Android APK through Flutter and the local Android SDK.';
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
  String get tarToolNote => _isRu
      ? 'Сжимает Linux release bundle в переносимый tar.gz архив.'
      : 'Compresses the Linux release bundle into a portable tar.gz archive.';
  String get dockerNote => _isRu
      ? 'Нужен для сборки пакетов в контейнерах, например deb на Fedora.'
      : 'Required for container builds, such as deb packaging on Fedora.';
  String get dockerDebNote => _isRu
      ? 'Нужен для запуска управляемого DEB builder окружения.'
      : 'Required to run the managed DEB builder environment.';
  String get dockerRpmNote => _isRu
      ? 'Нужен для запуска управляемого RPM builder окружения.'
      : 'Required to run the managed RPM builder environment.';
  String get debianBuilderNote => _isRu
      ? 'PackFoundry собирает этот образ один раз: Debian, Flutter SDK и инструменты deb-сборки остаются в кеше до удаления.'
      : 'PackFoundry builds this image once: Debian, Flutter SDK and deb packaging tools stay cached until removed.';
  String get rpmBuilderNote => _isRu
      ? 'PackFoundry builder на Fedora с Flutter SDK и rpm-build для воспроизводимой rpm-сборки.'
      : 'PackFoundry Fedora builder with Flutter SDK and rpm-build for reproducible rpm packaging.';
  String get dpkgDebNote => _isRu
      ? 'Создаёт deb-пакет на Debian/Ubuntu-like хостах.'
      : 'Creates deb packages on Debian/Ubuntu-like hosts.';
  String get rpmBuildToolNote => _isRu
      ? 'Создаёт rpm-пакет на Fedora/RHEL-like хостах.'
      : 'Creates rpm packages on Fedora/RHEL-like hosts.';
  String get miniGuide => _isRu ? 'Мини-инструкция' : 'Mini guide';
  List<String> get windowsBuildKitGuideSteps => _isRu
      ? const [
          'Во вкладке Project выберите Windows / Inno Setup exe, затем во вкладке Build соберите пакеты.',
          'В папке экспорта появится *_windows_build_kit.zip. Скопируйте его в Windows 10/11 или Windows VM.',
          r'Распакуйте архив, откройте PowerShell в распакованной папке и запустите: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\scripts\build_windows.ps1',
          'Скрипт сам проверит Flutter, Visual Studio Build Tools, Inno Setup и Developer Mode. Если попросит включить Developer Mode, включите его и запустите скрипт снова.',
          'Готовый EXE-установщик появится в папке output рядом со скриптом.',
        ]
      : const [
          'In Project, select Windows / Inno Setup exe, then build packages from the Build workspace.',
          'The export folder will contain *_windows_build_kit.zip. Copy it to Windows 10/11 or a Windows VM.',
          r'Extract the archive, open PowerShell in the extracted folder and run: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\scripts\build_windows.ps1',
          'The script checks Flutter, Visual Studio Build Tools, Inno Setup and Developer Mode. If it asks for Developer Mode, enable it and run the script again.',
          'The final EXE installer appears in the output folder next to the script.',
        ];
  String get windowsZipNote => _isRu
      ? 'Нужен на Linux-хосте, чтобы создать переносимый Windows build kit архив.'
      : 'Required on the Linux host to create a transferable Windows build kit archive.';
  String get windowsMachineNote => _isRu
      ? 'Пользователь переносит zip в настоящую Windows или VM. Внутри не нужны сетевые пробросы и агент.'
      : 'The user moves the zip to a real Windows machine or VM. No port forwarding or agent is needed.';
  String get windowsBuildScriptNote => _isRu
      ? 'Скрипт внутри zip проверит и установит Flutter SDK, Visual Studio Build Tools и Inno Setup, затем соберёт EXE.'
      : 'The script inside the zip checks and installs Flutter SDK, Visual Studio Build Tools and Inno Setup, then builds the EXE.';
  String get innoSetupNote => _isRu
      ? 'Упаковывает уже собранное Windows-приложение в EXE-установщик.'
      : 'Packages an already-built Windows app into an EXE installer.';
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
  String get additionalPackageDependencies =>
      _isRu ? 'Дополнительные зависимости' : 'Additional dependencies';
  String get additionalPackageDependenciesHelp => _isRu
      ? 'Эти зависимости добавляются к стандартным зависимостям выбранного формата пакета при сборке.'
      : 'These dependencies are appended to the default dependency list for the selected package format during build.';
  String get debAdditionalDependenciesHelp => _isRu
      ? 'Одна зависимость на строку. Можно использовать альтернативы через |.'
      : 'One dependency per line. Alternatives with | are allowed.';
  String get rpmAdditionalDependenciesHelp =>
      _isRu ? 'Одна зависимость на строку.' : 'One dependency per line.';
  String get packageInspectorShort => _isRu ? 'Пакеты' : 'Packages';
  String get packageInspector =>
      _isRu ? 'Инспектор пакета' : 'Package Inspector';
  String get choosePackage => _isRu ? 'Выбрать пакет' : 'Choose package';
  String get packageTypeGroup => _isRu ? 'Пакеты' : 'Packages';
  String get noPackageSelected => _isRu
      ? 'Выберите готовый пакет из файловой системы, чтобы посмотреть его метаданные и зависимости.'
      : 'Choose an existing package from the filesystem to inspect metadata and dependencies.';
  String get packageFormat => _isRu ? 'Формат пакета' : 'Package format';
  String get packageFileName => _isRu ? 'Файл' : 'File';
  String get packageSize => _isRu ? 'Размер' : 'Size';
  String get packagePath => _isRu ? 'Путь' : 'Path';
  String get packageFileTree => _isRu ? 'Дерево файлов' : 'File tree';
  String get packageFileTreeUnavailable => _isRu
      ? 'Не удалось распаковать пакет или получить список файлов.'
      : 'Could not extract the package or read its file list.';
  String packageFileTreeCount(int count) {
    if (!_isRu) {
      return '$count item${count == 1 ? '' : 's'}';
    }
    return 'Элементов: $count';
  }

  String get packageEditMode => _isRu ? 'Редактирование' : 'Editing';
  String get packageEditable => _isRu ? 'Доступно' : 'Available';
  String get packageReadonly => _isRu ? 'Только просмотр' : 'Read only';
  String get packageMetadata => _isRu ? 'Метаданные' : 'Metadata';
  String get packageMetadataHelp => _isRu
      ? 'Для DEB это содержимое control-файла. Изменения сохраняются в новую копию пакета.'
      : 'For DEB this is the control file content. Changes are saved into a new package copy.';
  String get packageReadonlyHelp => _isRu
      ? 'Этот формат нельзя безопасно патчить после сборки. Измените данные в проекте и пересоберите пакет.'
      : 'This format cannot be safely patched after build. Change metadata in the project and rebuild the package.';
  String get packageDependencies => _isRu ? 'Зависимости' : 'Dependencies';
  String get packageDependenciesHelp => _isRu
      ? 'Одна зависимость на строку. Для DEB можно использовать альтернативы через |, например libgtk-3-0 | libgtk-3-0t64.'
      : 'One dependency per line. DEB alternatives with | are allowed, for example libgtk-3-0 | libgtk-3-0t64.';
  String get saveEditedPackage =>
      _isRu ? 'Сохранить измененную копию' : 'Save edited copy';
  String packageSaved(String path) => _isRu
      ? 'Измененный пакет сохранен: $path'
      : 'Edited package saved: $path';
  String packageInspectFailed(String error) => _isRu
      ? 'Не удалось прочитать пакет. $error'
      : 'Could not inspect package. $error';
  String packageSaveFailed(String error) => _isRu
      ? 'Не удалось сохранить пакет. $error'
      : 'Could not save package. $error';
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
  String get runWithoutBuild =>
      _isRu ? 'Запустить без сборки' : 'Run without build';
  String get runningApp => _isRu ? 'Приложение запущено' : 'App is running';
  String get stopRunningApp => _isRu ? 'Остановить' : 'Stop';
  String get buildSuccessTitle =>
      _isRu ? 'Сборка завершена' : 'Build completed';
  String get buildSuccessMessage => _isRu
      ? 'Выбранные установщики успешно собраны и сохранены в папку экспорта.'
      : 'Selected installers were built successfully and saved to the output folder.';
  String get ok => _isRu ? 'OK' : 'OK';
  String get visualBuildMode => _isRu ? 'Визуально' : 'Visual';
  String get commandsBuildMode => _isRu ? 'Команды' : 'Commands';
  String get fullRoadmapMode => _isRu ? 'Полное' : 'Full';
  String get simplifiedRoadmapMode => _isRu ? 'Упрощенное' : 'Simplified';
  String get noBuildCommands => _isRu
      ? 'Выберите форматы установщиков, чтобы увидеть команды сборки.'
      : 'Select installer formats to preview build commands.';
  String get selectProjectForCommands => _isRu
      ? 'Выберите Flutter-проект, чтобы PackFoundry подставил реальные пути и имена.'
      : 'Select a Flutter project so PackFoundry can resolve real paths and names.';
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
    if (_isRu) {
      final title = _russianVisualRoadmapTitles[id];
      if (title != null) {
        return title;
      }
    }
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
      'windows-kit' => _isRu ? 'WINDOWS KIT' : 'WINDOWS KIT',
      'android-build' => _isRu ? 'APK сборка' : 'APK build',
      'apk-export' => _isRu ? 'APK экспорт' : 'APK export',
      'summary' => _isRu ? 'Экспорт' : 'Export',
      'cleanup' => _isRu ? 'Очистка' : 'Cleanup',
      _ => fallback,
    };
  }

  String roadmapStepDescription(String id, String fallback) {
    if (_isRu) {
      final description = _russianVisualRoadmapDescriptions[id];
      if (description != null) {
        return description;
      }
    }
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
            ? 'Запуск кешированного Debian builder окружения.'
            : 'Start the cached Debian builder environment.',
      'deb-build' =>
        _isRu
            ? 'Получение зависимостей и сборка внутри кешированного builder.'
            : 'Resolve dependencies and compile inside the cached builder.',
      'deb-package' =>
        _isRu
            ? 'Создание DEBIAN/control и запуск dpkg-deb.'
            : 'Create DEBIAN/control and run dpkg-deb.',
      'windows-kit' =>
        _isRu
            ? 'Создание zip-набора для сборки EXE на Windows.'
            : 'Create a zip kit for building the EXE on Windows.',
      'android-build' =>
        _isRu
            ? 'Сборка Android release APK через Flutter и Gradle.'
            : 'Compile the Android release APK through Flutter and Gradle.',
      'apk-export' =>
        _isRu
            ? 'Поиск готового APK и копирование в папку экспорта.'
            : 'Find the generated APK and copy it to the export folder.',
      'summary' =>
        _isRu
            ? 'Проверка и вывод списка созданных артефактов.'
            : 'Verify and report generated artifacts.',
      'cleanup' =>
        _isRu
            ? 'Удаление временных рабочих папок. Тяжёлые кеши builder остаются отдельно.'
            : 'Remove temporary workspaces. Builder builds keep heavy caches outside this folder.',
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
      'Preparing transferable Windows build kit zip.' =>
        'Готовим переносимый Windows build kit zip.',
      'Copying project and writing Windows helper files.' =>
        'Копируем проект и записываем вспомогательные Windows-файлы.',
      'Compressing Windows build kit zip.' =>
        'Упаковываем Windows build kit в zip.',
      'Using cached PackFoundry Debian builder with Flutter SDK and Linux packaging tools.' =>
        'Используем кешированный PackFoundry Debian builder с Flutter SDK и инструментами упаковки Linux.',
      'Running flutter pub get with persistent PackFoundry pub-cache.' =>
        'Запускаем flutter pub get с постоянным PackFoundry pub-cache.',
      'Running flutter build linux --release inside the Debian builder.' =>
        'Запускаем flutter build linux --release внутри Debian builder.',
      'Writing DEBIAN/control, desktop entry and icon files.' =>
        'Записываем DEBIAN/control, desktop-файл и файлы иконок.',
      'Running dpkg-deb --build for the package root.' =>
        'Запускаем dpkg-deb --build для корня пакета.',
      'Using PackFoundry DEB builder image with Flutter SDK and Linux dependencies already installed.' =>
        'Используем PackFoundry DEB builder image, где Flutter SDK и Linux-зависимости уже установлены.',
      'Running flutter pub get with the persistent PackFoundry pub-cache volume.' =>
        'Запускаем flutter pub get с постоянным PackFoundry pub-cache volume.',
      'Running flutter build linux --release inside the cached Debian builder.' =>
        'Запускаем flutter build linux --release внутри кешированного Debian builder.',
      _ => detail,
    };
  }

  String get roadmapDetailsTitle => _isRu ? 'Что происходит' : 'What happens';
  String get visualSubstepExpandedDetail => _isRu
      ? 'PackFoundry отслеживает выполнение этого технического действия и автоматически обновляет его статус, прогресс и диагностические сообщения.'
      : 'PackFoundry tracks this technical action and automatically updates its status, progress, and diagnostic messages.';
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
      'windows-kit' =>
        _isRu
            ? 'PackFoundry складывает во временную папку копию проекта, настройки Inno Setup, выбранную иконку и PowerShell-скрипт. Затем всё упаковывается в zip, который можно перенести в Windows и запустить без сетевой настройки VM.'
            : 'PackFoundry puts a project copy, Inno Setup config, selected icon and PowerShell script into a temporary folder. Then it zips everything so it can be moved to Windows and run without VM network setup.',
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

const _russianVisualRoadmapTitles = <String, String>{
  'project:validate': 'Проверка проекта',
  'project:metadata': 'Чтение метаданных',
  'project:export': 'Подготовка экспорта',
  'workspace:create': 'Создание workspace',
  'workspace:copy': 'Копирование исходников',
  'workspace:overrides': 'Применение настроек',
  'local-build:dependencies': 'Зависимости Flutter',
  'local-build:compile': 'Компиляция Flutter',
  'local-build:native': 'Нативный runner',
  'bundle:locate': 'Поиск bundle',
  'bundle:executable': 'Исполняемый файл',
  'bundle:icon': 'Иконка окна',
  'rpm:tree': 'Структура RPM',
  'rpm:metadata': 'Метаданные RPM',
  'rpm:spec': 'Spec-файл RPM',
  'rpm:build': 'Запуск rpmbuild',
  'rpm:export': 'Экспорт RPM',
  'appimage:appdir': 'Структура AppDir',
  'appimage:apprun': 'Создание AppRun',
  'appimage:desktop': 'Интеграция с desktop',
  'appimage:package': 'Запуск appimagetool',
  'appimage:export': 'Экспорт AppImage',
  'targz:archive': 'Создание архива',
  'targz:verify': 'Проверка архива',
  'deb-container:runtime': 'Docker или Podman',
  'deb-container:image': 'Образ DEB builder',
  'deb-container:start': 'Запуск builder',
  'deb-build:dependencies': 'Зависимости в Debian',
  'deb-build:compile': 'Компиляция в Debian',
  'deb-build:bundle': 'Поиск DEB bundle',
  'deb-package:layout': 'Структура Debian-пакета',
  'deb-package:control': 'Файл DEBIAN/control',
  'deb-package:desktop': 'Интеграция DEB',
  'deb-package:build': 'Запуск dpkg-deb',
  'deb-package:export': 'Экспорт DEB',
  'windows-kit:layout': 'Структура Windows kit',
  'windows-kit:project': 'Копирование проекта Windows',
  'windows-kit:scripts': 'Скрипты Windows',
  'windows-kit:archive': 'Архив Windows kit',
  'android-build:dependencies': 'Зависимости Android',
  'android-build:gradle': 'Gradle release build',
  'android-build:signing': 'Подпись APK',
  'apk-export:locate': 'Поиск APK',
  'apk-export:copy': 'Экспорт APK',
  'summary:verify': 'Проверка артефактов',
  'summary:report': 'Итоги сборки',
  'cleanup:ownership': 'Подготовка очистки',
  'cleanup:remove': 'Удаление workspace',
};

const _russianVisualRoadmapDescriptions = <String, String>{
  'project:validate':
      'Проверяем наличие pubspec.yaml и структуру Flutter-проекта.',
  'project:metadata': 'Читаем название, версию и параметры будущих пакетов.',
  'project:export': 'Проверяем и создаём выбранную папку экспорта.',
  'workspace:create': 'Создаём изолированный временный каталог сборки.',
  'workspace:copy': 'Копируем исходники без старых build-кешей и .git.',
  'workspace:overrides':
      'Применяем размер окна, иконку и application-id только к копии.',
  'local-build:dependencies': 'Получаем зависимости проекта через Flutter pub.',
  'local-build:compile':
      'Компилируем Dart-код и Flutter assets в release-режиме.',
  'local-build:native': 'Собираем плагины и нативный Linux runner.',
  'bundle:locate': 'Находим созданный каталог release/bundle.',
  'bundle:executable': 'Определяем основной исполняемый файл приложения.',
  'bundle:icon': 'Добавляем выбранную иконку окна внутрь bundle.',
  'rpm:tree': 'Создаём каталоги SPECS, RPMS и staging-файлы.',
  'rpm:metadata': 'Записываем desktop-файл и системную иконку.',
  'rpm:spec': 'Формируем правила установки, зависимости и список файлов.',
  'rpm:build': 'Передаём spec-файл rpmbuild и собираем бинарный RPM.',
  'rpm:export': 'Копируем готовый RPM в папку экспорта.',
  'appimage:appdir': 'Создаём переносимую файловую структуру AppDir.',
  'appimage:apprun':
      'Записываем launcher, который находит и запускает приложение.',
  'appimage:desktop': 'Добавляем desktop-файл, application-id и иконку.',
  'appimage:package': 'Упаковываем AppDir в один файл через appimagetool.',
  'appimage:export': 'Выставляем право запуска и проверяем итоговый AppImage.',
  'targz:archive': 'Сжимаем Linux release bundle командами tar и gzip.',
  'targz:verify': 'Проверяем наличие созданного tar.gz в экспорте.',
  'deb-container:runtime': 'Определяем доступный контейнерный runtime.',
  'deb-container:image': 'Проверяем кешированный Debian builder с Flutter SDK.',
  'deb-container:start': 'Подключаем проект, экспорт и постоянный pub-cache.',
  'deb-build:dependencies': 'Запускаем flutter pub get внутри Debian builder.',
  'deb-build:compile': 'Собираем Linux release bundle в окружении Debian.',
  'deb-build:bundle': 'Находим bundle и исполняемый файл внутри контейнера.',
  'deb-package:layout': 'Создаём DEBIAN, /opt и каталоги desktop-интеграции.',
  'deb-package:control':
      'Записываем версию, зависимости, описание и maintainer.',
  'deb-package:desktop': 'Устанавливаем desktop-файл и иконку приложения.',
  'deb-package:build': 'Собираем пакет командой dpkg-deb --build.',
  'deb-package:export': 'Переносим готовый DEB из контейнера в экспорт.',
  'windows-kit:layout': 'Создаём каталоги project, scripts, inno и assets.',
  'windows-kit:project': 'Копируем подготовленный Flutter-проект в набор.',
  'windows-kit:scripts': 'Генерируем PowerShell и конфигурацию Inno Setup.',
  'windows-kit:archive': 'Упаковываем переносимый Windows build kit в zip.',
  'android-build:dependencies':
      'Получаем Flutter-зависимости перед Android-сборкой.',
  'android-build:gradle': 'Запускаем Flutter и Gradle для release-сборки APK.',
  'android-build:signing':
      'Android toolchain подписывает итоговый APK доступным ключом.',
  'apk-export:locate': 'Находим созданный файл app-release.apk.',
  'apk-export:copy': 'Копируем APK в папку экспорта с именем приложения.',
  'summary:verify': 'Проверяем созданные файлы для всех выбранных целей.',
  'summary:report': 'Показываем пути к успешным пакетам и итог сборки.',
  'cleanup:ownership': 'Возвращаем владельца файлов после контейнерной сборки.',
  'cleanup:remove': 'Удаляем временную копию проекта и staging-файлы.',
};

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
