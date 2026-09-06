// e2ePumpUntil / condition-or-idle smoke pins (#2336 AC5, #4734 Slice J).
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets('e2ePumpUntil succeeds when condition is already true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildAppShellMaterialApp(applyEditorialTheme: false, home: SizedBox()),
    );
    var calls = 0;
    await e2ePumpUntil(
      tester,
      () {
        calls++;
        return true;
      },
      timeout: const Duration(seconds: 1),
      phaseName: 'smoke_immediate',
    );
    expect(calls, 1);
  });

  testWidgets('e2ePumpUntilConditionOrIdle succeeds before first pump', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildAppShellMaterialApp(applyEditorialTheme: false, home: SizedBox()),
    );
    final met = await e2ePumpUntilConditionOrIdle(
      tester,
      () => true,
      timeout: const Duration(seconds: 1),
      phaseName: 'smoke_condition_idle_immediate',
    );
    expect(met, isTrue);
  });

  testWidgets(
    'e2ePumpUntilConditionOrIdle returns false when timeout elapses',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShellMaterialApp(applyEditorialTheme: false, home: SizedBox()),
      );
      final met = await e2ePumpUntilConditionOrIdle(
        tester,
        () => false,
        timeout: const Duration(milliseconds: 60),
        phaseName: 'smoke_condition_idle_timeout',
      );
      expect(met, isFalse);
    },
  );

  testWidgets(
    'e2ePumpUntilConditionOrIdle returns true immediately when condition is already true',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShellMaterialApp(applyEditorialTheme: false, home: SizedBox()),
      );
      final sw = Stopwatch()..start();
      final result = await e2ePumpUntilConditionOrIdle(
        tester,
        () => true,
        timeout: const Duration(seconds: 5),
      );
      expect(result, isTrue);
      expect(sw.elapsed < const Duration(milliseconds: 200), isTrue);
    },
  );

  testWidgets(
    'e2ePumpUntilConditionOrIdle returns false on timeout without throwing',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShellMaterialApp(applyEditorialTheme: false, home: SizedBox()),
      );
      final result = await e2ePumpUntilConditionOrIdle(
        tester,
        () => false,
        timeout: const Duration(milliseconds: 150),
      );
      expect(result, isFalse);
    },
  );

  testWidgets(
    'e2ePumpUntilConditionOrIdle returns true once condition flips during pump',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShellMaterialApp(applyEditorialTheme: false, home: SizedBox()),
      );
      var pumps = 0;
      final result = await e2ePumpUntilConditionOrIdle(tester, () {
        pumps++;
        return pumps >= 3;
      }, timeout: const Duration(seconds: 2));
      expect(result, isTrue);
      expect(pumps >= 3, isTrue);
    },
  );

  testWidgets(
    'e2ePumpUntilFinderEmpty short-circuits when finder already empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShellMaterialApp(applyEditorialTheme: false, home: SizedBox()),
      );
      final sw = Stopwatch()..start();
      await e2ePumpUntilFinderEmpty(
        tester,
        find.byType(ExpansionTile),
        timeout: const Duration(seconds: 5),
      );
      expect(sw.elapsed < const Duration(milliseconds: 200), isTrue);
    },
  );
}
