/// Pins the **pre-pump short-circuit**, **adaptive backoff polling**, and
/// **`diagnoseAfter` settle pump** contracts of `e2eWaitUntilFound`
/// (Refs GitHub #2336 AC2 / AC5 /
/// `SPEC/program/e2e-integration-tests.md` § Adaptive poll pacing).
///
/// `e2eWaitUntilFound` is the canonical "wait until a finder becomes
/// non-empty" primitive that the rest of the E2E shared helpers
/// (`e2eWaitForNewGameEntry`, `e2eOpenProductionPanel`,
/// `e2eSplitHomeFleetOnce`, ...) depend on, but it had no direct
/// behavioral contract test — only indirect coverage through the
/// scenario-level pins. Any silent regression in its three branches
/// (entry short-circuit, adaptive pump loop, timeout failure path with
/// optional diagnostic settle) would slip through the existing widget
/// tests and only surface as a confusing E2E timing/flake regression
/// in the wall-clock-bound paths #2336 is reducing.
///
/// Because the `integration_test/` suite runs behind a no-op
/// `app_e2e_linux` lane today (`SPEC/program/e2e-integration-tests.md`
/// § CI), the behavioral pins live in the widget-test layer and use
/// fake-async `Timer` flips so the helper's `tester.pump` loop
/// observes the mounted finders without the test driving extra pumps
/// itself.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/delayed_mount_harness.dart';

Future<void> _pumpHost(
  WidgetTester tester, {
  required Key targetKey,
  Duration? mountAfter,
  bool startMounted = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: DelayedMountHost(
            mountAfter: mountAfter,
            startMounted: startMounted,
            child: TextButton(
              key: targetKey,
              onPressed: () {},
              child: const Text('btn'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'short-circuits before any pump when finder is already non-empty',
    (WidgetTester tester) async {
      const targetKey = Key('e2e_present_btn');
      await _pumpHost(tester, targetKey: targetKey, startMounted: true);
      expect(find.byKey(targetKey), findsOneWidget);

      final sw = Stopwatch()..start();
      await e2eWaitUntilFound(
        tester,
        find.byKey(targetKey),
        timeout: const Duration(seconds: 5),
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'Pre-pump short-circuit must return well before the timeout cap '
            'when the finder is already non-empty on entry; this keeps the '
            'caller from paying any adaptive pump time (#2336 AC5).',
      );
    },
  );

  testWidgets(
    'returns once a scheduled mount makes the finder non-empty during pump',
    (WidgetTester tester) async {
      const targetKey = Key('e2e_late_btn');
      await _pumpHost(
        tester,
        targetKey: targetKey,
        mountAfter: const Duration(milliseconds: 80),
      );
      expect(find.byKey(targetKey), findsNothing);

      await e2eWaitUntilFound(
        tester,
        find.byKey(targetKey),
        timeout: const Duration(seconds: 5),
      );

      expect(
        find.byKey(targetKey),
        findsOneWidget,
        reason:
            'The target finder must be non-empty at return time — that is '
            'the exact condition the adaptive pump loop waits on.',
      );
    },
  );

  testWidgets(
    'fails with TestFailure when finder never becomes non-empty within timeout',
    (WidgetTester tester) async {
      const missingKey = Key('e2e_missing_btn');
      await _pumpHost(tester, targetKey: missingKey);
      Object? caught;
      try {
        await e2eWaitUntilFound(
          tester,
          find.byKey(missingKey),
          timeout: const Duration(milliseconds: 200),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Persistent absence must hit the timeout failure path so '
            'missing widgets do not silently no-op and leak into later '
            'test steps (#2336 AC10).',
      );
      expect(
        caught.toString(),
        contains('Timed out'),
        reason:
            'Failure message must call out the timeout so the helper '
            'failure is attributable in CI logs.',
      );
      expect(
        caught.toString(),
        contains('waiting for'),
        reason:
            'Failure message must include the finder for diagnostic '
            'attribution alongside the timeout marker.',
      );
    },
  );

  testWidgets(
    'diagnoseAfter parameter still fails on persistent absence without crashing',
    (WidgetTester tester) async {
      const missingKey = Key('e2e_diagnose_btn');
      await _pumpHost(tester, targetKey: missingKey);

      Object? caught;
      try {
        await e2eWaitUntilFound(
          tester,
          find.byKey(missingKey),
          timeout: const Duration(milliseconds: 100),
          diagnoseAfter: const Duration(milliseconds: 300),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'diagnoseAfter must not swallow the timeout failure — the helper '
            'still has to fail so callers see the wait did not succeed '
            'even when a post-timeout diagnostic settle pump is requested.',
      );
      expect(
        caught.toString(),
        contains('Last exception'),
        reason:
            'The failure message must surface `tester.takeException()` under '
            '`Last exception:` so the diagnostic settle pump can attribute '
            'any late uncaught exceptions to the timed-out wait (#2336 AC10).',
      );
    },
  );

  testWidgets(
    'accepts a custom phaseName and E2ePerfLog on the short-circuit path',
    (WidgetTester tester) async {
      const targetKey = Key('e2e_perf_btn');
      await _pumpHost(tester, targetKey: targetKey, startMounted: true);
      final perf = E2ePerfLog('e2e_wait_until_found_test');
      await e2eWaitUntilFound(
        tester,
        find.byKey(targetKey),
        timeout: const Duration(seconds: 2),
        perf: perf,
        phaseName: 'pin_wait_until_found_perf_phase',
      );
      // Smoke-only: the helper must not throw when handed an E2ePerfLog +
      // explicit phaseName, so scenario-level callers can keep emitting
      // E2E_COUNTER / E2E_TIMING markers without paying a regression here.
    },
  );

  testWidgets('accepts a custom phaseName and E2ePerfLog on the timeout path', (
    WidgetTester tester,
  ) async {
    const missingKey = Key('e2e_perf_timeout_btn');
    await _pumpHost(tester, targetKey: missingKey);
    final perf = E2ePerfLog('e2e_wait_until_found_test');
    Object? caught;
    try {
      await e2eWaitUntilFound(
        tester,
        find.byKey(missingKey),
        timeout: const Duration(milliseconds: 100),
        perf: perf,
        phaseName: 'pin_wait_until_found_perf_timeout',
      );
    } catch (e) {
      caught = e;
    }
    expect(
      caught,
      isA<TestFailure>(),
      reason:
          'Passing a perf log on the timeout path must not suppress the '
          'fail() invocation; perf is observability metadata only.',
    );
  });
}
