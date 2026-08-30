library;

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ensure_non_home_fleet_nw_fixtures.dart';

void registerEnsureNonHomeFleetFailureGroup() {
  group('e2eEnsureNonHomeFleetInNwAfterLoop — failure branch', () {
    testWidgets('calls failureMessageBuilder with tester.takeException() when '
        'snapshot reports no NW fleet and widget tree has no fleet rows '
        '(naval panel mounted so openNavalPanel short-circuits)', (
      tester,
    ) async {
      await pumpEnsureNonHomeNavalPanelMounted(tester);
      // Snapshot is non-null so the harness probe consults snapshot only
      // (does NOT fall back to the widget tree) — guarantees the
      // failure path fires deterministically without needing a full
      // naval panel widget tree.
      ctE2eNavalPanelSnapshot = ensureNonHomeHomeOnlySnapshot();
      final perf = shared.E2ePerfLog('final_naval_reach_check_pin');
      var failureBuilderInvocations = 0;
      Object? lastExceptionSeenByBuilder = 'not-yet-invoked';
      await expectLater(
        e2eEnsureNonHomeFleetInNwAfterLoop(
          tester,
          perf: perf,
          failureMessageBuilder: (lastException) {
            failureBuilderInvocations++;
            lastExceptionSeenByBuilder = lastException;
            return 'scenario-specific fail | lastException=$lastException';
          },
        ),
        throwsA(
          isA<TestFailure>().having(
            (e) => e.message,
            'message',
            contains('scenario-specific fail | lastException='),
          ),
        ),
        reason:
            'When the snapshot reports no NW fleet, the harness probe '
            'returns false and the helper MUST call '
            '`fail(failureMessageBuilder(tester.takeException()))` so '
            'the scenario-specific fail message preserves the legacy '
            '"Last exception:" suffix the inline blocks appended. A '
            'regression that swallowed the failure or used a hardcoded '
            'message would surface here as either no throw or a wrong '
            'message string.',
      );
      expect(
        failureBuilderInvocations,
        1,
        reason:
            '`failureMessageBuilder` must be invoked exactly once on '
            'the failure path so the scenario-specific fail message '
            'is the only one rendered. A regression that bypassed '
            'the builder would leave the count at 0; one that called '
            'it twice would double-render the message.',
      );
      // `tester.takeException()` returns `null` when no framework
      // exception was raised inside the helper body; pin that the
      // builder still receives the call with `null` so the legacy
      // "Last exception: null" rendering is preserved byte-identically
      // for log scrapers that consume the suffix.
      expect(
        lastExceptionSeenByBuilder,
        isNull,
        reason:
            'The builder must be invoked with the value of '
            '`tester.takeException()` even when that value is `null` '
            '(no framework exception raised inside the helper body). '
            'A regression that swapped to a sentinel "no exception" '
            'string or a placeholder Object would break log scrapers '
            'keyed on the literal "Last exception: null" suffix.',
      );
    });
  });
}
