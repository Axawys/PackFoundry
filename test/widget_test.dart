import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pack_foundry/main.dart';

void main() {
  testWidgets('shows the PackFoundry build workspace', (tester) async {
    await tester.pumpWidget(const PackFoundryApp());

    expect(find.text('PackFoundry'), findsOneWidget);
    expect(find.text('Project'), findsOneWidget);
    expect(find.text('Application settings'), findsOneWidget);
    expect(find.text('Installers'), findsOneWidget);
    expect(find.text('Toolchain'), findsOneWidget);
    expect(find.text('Output folder'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Build installers'),
      findsOneWidget,
    );
  });
}
