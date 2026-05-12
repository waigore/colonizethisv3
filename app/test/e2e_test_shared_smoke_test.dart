import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();
  test('e2eAdaptivePollRampAfterIdle ramps under 100ms then caps', () {
    expect(e2eAdaptivePollRampAfterIdle(25), 50);
    expect(e2eAdaptivePollRampAfterIdle(75), 100);
    expect(e2eAdaptivePollRampAfterIdle(100), 100);
  });

  testWidgets('e2ePumpUntil succeeds when condition is already true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
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

  testWidgets('e2eCloseBottomSheet no-ops when no bottom sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await e2eCloseBottomSheet(tester);
  });

  testWidgets('e2eDismissTransientUi no-ops on empty scaffold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await e2eDismissTransientUi(tester);
  });

  testWidgets(
    'e2ePumpUntilFinderEmpty short-circuits when finder already empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final sw = Stopwatch()..start();
      await e2ePumpUntilFinderEmpty(
        tester,
        find.byType(ExpansionTile),
        timeout: const Duration(seconds: 5),
      );
      expect(
        sw.elapsed < const Duration(milliseconds: 200),
        isTrue,
        reason:
            'Already-empty finder must short-circuit before the timeout cap, '
            'so dismiss-style adaptive callers do not pay for a fixed wait.',
      );
    },
  );
}
