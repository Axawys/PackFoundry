<p align="center">
  <img src="assets/icon.png" alt="PackFoundry" width="160">
</p>

<h1 align="center">PackFoundry</h1>

<p align="center">
  Сборка установщиков Flutter-приложений для Linux, Android и Windows в несколько кликов.
</p>

PackFoundry — GUI-приложение на Flutter, которое помогает упаковывать Flutter-проекты в готовые пакеты без ручной рутины с `flutter build`, Docker/Podman, `rpmbuild`, `dpkg-deb`, AppImageTool, Android SDK и Windows/Inno Setup.

Главная идея: выбрать проект, указать метаданные релиза, отметить нужные форматы и нажать Build. PackFoundry проверяет окружение, готовит временную копию проекта, собирает пакеты, показывает наглядный roadmap и сохраняет артефакты в выбранную папку.

## Возможности

- Сборка Linux-пакетов: AppImage, `.deb`, `.rpm`, `tar.gz`.
- Сборка Android APK через Flutter и локальный Android SDK.
- Windows build kit: переносимый zip с проектом, Inno Setup config и PowerShell-скриптом для сборки `.exe` на Windows.
- Управляемые container builders для сборки пакетов не под текущий дистрибутив: Debian builder для DEB, Fedora builder для RPM.
- Быстрый режим host-сборки для формата текущего Linux-дистрибутива.
- Установка и диагностика инструментов сборки прямо из настроек.
- Дополнительные зависимости пакетов: `Depends` для DEB и `Requires` для RPM.
- Интерактивный roadmap сборки: визуальный режим и режим команд.
- Кнопка запуска проекта без сборки для быстрой проверки.
- Инспектор готовых пакетов: метаданные, зависимости, иконка и дерево файлов внутри пакета.
- Редактирование metadata/control и зависимостей DEB-пакета с сохранением измененной копии.
- Конфигурационный файл `packfoundry.json` для повторяемых сборок.
- Русская и английская локализация, светлая/темная/системная тема.

## Поддерживаемые артефакты

| Платформа | Формат | Статус |
| --- | --- | --- |
| Linux | AppImage | Работает |
| Linux | `.deb` | Работает нативно на DEB-based системах или через Debian builder |
| Linux | `.rpm` | Работает нативно на Fedora/RHEL-like системах или через Fedora builder |
| Linux | `tar.gz` | Работает |
| Android | APK | Работает |
| Windows | Inno Setup `.exe` | Работает через Windows build kit |
| macOS | `.dmg` | Запланировано |
| iOS | `.ipa` | Запланировано |

## Рабочие пространства

### Настройки

Здесь PackFoundry показывает доступность инструментов и builders:

- RPM: host-инструменты или Fedora builder.
- DEB: host-инструменты или Debian builder.
- AppImage: Flutter/Linux toolchain и AppImageTool.
- TAR.GZ: Flutter/Linux toolchain и `tar`.
- EXE: создание Windows build kit.
- APK: Flutter, Android SDK и Java.

В этой же вкладке находятся настройки интерфейса: тема и язык.

### Проект

Здесь выбирается Flutter-проект и настраивается будущая сборка:

- папка проекта;
- импорт/экспорт `packfoundry.json`;
- размер окна Linux desktop-приложения;
- иконка `.png` или `.svg`;
- тег релиза, разработчик, email, сайт, лицензия и описание;
- имя выходного пакета;
- папка экспорта;
- форматы установщиков;
- дополнительные зависимости для DEB/RPM.

PackFoundry работает с временной копией проекта. Настройки вроде размера окна и иконки применяются к build workspace, исходный проект не переписывается.

### Сборка

Здесь запускается сборка и отображается процесс:

- Build — собрать выбранные пакеты.
- Run without build — запустить выбранный Flutter-проект для теста.
- Visual — roadmap блоками с прогрессом.
- Commands — список команд, которые соответствуют текущему плану сборки.
- Full/Simplified — подробный или укрупненный roadmap.
- Технический лог — подробности выполнения и ошибок.

### Пакеты

Инспектор готовых пакетов. Можно выбрать файл `.deb`, `.rpm`, `.AppImage`, `.tar.gz`, `.apk`, `.exe` или `.zip` и посмотреть:

- формат, имя, размер и путь;
- metadata/control;
- зависимости;
- иконку, если она найдена внутри пакета;
- дерево файлов внутри архива/пакета.

Для DEB доступно редактирование metadata/control и зависимостей с сохранением новой копии `*_edited.deb`. RPM и часть других форматов показываются в режиме просмотра: их корректнее менять через параметры сборки и пересборку.

## Примеры использования

### Пример 1: собрать AppImage и RPM на Fedora

