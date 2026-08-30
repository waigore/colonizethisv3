library;

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_widget_pump_harness.dart';
import 'ensure_non_home_fleet_nw_fixtures.dart';

void registerEnsureNonHomeFleetBarrelGroup() {
  group('e2eEnsureNonHomeFleetInNwAfterLoop — AC1 barrel forwarding', () {
    testWidgets('ensureNonHomeFleetInNwAfterLoop (barrel alias) short-circuits '
        'identically to the lifted form on the snapshot reach path', (
      tester,
    ) async {
      await pumpE2eEmptyScaffold(tester);
      ctE2eNavalPanelSnapshot = ensureNonHomeReachedSnapshot();
      final perf = shared.E2ePerfLog('final_naval_reach_check_pin');
      var failureBuilderInvocations = 0;
      final result = await ensureNonHomeFleetInNwAfterLoop(
        tester,
        perf: perf,
        failureMessageBuilder: (lastException) {
          failureBuilderInvocations++;
          return 'should not fire';
        },
      );
      expect(
        failureBuilderInvocations,
        0,
        reason:
            'The AC1 barrel wrapper must forward arguments in the '
            'documented order — a regression that swapped '
            '`failureMessageBuilder` with `maxUiResponseWait`, '
            'dropped `perf`, or accidentally inserted a default '
            'message would surface here as a spurious failure on the '
            'happy reach path.',
      );
      expect(
        result.lastKnownNavalSnapshot,
        isNotNull,
        reason:
            'Barrel-aliased call must propagate the captured snapshot '
            'identically to the lifted form so the post-loop tracker '
            'in test 2 stays in sync between the two entrypoints.',
      );
    });

    test('ensureNonHomeFleetInNwAfterLoop is re-exported as a tear-off '
        '(compile-time signature pin)', () {
      final Future<E2eFinalNavalReachCheckResult> Function(
        WidgetTester, {
        required shared.E2ePerfLog perf,
        required String Function(Object? lastException) failureMessageBuilder,
        Duration maxUiResponseWait,
      })
      ref = ensureNonHomeFleetInNwAfterLoop;
      expect(
        ref,
        isNotNull,
        reason:
            'The AC1 barrel must continue to export the helper with '
            'the documented signature. A silent removal from the '
            '`show` clause or an arg-order swap on the wrapper would '
            'fail this assignment at compile time, surfacing a '
            'breaking change before CI rather than after.',
      );
    });
  });
}
