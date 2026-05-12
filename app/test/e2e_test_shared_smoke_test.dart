import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
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
}
