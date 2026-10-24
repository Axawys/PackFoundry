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
  String get projectPath => _isRu ? 'Путь к проекту' : 'Project path';
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
  String get projectVersionFound => _isRu ? 'Версия найдена' : 'Version found';
  String get projectVersionMissing =>
      _isRu ? 'Версия не указана' : 'Version missing';
  String get projectDescriptionFound =>
      _isRu ? 'Описание найдено' : 'Description found';
  String get projectDescriptionMissing =>
      _isRu ? 'Описание не указано' : 'Description missing';
  String projectIconFound(String path) =>
      _isRu ? 'Иконка: $path' : 'Icon: $path';
  String get projectIconMissing =>
      _isRu ? 'Иконка в assets не найдена' : 'No icon found in assets';
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

  String projectFolderNotFound(String path) {
    return _isRu ? 'Папка не найдена: $path' : 'Folder was not found: $path';
  }

  String get configPresets => _isRu ? 'Конфиги' : 'Configs';
  String get configPresetsHint => _isRu
      ? 'Конфиги остаются закреплёнными, пока их файлы существуют на диске. Нажмите на конфиг, чтобы применить его.'
      : 'Configs stay pinned as long as their files exist on disk. Click a config to apply it.';
  String get noConfigPresets => _isRu
      ? 'Пока нет закреплённых конфигов. Добавьте файл конфига или сохраните текущие настройки.'
      : 'No pinned configs yet. Add a config file or save the current settings.';
  String get addConfig => _isRu ? 'Добавить конфиг' : 'Add config';
  String get saveCurrentConfig =>
      _isRu ? 'Сохранить текущий' : 'Save current settings';
  String get activeConfig => _isRu ? 'Активен' : 'Active';
  String get configPresetBroken =>
      _isRu ? 'Файл не читается' : 'File cannot be read';
  String get removeConfigPreset =>
      _isRu ? 'Убрать из списка' : 'Remove from list';
  String get configPresetRemoved => _isRu
      ? 'Конфиг убран из списка. Файл на диске сохранён.'
      : 'Config was removed from the list. The file on disk is kept.';
  String get configPresetAlreadyPinned => _isRu
      ? 'Этот конфиг уже в списке.'
      : 'This config is already in the list.';

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
  String get pacmanBuildGroupTitle => 'PACMAN';
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

  String get toolchainCommonSection => _isRu ? 'Общие' : 'Common';
  String get toolchainCommonSectionHint => _isRu
      ? 'Нужны для сборки под любую платформу.'
      : 'Needed for every build target.';
  String get toolchainPlatformsSection => _isRu ? 'Платформы' : 'Platforms';
  String get toolchainPlatformsSectionHint => _isRu
      ? 'Дополнительные инструменты для конкретных форматов пакетов.'
      : 'Extra tools for specific package formats.';
  String get commonToolsGroupTitle => 'FLUTTER';
  String get commonToolsGroupSubtitle => _isRu
      ? 'Flutter SDK и системные утилиты, без которых не соберётся ни одна цель.'
      : 'Flutter SDK and system utilities that every build target relies on.';
  String get gitNote => _isRu
      ? 'Загружает и обновляет Flutter SDK.'
      : 'Downloads and updates the Flutter SDK.';
  String get archiveToolsName => _isRu
      ? 'Утилиты загрузки и распаковки'
      : 'Download and archive utilities';
  String get archiveToolsNote => _isRu
      ? 'Flutter использует их, чтобы скачать Dart SDK и артефакты движка.'
      : 'Flutter uses them to fetch the Dart SDK and engine artifacts.';
  String get requiresCommonTools => _isRu
      ? 'Также нужны общие инструменты — они установятся вместе с этой группой.'
      : 'Common tools are also required; they are installed along with this group.';
  String get installPreparing =>
      _isRu ? 'Подготовка установки…' : 'Preparing installation…';
  String get installStepSystemPackages =>
      _isRu ? 'Системные пакеты' : 'System packages';
  String get installStepFlutterSdk => 'Flutter SDK';
  String get installStepAndroidSdk => 'Android SDK';
  String get installStepAppImageTool => 'AppImageTool';
  String get installStepContainerRuntime =>
      _isRu ? 'Контейнерный runtime' : 'Container runtime';
  String get installStepBuilderImage =>
      _isRu ? 'Образ builder' : 'Builder image';
  String get installEstimatingTime =>
      _isRu ? 'Оцениваем время…' : 'Estimating time…';
  String get installCannotCancel => _isRu
      ? 'Этот шаг выполняет пакетный менеджер, его нельзя прервать безопасно.'
      : 'This step runs the package manager and cannot be interrupted safely.';

  String installOverallProgress(int progress) {
    return _isRu ? 'Установка: $progress%' : 'Installing: $progress%';
  }

  String installStepCounter(int current, int total) {
    return _isRu ? 'Шаг $current из $total' : 'Step $current of $total';
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

  String pacmanBuildNativeSubtitle(String distribution) {
    return _isRu
        ? 'Нативный пакет pacman (.pkg.tar.zst) через makepkg для $distribution.'
        : 'Native pacman package (.pkg.tar.zst) built with makepkg for $distribution.';
  }

  String pacmanBuildUnsupportedSubtitle(String distribution) {
    return _isRu
        ? 'Пакеты pacman собираются только на Arch-based системах, а это $distribution.'
        : 'pacman packages are built only on Arch-based hosts; this is $distribution.';
  }

  String get makepkgNote => _isRu
      ? 'Собирает пакет по PKGBUILD и записывает метаданные для pacman.'
      : 'Builds the package from a PKGBUILD and writes the metadata pacman needs.';
  String get fakerootNote => _isRu
      ? 'Нужен makepkg, чтобы упаковать файлы от root без sudo. Входит в base-devel.'
      : 'Lets makepkg package files as root without sudo. Part of base-devel.';
  String get hostPacmanCompatibilityToolName =>
      _isRu ? 'Совместимость pacman' : 'pacman compatibility';
  String get hostPacmanCompatibilityToolNote => _isRu
      ? 'Нужна Arch Linux или производная: Manjaro, EndeavourOS, CachyOS и т.п.'
      : 'Requires Arch Linux or a derivative such as Manjaro, EndeavourOS or CachyOS.';
  String get pacmanHostInstallUnsupported => _isRu
      ? 'Пакеты pacman можно собрать только на Arch-based системе.'
      : 'pacman packages can only be built on an Arch-based system.';
  String get tarGzTargetHint => _isRu
      ? 'Переносимый архив: распаковать и запустить, не пакет'
      : 'Portable archive to unpack and run, not a package';

  String get appImageBuildGroupSubtitle => _isRu
      ? 'Сборка переносимого AppImage для Linux.'
      : 'Build a portable AppImage for Linux.';
  String get tarGzBuildGroupSubtitle => _isRu
      ? 'Переносимый tar.gz архив с Linux release bundle: его распаковывают и запускают. Пакетные менеджеры (pacman, apt, dnf) его не устанавливают.'
      : 'Portable tar.gz archive with the Linux release bundle to unpack and run. Package managers (pacman, apt, dnf) cannot install it.';
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
  String get pacmanAdditionalDependenciesHelp => _isRu
      ? 'Одна зависимость на строку, имена пакетов Arch.'
      : 'One dependency per line, Arch package names.';
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
  String get buildInstallers => _isRu ? 'Собрать' : 'Build';
  String get runWithoutBuild => _isRu ? 'Запустить' : 'Run';
  String get runningApp => _isRu ? 'Приложение запущено' : 'App is running';
  String get stopRunningApp => _isRu ? 'Остановить' : 'Stop';
  String get sendToDevice =>
      _isRu ? 'Отправить на устройство' : 'Send to device';
  String get sendToDeviceHint => _isRu
      ? 'Собирает release APK и устанавливает его на подключенное Android-устройство.'
      : 'Builds a release APK and installs it on the connected Android device.';
  String get cancelSendToDevice => _isRu ? 'Отменить' : 'Cancel';
  String get adbMissing => _isRu
      ? 'adb не найден. Установите Android SDK во вкладке «Настройки».'
      : 'adb was not found. Install the Android SDK on the Settings tab.';
  String get androidDeviceSearchTitle =>
      _isRu ? 'Поиск устройства' : 'Looking for a device';
  String get androidDeviceMissingMessage => _isRu
      ? 'Подключите Android-устройство по USB и включите отладку по USB в параметрах разработчика.'
      : 'Connect an Android device over USB and enable USB debugging in the developer options.';
  String get androidDeviceUnauthorizedTitle =>
      _isRu ? 'Подтвердите отладку' : 'Confirm debugging';
  String androidDeviceUnauthorizedMessage(String device) {
    return _isRu
        ? 'Устройство $device подключено, но не авторизовано. На экране телефона появится запрос «Разрешить отладку по USB?» с отпечатком ключа — сверьте его и нажмите «Разрешить», затем повторите проверку.'
        : 'Device $device is connected but not authorized. The phone shows an "Allow USB debugging?" prompt with a key fingerprint — confirm it, then check again.';
  }

  String get retryDeviceCheck => _isRu ? 'Проверить снова' : 'Check again';
  String get chooseAndroidDeviceTitle =>
      _isRu ? 'Выберите устройство' : 'Choose a device';
  String get androidBuildingApk =>
      _isRu ? 'Сборка release APK...' : 'Building the release APK...';
  String androidInstallingApk(String device) {
    return _isRu ? 'Установка на $device...' : 'Installing on $device...';
  }

  String get androidApkMissing => _isRu
      ? 'APK не найден после сборки. Подробности — в техническом логе.'
      : 'The APK was not found after the build. See the technical log.';
  String get androidBuildFailed => _isRu
      ? 'Не удалось собрать APK. Подробности — в техническом логе.'
      : 'The APK build failed. See the technical log.';
  String androidInstallSucceeded(String device) {
    return _isRu
        ? 'APK установлен на $device.'
        : 'The APK was installed on $device.';
  }

  String get androidInstallFailed => _isRu
      ? 'Установка не удалась. Подробности — в техническом логе.'
      : 'The install failed. See the technical log.';
  String get androidSignatureConflictTitle =>
      _isRu ? 'Установлена другая сборка' : 'A different build is installed';
  String get androidSignatureConflictMessage => _isRu
      ? 'На устройстве уже стоит версия приложения, подписанная другим ключом. Обновить её поверх нельзя — старую нужно удалить, вместе с ней будут потеряны данные приложения.'
      : 'The device already has a version of the app signed with a different key. It cannot be updated in place — the old one must be removed, and the app data will be lost with it.';
  String get removeAndInstall =>
      _isRu ? 'Удалить и установить' : 'Uninstall and install';
  String get androidSendCancelled =>
      _isRu ? 'Отправка на устройство отменена.' : 'Send to device cancelled.';
  String get buildSuccessTitle =>
      _isRu ? 'Сборка завершена' : 'Build completed';
  String get buildSuccessMessage => _isRu
      ? 'Выбранные установщики успешно собраны и сохранены в папку экспорта.'
      : 'Selected installers were built successfully and saved to the output folder.';
  String get buildWarningsTitle =>
      _isRu ? 'Сборка не завершена' : 'Build did not finish';
  String get buildWarningsMessage => _isRu
      ? 'Сборка остановилась на одном из шагов. Подробности — в журнале процессов.'
      : 'The build stopped on one of the steps. See the process log for details.';
  String get ok => _isRu ? 'OK' : 'OK';
  String get buildPlanTitle => _isRu ? 'План сборки' : 'Build plan';
  String get buildCommandsTitle => _isRu ? 'Команды' : 'Commands';
  String get processLogTitle => _isRu ? 'Журнал процессов' : 'Process log';
  String get noBuildPlan => _isRu
      ? 'Выберите форматы установщиков на вкладке «Проект», чтобы увидеть план сборки.'
      : 'Select installer formats on the Project tab to see the build plan.';
  String get noBuildCommands => _isRu
      ? 'Выберите форматы установщиков, чтобы увидеть команды сборки.'
      : 'Select installer formats to preview build commands.';
  String get noStepCommands => _isRu
      ? 'У этого этапа нет отдельных команд.'
      : 'This step has no separate commands.';
  String get copyStepCommands =>
      _isRu ? 'Скопировать команды этапа' : 'Copy step commands';
  String get copyFullScript => _isRu ? 'Весь скрипт' : 'Full script';
  String get copyLog => _isRu ? 'Скопировать журнал' : 'Copy log';
  String get copiedToClipboard =>
      _isRu ? 'Скопировано в буфер обмена' : 'Copied to clipboard';
  String get selectProjectForCommands => _isRu
      ? 'Выберите Flutter-проект, чтобы PackFoundry подставил реальные пути и имена.'
      : 'Select a Flutter project so PackFoundry can resolve real paths and names.';
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
      'pacman' => 'PACMAN',
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
      'pacman' =>
        _isRu
            ? 'Генерация PKGBUILD и запуск makepkg.'
            : 'Generate a PKGBUILD and run makepkg.',
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
      'Preparing PKGBUILD and package metadata.' =>
        'Готовим PKGBUILD и метаданные пакета.',
      'Running makepkg.' => 'Запускаем makepkg.',
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
      'pacman' =>
        _isRu
            ? 'PackFoundry пишет PKGBUILD с метаданными, зависимостями, desktop-файлом и иконкой, затем makepkg собирает пакет .pkg.tar.zst с файлами .PKGINFO и .MTREE. Его ставят командой sudo pacman -U, приложение попадает в /opt и в меню.'
            : 'PackFoundry writes a PKGBUILD with metadata, dependencies, desktop file and icon, then makepkg builds a .pkg.tar.zst package with .PKGINFO and .MTREE. Install it with sudo pacman -U; the app goes to /opt and the app menu.',
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
      'pacman package' => 'pacman пакет',
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
