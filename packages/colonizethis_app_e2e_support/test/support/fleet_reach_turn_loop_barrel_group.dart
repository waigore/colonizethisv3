// e2eFleetReachTurnLoop AC1 barrel pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

import 'e2e_widget_pump_harness.dart';
import 'fleet_reach_turn_loop_fixtures.dart';

void registerFleetReachTurnLoopBarrelGroup() {
  group('e2eFleetReachTurnLoop — AC1 barrel forwarding', () {
    testWidgets(
      'fleetReachTurnLoop (barrel alias) short-circuits identically to '
      'the lifted form when the snapshot precheck satisfies',
      (tester) async {
        await pumpE2eEmptyScaffold(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));
        ctE2eNavalPanelSnapshot = fleetReachReachedSnapshot();
        final perf = shared.E2ePerfLog('fleet_reach_loop_pin');
        final steps = <String>[];
        final result = await fleetReachTurnLoop(
          tester,
          l10n,
          perf: perf,
          ensureUnderWallClock: steps.add,
          maxTurns: kE2eDefaultFleetReachLoopMaxTurns,
        );
        expect(
          result.exit,
          E2eFleetReachLoopExit.reachedSnapshotPrecheck,
          reason:
              'The AC1 barrel wrapper must forward arguments in the '
              'documented order — a regression that swapped '
              '`ensureUnderWallClock` with `maxTurns`, dropped `l10n`, '
              'or accidentally captured a fresh `maxTurns` default would '
              'surface here, not in the slow CI lane.',
        );
        expect(
          result.iterationsRun,
          0,
          reason:
              'Barrel-aliased call must report the same '
              '[iterationsRun] as the lifted form so AC8 timing harness '
              'aggregating per-iteration cost stays attribution-stable '
              'across the lift.',
        );
        expect(
          steps,
          equals(<String>['turn loop start turnIdx=0']),
          reason:
              'Barrel alias must invoke `ensureUnderWallClock` exactly '
              'as the lifted form; an extra or missing callback would '
              'drift the wall-clock attribution between the two '
              'entrypoints.',
        );
      },
    );

    test('fleetReachTurnLoop is re-exported as a tear-off '
        '(compile-time signature pin)', () {
      final Future<E2eFleetReachLoopResult> Function(
        WidgetTester,
        AppLocalizations, {
        required shared.E2ePerfLog perf,
        required void Function(String step) ensureUnderWallClock,
        Duration maxUiResponseWait,
        int maxTurns,
      })
      ref = fleetReachTurnLoop;
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
