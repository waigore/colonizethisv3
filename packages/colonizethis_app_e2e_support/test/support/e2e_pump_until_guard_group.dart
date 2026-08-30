// Extracted from e2e_pump_until_test.dart (#4598 Slice C).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'delayed_condition_host_harness.dart';
import 'e2e_widget_pump_harness.dart';

void registerE2ePumpUntilGuardGroup() {
  group('e2ePumpUntilConditionOrIdle (best-effort)', () {
    testWidgets(
      'returns true once a scheduled flip makes the condition true during pump',
      (WidgetTester tester) async {
        final state = await pumpDelayedConditionHost(
          tester,
          flipAfter: const Duration(milliseconds: 60),
        );
        expect(state.ready, isFalse);

        final met = await e2ePumpUntilConditionOrIdle(
          tester,
          () => state.ready,
          timeout: const Duration(seconds: 5),
        );

        expect(
          met,
          isTrue,
          reason:
              'Best-effort variant must return `true` when the condition '
              'flips during the adaptive pump loop so caller paths '
              '(panel-open settle, sheet-close settle) can short-circuit '
              'instead of paying the full timeout.',
        );
      },
    );

    testWidgets(
      'returns false without throwing when predicate is persistently false',
      (WidgetTester tester) async {
        await pumpE2eEmptyApp(tester);
        Object? caught;
        bool? met;
        try {
          met = await e2ePumpUntilConditionOrIdle(
            tester,
            () => false,
            timeout: const Duration(milliseconds: 150),
            phaseName: 'pin_pump_until_idle_timeout',
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'Best-effort variant must NOT call fail() on timeout so '
              'callers can treat the wait as an optional post-tap settle '
              '(#2336 AC5).',
        );
        expect(
          met,
          isFalse,
          reason:
              'Persistent false predicate must surface as a `false` return '
              'so call-site short-circuit logic (open panel openers) can '
              'decide whether to escalate the wait.',
        );
      },
    );

    testWidgets(
      'accepts a custom phaseName and E2ePerfLog on the immediate path',
      (WidgetTester tester) async {
        await pumpE2eEmptyApp(tester);
        final perf = E2ePerfLog('e2e_pump_until_test');
        final met = await e2ePumpUntilConditionOrIdle(
          tester,
          () => true,
          timeout: const Duration(seconds: 2),
          perf: perf,
          phaseName: 'pin_pump_until_idle_perf_phase',
        );
        expect(
          met,
          isTrue,
          reason:
              'Smoke-only: the helper must keep its immediate-success '
              'contract when handed an E2ePerfLog + explicit phaseName so '
              'scenario-level callers can attach observability metadata '
              'without changing semantics.',
        );
      },
    );

    testWidgets(
      'accepts a custom phaseName and E2ePerfLog on the timeout path',
      (WidgetTester tester) async {
        await pumpE2eEmptyApp(tester);
        final perf = E2ePerfLog('e2e_pump_until_test');
        final met = await e2ePumpUntilConditionOrIdle(
          tester,
          () => false,
          timeout: const Duration(milliseconds: 80),
          perf: perf,
          phaseName: 'pin_pump_until_idle_perf_timeout',
        );
        expect(
          met,
          isFalse,
          reason:
              'Passing a perf log on the timeout path must keep the '
              'best-effort `false` return; perf is observability metadata '
              'only and must not promote the timeout into a fail() call.',
        );
      },
    );
  });
}
