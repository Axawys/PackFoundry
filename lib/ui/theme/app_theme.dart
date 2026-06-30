import 'package:flutter/material.dart';

/// Semantic colors for build/tool status.
///
/// The interface itself is intentionally neutral (no accent hue): the only
/// colors in the UI come from this palette — green when something succeeds and
/// red when there is a problem. Everything else uses the neutral [ColorScheme].
@immutable
class StatusPalette extends ThemeExtension<StatusPalette> {
  const StatusPalette({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.problem,
    required this.problemContainer,
    required this.onProblemContainer,
  });

  /// Solid green, for icons and borders.
  final Color success;

  /// Soft green block background (e.g. status chips).
  final Color successContainer;

  /// Text/icon color drawn on [successContainer].
  final Color onSuccessContainer;

  /// Solid red, for icons and borders.
  final Color problem;

  /// Soft red block background (e.g. status chips).
  final Color problemContainer;

  /// Text/icon color drawn on [problemContainer].
  final Color onProblemContainer;

  static const StatusPalette light = StatusPalette(
    success: Color(0xFF16A34A),
    successContainer: Color(0xFFDCFCE7),
    onSuccessContainer: Color(0xFF166534),
    problem: Color(0xFFDC2626),
    problemContainer: Color(0xFFFEE2E2),
    onProblemContainer: Color(0xFF991B1B),
  );

  static const StatusPalette dark = StatusPalette(
    success: Color(0xFF4ADE80),
    successContainer: Color(0xFF14361F),
    onSuccessContainer: Color(0xFFBBF7D0),
    problem: Color(0xFFF87171),
    problemContainer: Color(0xFF3F1A1A),
    onProblemContainer: Color(0xFFFECACA),
  );

  @override
  StatusPalette copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? problem,
    Color? problemContainer,
    Color? onProblemContainer,
  }) {
    return StatusPalette(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      problem: problem ?? this.problem,
      problemContainer: problemContainer ?? this.problemContainer,
      onProblemContainer: onProblemContainer ?? this.onProblemContainer,
    );
  }

  @override
  StatusPalette lerp(ThemeExtension<StatusPalette>? other, double t) {
    if (other is! StatusPalette) {
      return this;
    }
    return StatusPalette(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      problem: Color.lerp(problem, other.problem, t)!,
      problemContainer: Color.lerp(problemContainer, other.problemContainer, t)!,
      onProblemContainer:
          Color.lerp(onProblemContainer, other.onProblemContainer, t)!,
    );
  }
}

extension StatusPaletteContext on BuildContext {
  /// Semantic success/problem colors for the current theme.
  ///
  /// Falls back to the brightness-appropriate default if the extension was not
  /// registered on the theme (e.g. a bare [MaterialApp] in a widget test).
  StatusPalette get status {
    final theme = Theme.of(this);
    return theme.extension<StatusPalette>() ??
        (theme.brightness == Brightness.dark
            ? StatusPalette.dark
            : StatusPalette.light);
  }
}

/// Builds the application [ThemeData].
///
/// Surfaces are kept neutral grey in both light and dark themes — no hue tint
/// (in particular, no dark-green background in dark mode) — by deriving the
/// scheme with [DynamicSchemeVariant.monochrome] from a neutral seed.
ThemeData buildAppTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6B6B6B),
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
  ).copyWith(
    // Keep elevated surfaces flat — no primary tint bleeding into cards.
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
    extensions: <ThemeExtension<dynamic>>[
      brightness == Brightness.dark ? StatusPalette.dark : StatusPalette.light,
    ],
  );
}