1. Откройте PackFoundry.
2. Во вкладке «Настройки» убедитесь, что RPM host tools и AppImageTool доступны. Если нет — нажмите установку недостающих инструментов.
3. Во вкладке «Проект» выберите папку Flutter-проекта.
4. Укажите тег релиза, например `v1.3.0`, иконку и папку экспорта.
5. В «Установщиках» отметьте AppImage и RPM.
6. Нажмите Build во вкладке «Сборка».
7. В папке экспорта появятся `.AppImage` и `.rpm`.

### Пример 2: собрать DEB на Fedora через builder

1. Во вкладке «Настройки» установите DEB builder.
2. Во вкладке «Проект» выберите приложение и папку экспорта.
3. Отметьте `deb package`.
4. Если нужно, добавьте зависимость в DEB Depends, например:

```text
libgtk-3-0 | libgtk-3-0t64
```

5. Нажмите Build.
6. PackFoundry запустит Debian builder и сохранит `.deb` в папку экспорта.

### Пример 3: собрать Windows EXE через Windows build kit

1. На Linux выберите Flutter-проект и отметьте Windows / Inno Setup exe.
2. Нажмите Build.
3. В папке экспорта появится архив:

```text
*_windows_1.3.0_x64_build_kit.zip
```

4. Скопируйте архив в Windows 10/11 или Windows VM.
5. Распакуйте его и выполните в PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\build_windows.ps1
```

Скрипт проверит Flutter SDK, Visual Studio Build Tools, Inno Setup и Developer Mode. Готовый `.exe` появится в папке `output`.

### Пример 4: проверить готовый DEB-пакет

1. Откройте вкладку «Пакеты».
2. Нажмите «Выбрать пакет» и выберите `.deb`.
3. Посмотрите metadata, зависимости, иконку и дерево файлов.
4. При необходимости измените `Depends` или control metadata.
5. Нажмите «Сохранить измененную копию».

## Конфигурационный файл

PackFoundry умеет импортировать и экспортировать `packfoundry.json`. Это удобно, если вы хотите один раз описать проект, форматы пакетов и metadata, а потом менять только тег релиза.

Особое значение:

```text
$choose_in_packfoundry
```

означает, что путь будет выбран пользователем в интерфейсе.

Пример:

```json
{
  "schema": "packfoundry.config.v1",
  "projectPath": "$choose_in_packfoundry",
  "outputPath": "$choose_in_packfoundry",
  "iconPath": "assets/icon.png",
  "appName": "HashChecker",
  "releaseTag": "v1.3.0",
  "developerEmail": "dev@example.com",
  "publisherName": "Example Studio",
  "homepageUrl": "https://example.com/hashchecker",
  "license": "GPL-2.0-only",
  "description": "A desktop tool for checking file hashes.",
  "window": {
    "width": 1280,
    "height": 800
  },
  "packageTypes": [
    "appimage",
    "deb",
    "rpm",
    "tar.gz",
    "apk",
    "exe"
  ],
  "additionalDependencies": {
    "deb": "libgtk-3-0 | libgtk-3-0t64",
    "rpm": "webkit2gtk4.1"
  }
}
```

Поддерживаемые `packageTypes`: `appimage`, `deb`, `rpm`, `tar.gz`, `apk`, `exe`, `dmg`, `ipa`.

`additionalDependencies` добавляет зависимости к стандартному набору PackFoundry:

- `deb` записывается в `Depends`;
- `rpm` записывается в `Requires`.

## Имена выходных файлов

PackFoundry использует единый шаблон имен:

```text
AppName_platform_version_arch.ext
```

Примеры:

```text
HashChecker_linux_1.3.0_x64.AppImage
HashChecker_linux_1.3.0_x64.tar.gz
HashChecker_linux_1.3.0_x64.deb
HashChecker_linux_1.3.0-1_x64.rpm
HashChecker_android_1.3.0_universal.apk
HashChecker_windows_1.3.0_x64_build_kit.zip
```

## Как работает сборка

PackFoundry создает временную копию проекта, применяет build-only настройки и запускает нужный pipeline:

- AppImage собирается через Linux release bundle и AppImageTool.
- DEB собирается через `dpkg-deb`; на не-DEB системах используется Debian builder.
- RPM собирается через `rpmbuild`; на не-RPM системах используется Fedora builder.
- `tar.gz` упаковывает Linux release bundle.
- APK собирается через `flutter build apk --release`.
- Windows EXE собирается через переносимый build kit, который запускается на Windows.

Builders кэшируются и переиспользуются, поэтому первая установка может быть долгой, а последующие сборки идут заметно быстрее.

## Разработка

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d linux
```

## Структура проекта

```text
lib/
  core/
    models/       # модели сборки, конфигов, инструментов и инспектора пакетов
    services/     # сборка, builders, toolchain, config, package inspector
  l10n/           # локализация
  ui/
    pages/        # основные страницы приложения
    widgets/      # UI-компоненты
```

## Лицензия

PackFoundry распространяется под лицензией GNU General Public License version 2.0 only.

См. файл [LICENSE](LICENSE).
