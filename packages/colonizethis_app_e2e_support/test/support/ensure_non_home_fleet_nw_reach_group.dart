library;

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_widget_pump_harness.dart';
import 'ensure_non_home_fleet_nw_fixtures.dart';

void registerEnsureNonHomeFleetReachGroup() {
  group('e2eEnsureNonHomeFleetInNwAfterLoop — snapshot reach short-circuit', () {
    testWidgets(
      'returns successfully without calling failureMessageBuilder when '
      'snapshot precheck reports reach (open-naval-panel branch skipped)',
      (tester) async {
        await pumpE2eEmptyScaffold(tester);
        ctE2eNavalPanelSnapshot = ensureNonHomeReachedSnapshot();
        final perf = shared.E2ePerfLog('final_naval_reach_check_pin');
        var failureBuilderInvocations = 0;
        final result = await e2eEnsureNonHomeFleetInNwAfterLoop(
          tester,
          perf: perf,
          failureMessageBuilder: (lastException) {
            failureBuilderInvocations++;
            return 'should not be invoked (lastException=$lastException)';
          },
        );
        expect(
          failureBuilderInvocations,
          0,
          reason:
              'A snapshot that satisfies '
              '`e2eFleetReachDoneFromCtSnapshotOnly` must short-circuit '
              'past the conditional `openNavalPanel` AND the harness '
              'probe must succeed via snapshot — `failureMessageBuilder` '
              'should never fire on the happy reach path. A regression '
              'that called it unconditionally would fail every scenario '
              'with a synthetic message.',
        );
        expect(
          result.lastKnownNavalSnapshot,
          isNotNull,
          reason:
              'When the precheck satisfies via the live global '
              '`ctE2eNavalPanelSnapshot`, the captured snapshot must '
              'propagate into [E2eFinalNavalReachCheckResult.lastKnownNavalSnapshot] '
              'so test 2 can update its `lastKnownNavalSnapshot` tracker '
              'before the bundled-Explore diagnostics fire.',
        );
        expect(
          identical(result.lastKnownNavalSnapshot, ctE2eNavalPanelSnapshot),
          isTrue,
          reason:
              'The captured snapshot must be the same object reference '
              'as the live global at the post-conditional-open probe '
              'point — a defensive copy would either duplicate memory '
              'per call or drift the equality contract used by '
              '[e2eBundledExploreRejectionDiagnostics].',
        );
      },
    );
  });
}
