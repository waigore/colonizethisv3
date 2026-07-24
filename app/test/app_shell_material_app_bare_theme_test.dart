// Pins `buildAppShellMaterialApp(applyEditorialTheme: false)` bare chrome
// used by `ctRegionMapTestHarness` golden hosts (Refs #4035).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'positive: buildAppShellMaterialApp defaults to editorial theme',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShellMaterialApp(home: const Text('themed')),
      );
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme,
        isNotNull,
      );
    },
  );

  testWidgets('negative: applyEditorialTheme false omits MaterialApp.theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildAppShellMaterialApp(
        applyEditorialTheme: false,
        home: const Text('bare'),
      ),
    );
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).theme, isNull);
  });
}
