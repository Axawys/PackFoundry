<p align="center">
  <img src="assets/icon.png" alt="PackFoundry" width="160">
</p>

<h1 align="center">PackFoundry</h1>

<p align="center">
  Собирайте установщики Flutter-приложений для Linux и Windows в пару кликов.
</p>

PackFoundry — GUI-приложение на Flutter для упаковки Flutter-проектов в готовые установщики и переносимые архивы без ручной рутины в терминале.

Идея простая: выбрать папку проекта, заполнить метаданные релиза, отметить нужные форматы, выбрать папку экспорта и нажать Build. PackFoundry проверяет окружение, показывает доступные варианты сборки, создаёт временную копию проекта, запускает нужные инструменты и ведёт наглядный roadmap процесса.

## Главное

- Linux AppImage, `.deb`, `.rpm` и `tar.gz` из одного интерфейса.
- Windows `.exe` через переносимый Windows build kit: PackFoundry создаёт zip, а внутри Windows запускается готовый PowerShell-скрипт.
- Managed builders для сборки пакетов не под текущий дистрибутив: тяжёлое окружение создаётся один раз и переиспользуется.
- Настройки инструментов по форматам: RPM, DEB, AppImage, tar.gz и EXE показывают, чего не хватает для сборки.
- Пошаговый roadmap сборки с прогрессом, раскрываемыми этапами, логами и примерным оставшимся временем.
- Русская и английская локализация, светлая/тёмная/системная тема.

## Как это выглядит для пользователя

1. Открыть PackFoundry.
2. Выбрать папку Flutter-проекта.
3. Указать иконку, размер окна и метаданные релиза.
4. В разделе «Установщики» выбрать нужные форматы, имя выходного пакета и папку экспорта.
5. Нажать Build.
6. Получить готовые артефакты в выбранной папке.

PackFoundry работает с временной копией проекта. Настройки вроде размера окна применяются только к этой копии, исходники выбранного приложения не меняются.

## Рабочие пространства

### Настройки

Диагностика и установка инструментов сборки. Блоки разделены по форматам:

- RPM — host-сборка на Fedora/RHEL-like системах или управляемый Fedora builder для будущей cross-distro сборки.
- DEB — нативная сборка на Debian/Ubuntu-like системах или управляемый Debian builder на других Linux-дистрибутивах.
- AppImage — Flutter/Linux toolchain и AppImageTool.
- TAR.GZ — Flutter/Linux toolchain и системный `tar`.
- EXE — инструменты для создания Windows build kit zip.

Ниже находится панель установок интерфейса: тема и язык.

### Проект

Выбор Flutter-проекта и настройка будущих пакетов:

- каталог проекта и полезные проверки: `pubspec.yaml`, Linux/Windows runners, версия, описание;
- размер окна, иконка `.png` или `.svg`;
- тег релиза, почта разработчика, издатель, сайт проекта, лицензия и описание пакета;
- выбор форматов установщиков;
- имя выходного пакета;
- папка экспорта.

### Сборка

Запуск сборки и наблюдение за процессом:

- кнопка Build;
- общий прогресс и примерное оставшееся время;
- интерактивный roadmap этапов;
- технический лог.

## Поддерживаемые артефакты

| Платформа | Формат | Статус |
| --- | --- | --- |
| Linux | AppImage | Работает |
| Linux | `.deb` | Работает: нативно на DEB-based или через Debian builder |
| Linux | `.rpm` | Работает на Fedora/RHEL-like host-системах |
| Linux | `tar.gz` | Работает |
| Windows | Inno Setup `.exe` | Работает через Windows build kit zip |
| Android | APK/AAB | Запланировано |
| macOS | `.dmg` | Запланировано |
| iOS | `.ipa` | Запланировано |

## Как работает Linux-сборка

PackFoundry создаёт временную копию проекта, применяет build-only настройки и собирает Linux release bundle.

- AppImage собирается из Linux bundle через `appimagetool`.
- RPM собирается через `rpmbuild`, spec-файл генерируется автоматически.
- DEB собирается через `dpkg-deb`; на не-DEB системах используется управляемый Debian builder с Flutter SDK и зависимостями внутри контейнера.
- `tar.gz` — переносимый архив Linux release bundle.

Метаданные из панели проекта попадают в пакеты: версия, maintainer/email, license, homepage, description и publisher там, где формат это поддерживает.

## Как работает Windows build kit

Прямая сборка Windows runner на Linux невозможна без полноценного Windows toolchain. Поэтому PackFoundry делает переносимый zip-набор:

```text
*_windows_build_kit.zip
```

Внутри:

- копия Flutter-проекта;
- `scripts/build_windows.ps1`;
- `inno/setup.iss`;
- выбранная иконка;
- короткая инструкция.

Пользователь переносит zip в Windows 10/11 или Windows VM, распаковывает и запускает:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\build_windows.ps1
```

Скрипт сам проверяет и при необходимости устанавливает Git, Flutter SDK, Visual Studio Build Tools и Inno Setup, включает/проверяет Developer Mode, собирает `flutter build windows --release` и создаёт `.exe` установщик в папке `output`.

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
    models/       # модели и состояние сборки
    services/     # сервисы сборки, упаковки и диагностики инструментов
  l10n/           # локализация
  ui/
    pages/        # страницы приложения
    widgets/      # UI-компоненты
```

## Лицензия

PackFoundry распространяется под лицензией GNU General Public License version 2.0 only.

См. файл [LICENSE](LICENSE).
