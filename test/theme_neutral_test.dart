import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pack_foundry/ui/theme/app_theme.dart';

void main() {
  // The UI must stay neutral: no accent hue on surfaces or primary (in
  // particular, no dark-green/teal background in dark mode). Only the
  // StatusPalette is allowed to carry color.
  for (final brightness in Brightness.values) {
    test('$brightness scheme is neutral grey (no hue tint)', () {
      final scheme = buildAppTheme(brightness).colorScheme;
      final neutralRoles = <Color>[
        scheme.surface,
        scheme.surfaceContainerLow,
        scheme.surfaceContainerHighest,
        scheme.primary,
        scheme.primaryContainer,
        scheme.secondary,
      ];
      for (final color in neutralRoles) {
        final saturation = HSLColor.fromColor(color).saturation;
        expect(
          saturation,
          lessThan(0.06),
          reason: '$color is not neutral (saturation=$saturation)',
        );
      }
    });
  }
}
