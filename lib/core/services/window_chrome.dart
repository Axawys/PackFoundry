import 'dart:io';

import 'package:flutter/services.dart';

/// Bridges the in-app light/dark theme to the native window decorations.
///
/// On Linux the GTK header bar / title bar does not follow Flutter's theme on
/// its own, so we ask the native runner to switch its dark variant whenever the
/// effective brightness changes. No-op on other platforms.
class WindowChrome {
  WindowChrome._();

  static const MethodChannel _channel = MethodChannel('packfoundry/window');

  /// Requests that the native title bar use its dark ([dark] = true) or light
  /// variant. Best-effort: failures are ignored.
  static Future<void> setDarkTitleBar(bool dark) async {
    if (!Platform.isLinux) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setDarkTitleBar', dark);
    } on MissingPluginException {
      // Native handler unavailable (e.g. running under flutter test).
    } on PlatformException {
      // Title bar theming is best-effort; ignore platform-side failures.
    }
  }
}
