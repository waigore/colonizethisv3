// e2eFleetReachTurnLoop snapshot precheck pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

import 'e2e_widget_pump_harness.dart';
import 'expect_panel_texts_harness.dart';
import 'fleet_reach_turn_loop_fixtures.dart';

void registerFleetReachTurnLoopPrecheckGroup() {
  group('e2eFleetReachTurnLoop — snapshot precheck short-circuit', () {
    testWidgets(
      'reached snapshot at iteration 0 returns [reachedSnapshotPrecheck] '
      'with iterationsRun=0 and a single ensureUnderWallClock callback',
      (tester) async {
        await pumpE2eEmptyScaffold(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));
        ctE2eNavalPanelSnapshot = fleetReachReachedSnapshot();
        final perf = shared.E2ePerfLog('fleet_reach_loop_pin');
        final steps = <String>[];
        late E2eFleetReachLoopResult result;
        final lines = await captureDebugPrints(() async {
          result = await e2eFleetReachTurnLoop(
            tester,
            l10n,
            perf: perf,
            ensureUnderWallClock: steps.add,
            maxTurns: kE2eDefaultFleetReachLoopMaxTurns,
          );
        });
        expect(
          result.exit,
          E2eFleetReachLoopExit.reachedSnapshotPrecheck,
          reason:
              'A snapshot satisfying '
              '`e2eFleetReachDoneFromCtSnapshotOnly` at the very first '
              'probe of iteration 0 must map to '
              '[reachedSnapshotPrecheck] so call sites emit the legacy '
              '`meta: result=reached_snapshot_precheck` perf marker — '
              'never the more generic [reachedAfterMove] or post-turn '
              'branches.',
        );
        expect(
          result.iterationsRun,
          0,
          reason:
              'Reach on iteration 0 means iterationsRun must be 0; a '
              'regression that incremented inside the precheck branch '
              'would surface here as off-by-one and skew per-iteration '
              'wall-clock attribution.',
        );
        expect(
          steps,
          equals(<String>['turn loop start turnIdx=0']),
          reason:
              'The first per-iteration `ensureUnderWallClock` callback '
              'must fire before the snapshot probe so wall-clock guards '
              'apply uniformly across every iteration. Dropping it on '
              'iteration 0 would let a degenerate "always satisfied" '
              'snapshot mask a wall-clock breach.',
        );
        expect(
          lines
              .where(
                (line) => line.startsWith(
                  'E2E_COUNTER|test=fleet_reach_loop_pin|name=turn_loop_iterations|',
                ),
              )
              .toList(),
          <String>[
            'E2E_COUNTER|test=fleet_reach_loop_pin|name=turn_loop_iterations|value=1',
          ],
          reason:
              'Even a precheck-only iteration must bump '
              '`turn_loop_iterations` exactly once so dashboards counting '
              'per-iteration cost attribute the entry to the right '
              'scenario; dropping the bump on the precheck branch would '
              'under-count the cheapest exit path.',
        );
      },
    );
  });
}
