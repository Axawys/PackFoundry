# PackFoundry

PackFoundry is a Linux-first Flutter desktop application for preparing release builds and installers for Flutter projects.

The goal is to replace repetitive release chores with a guided workspace:

- choose a Flutter project folder;
- inspect available SDKs and packaging tools;
- suggest tools that can be installed to unlock more targets;
- configure app name, icon and window defaults;
- select installer formats;
- run the build pipeline with clear progress, logs and recovery hints.

## Current Prototype

The app currently includes a working Flutter UI prototype with:

- project selection placeholder;
- application metadata fields;
- installable target checklist;
- toolchain status overview;
- simulated build progress and log output.

## Planned Build Targets

Initial Linux-hosted targets:

- Linux AppImage;
- Linux deb;
- Linux rpm;
- Linux tar.gz bundle;
- Android APK/AAB when Android SDK is available;
- Windows Inno Setup installer through Docker/Wine where practical.

Longer-term targets may use native or remote builders for macOS, iOS and Windows-specific packaging.

## Development

```sh
flutter analyze
flutter test
flutter run -d linux
```
