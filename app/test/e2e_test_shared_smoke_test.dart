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

  test('e2eNextIdlePollStepMs doubles until max cap', () {
    expect(e2eNextIdlePollStepMs(25), 50);
    expect(e2eNextIdlePollStepMs(250), 500);
    expect(e2eNextIdlePollStepMs(500), 500);
  });

  testWidgets('e2ePumpUntilFinderEmpty returns immediately when finder empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final sw = Stopwatch()..start();
    await e2ePumpUntilFinderEmpty(
      tester,
      find.byType(SnackBar),
      timeout: const Duration(seconds: 2),
    );
    expect(sw.elapsed, lessThan(const Duration(milliseconds: 50)));
  });

  testWidgets('e2eCollectTextPreorder walks subtree in preorder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('alpha'),
              Row(children: [Text('beta')]),
            ],
          ),
        ),
      ),
    );
    final root = tester.element(find.byType(Column));
    final lines = <String>[];
    e2eCollectTextPreorder(root, lines);
    expect(lines, ['alpha', 'beta']);
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

  testWidgets('e2ePumpFor completes (zero and non-zero virtual time)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await e2ePumpFor(tester, Duration.zero);
    await e2ePumpFor(tester, const Duration(milliseconds: 80));
    expect(find.byType(SizedBox), findsOneWidget);
  });

  test('E2ePerfLog bumpCounter and timing are safe to call', () {
    final log = E2ePerfLog('smoke');
    log.bumpCounter('a');
    log.bumpCounter('a', by: 2);
    log.timing('p', const Duration(milliseconds: 12));
  });
}
