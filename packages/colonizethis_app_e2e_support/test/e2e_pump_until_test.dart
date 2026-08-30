/// Pins the **pre-pump short-circuit**, **adaptive backoff polling**, and
/// **timeout branches** of the `e2ePumpUntil` family
/// (`e2ePumpUntil` strict and `e2ePumpUntilConditionOrIdle` best-effort)
/// in `app/integration_test/e2e_test_shared.dart` (Refs GitHub #2336 AC5 /
/// `SPEC/program/e2e-integration-tests.md` § Adaptive poll pacing).
///
/// `e2ePumpUntil` is the canonical strict "pump until predicate true,
/// otherwise `fail()`" primitive used by `e2eSplitHomeFleetOnce`
/// (`app/integration_test/e2e_test_shared_panels.dart`) for split-dialog
/// confirmation, while `e2ePumpUntilConditionOrIdle` is the best-effort
/// variant relied on across the shared panel openers
/// (`e2eOpenCivilianPanel`, `e2eOpenNavalPanel`, `e2eOpenProductionPanel`,
/// `e2eCloseBottomSheet`, ...). The existing
/// `e2e_test_shared_smoke_test.dart` pins only the immediate-success and
/// flip-during-pump paths; the **timeout fail-fast** path of
/// `e2ePumpUntil` and the **perf-log/phaseName** acceptance smokes have
/// no direct widget-test coverage, so a silent regression in either
/// (for example a swap from `fail(...)` to a silent `return`, or a perf-log
/// arg signature break) would only surface as a confusing E2E flake or
/// timing regression on the wall-clock-bound paths #2336 is reducing.
///
/// Because the `integration_test/` suite runs behind a no-op
/// `app_e2e_linux` lane today (`SPEC/program/e2e-integration-tests.md`
/// § CI), the behavioral pins live in the widget-test layer and use a
/// fake-async `Timer` flip plus an explicit call counter so the helper's
/// `tester.pump` loop drives the condition without the test pumping
/// itself.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/delayed_condition_host_harness.dart';
import 'support/e2e_widget_pump_harness.dart';
import 'support/e2e_pump_until_guard_group.dart';

void main() {
  suppressLogsForTests();

  group('e2ePumpUntil (strict)', () {
    testWidgets(
      'short-circuits before any pump when condition is already true',
      (WidgetTester tester) async {
        await pumpE2eEmptyApp(tester);
        var calls = 0;
        final sw = Stopwatch()..start();
        await e2ePumpUntil(tester, () {
          calls++;
          return true;
        }, timeout: const Duration(seconds: 5));
        expect(
          calls,
          1,
          reason:
              'Strict variant must evaluate the predicate exactly once on '
              'the entry short-circuit; extra evaluations imply a wasted '
              'pump cycle the wall-clock-bound paths cannot afford '
              '(#2336 AC5).',
        );
        expect(
          sw.elapsed,
          lessThan(const Duration(milliseconds: 200)),
          reason:
              'Pre-pump short-circuit must return well before the timeout '
              'cap when the predicate is already true on entry.',
        );
      },
    );

    testWidgets(
      'returns once a scheduled flip makes the condition true during pump',
      (WidgetTester tester) async {
        final state = await pumpDelayedConditionHost(
          tester,
          flipAfter: const Duration(milliseconds: 80),
        );
        expect(state.ready, isFalse);

        await e2ePumpUntil(
          tester,
          () => state.ready,
          timeout: const Duration(seconds: 5),
        );

        expect(
          state.ready,
          isTrue,
          reason:
              'The predicate must be observed true at return time — that is '
              'the exact condition the adaptive pump loop waits on for the '
              'split-dialog confirmation path in '
              '`e2eSplitHomeFleetOnce`.',
        );
      },
    );

    testWidgets(
      'fails with TestFailure when condition never becomes true within timeout',
      (WidgetTester tester) async {
        await pumpE2eEmptyApp(tester);
        Object? caught;
        try {
          await e2ePumpUntil(
            tester,
            () => false,
            timeout: const Duration(milliseconds: 200),
            phaseName: 'pin_pump_until_timeout',
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'Strict variant must hit the timeout failure path so '
              'persistent false predicates do not silently no-op and leak '
              'into later test steps (#2336 AC10).',
        );
        final message = caught.toString();
        expect(
          message,
          contains('Timed out'),
          reason:
              'Failure message must call out the timeout so the helper '
              'failure is attributable in CI logs.',
        );
        expect(
          message,
          contains('e2ePumpUntil'),
          reason:
              'Failure message must include the helper name so the '
              'failure is unambiguously attributed to '
              '`e2ePumpUntil` (and not the sibling `e2eWaitUntilFound`).',
        );
        expect(
          message,
          contains('pin_pump_until_timeout'),
          reason:
              'Failure message must include the caller-supplied `phaseName` '
              'so callers can identify which call site timed out.',
        );
      },
    );

    testWidgets(
      'accepts a custom phaseName and E2ePerfLog on the success path',
      (WidgetTester tester) async {
        await pumpE2eEmptyApp(tester);
        final perf = E2ePerfLog('e2e_pump_until_test');
        await e2ePumpUntil(
          tester,
          () => true,
          timeout: const Duration(seconds: 2),
          perf: perf,
          phaseName: 'pin_pump_until_perf_phase',
        );
        // Smoke-only: the helper must not throw when handed an E2ePerfLog +
        // explicit phaseName, so scenario-level callers can keep emitting
        // E2E_COUNTER / E2E_TIMING markers without paying a regression here.
      },
    );

    testWidgets(
      'accepts a custom phaseName and E2ePerfLog on the timeout path',
      (WidgetTester tester) async {
        await pumpE2eEmptyApp(tester);
        final perf = E2ePerfLog('e2e_pump_until_test');
        Object? caught;
        try {
          await e2ePumpUntil(
            tester,
            () => false,
            timeout: const Duration(milliseconds: 100),
            perf: perf,
            phaseName: 'pin_pump_until_perf_timeout',
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
      },
    );
  });

  registerE2ePumpUntilGuardGroup();
}
