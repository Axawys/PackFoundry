import 'dart:io';

/// Tells which Flutter platforms a project has been created for.
///
/// Building a platform the project lacks fails deep inside the flutter tool,
/// e.g. `flutter build apk` without `android/` reports that it cannot read
/// `android/app/build.gradle`, so targets are checked up front instead.
class ProjectPlatforms {
  const ProjectPlatforms._();

  /// The project folder a platform lives in, or null when PackFoundry does
  /// not need one for that platform.
  static String? folderFor(String platform) {
    return switch (platform) {
      'Linux' => 'linux',
      'Android' => 'android',
      'Windows' => 'windows',
      _ => null,
    };
  }

  static bool supports(String projectPath, String platform) {
    return switch (platform) {
      'Linux' => File('$projectPath/linux/CMakeLists.txt').existsSync(),
      'Windows' => File('$projectPath/windows/CMakeLists.txt').existsSync(),
      'Android' =>
        File('$projectPath/android/app/build.gradle').existsSync() ||
            File('$projectPath/android/app/build.gradle.kts').existsSync(),
      _ => true,
    };
  }
}
