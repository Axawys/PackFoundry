import 'dart:io';

/// Finds the Flutter SDK executable.
///
/// Apps started from a desktop menu do not inherit the PATH that shell
/// profiles set up, so `flutter` resolved by name through `/bin/sh` fails with
/// "command not found" even when the SDK is installed. Resolving the file up
/// front and running it directly avoids that.
class FlutterLocator {
  FlutterLocator({Map<String, String>? environment})
    : _environment = environment ?? Platform.environment;

  final Map<String, String> _environment;

  /// The SDK PackFoundry installs from the toolchain tab.
  File get managedExecutable =>
      File('${_userDataDirectory()}/pack_foundry/flutter/bin/flutter');

  /// Looks in PATH, then FLUTTER_ROOT, then the usual install folders and
  /// finally the SDK managed by PackFoundry.
  File? find() {
    for (final candidate in _candidates()) {
      if (candidate.existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  /// Environment overrides for a child process run with [flutter]: its `bin`
  /// folder goes first on PATH, because Gradle and other tools started by the
  /// flutter tool call `flutter` and `dart` by name.
  Map<String, String> environmentFor(File flutter) {
    final path = _environment['PATH'];
    return {
      'PATH': path == null || path.isEmpty
          ? flutter.parent.path
          : '${flutter.parent.path}:$path',
    };
  }

  Iterable<File> _candidates() sync* {
    final path = _environment['PATH'];
    if (path != null) {
      for (final directory in path.split(':')) {
        if (directory.isNotEmpty) {
          yield File('$directory/flutter');
        }
      }
    }

    final flutterRoot = _environment['FLUTTER_ROOT'];
    if (flutterRoot != null && flutterRoot.isNotEmpty) {
      yield File('$flutterRoot/bin/flutter');
    }

    final home = _environment['HOME'];
    if (home != null && home.isNotEmpty) {
      for (final folder in const [
        'flutter',
        'development/flutter',
        'dev/flutter',
        'sdk/flutter',
        'sdks/flutter',
        '.local/flutter',
        'fvm/default',
        'snap/flutter/common/flutter',
      ]) {
        yield File('$home/$folder/bin/flutter');
      }
    }
    for (final folder in const [
      '/opt/flutter',
      '/usr/lib/flutter',
      '/usr/local/flutter',
      '/usr/local/lib/flutter',
    ]) {
      yield File('$folder/bin/flutter');
    }

    yield managedExecutable;
  }

  String _userDataDirectory() {
    final xdgDataHome = _environment['XDG_DATA_HOME'];
    if (xdgDataHome != null && xdgDataHome.isNotEmpty) {
      return xdgDataHome;
    }
    final home = _environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return '$home/.local/share';
    }
    return Directory.systemTemp.path;
  }
}
