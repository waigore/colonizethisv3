// Smoke pins for combat_ui_specs_test_support (Refs #4013).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'combat_ui_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('combatUiSpecsFrame / darkFrame host a child', (tester) async {
    await tester.pumpWidget(combatUiSpecsFrame(const Text('light-frame')));
    expect(find.text('light-frame'), findsOneWidget);

    await tester.pumpWidget(combatUiSpecsDarkFrame(const Text('dark-frame')));
    expect(find.text('dark-frame'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme, AppThemes.editorialMonocle);
  });
}
