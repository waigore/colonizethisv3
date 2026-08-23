/// Pins the widget-tree contract of [e2eFleetReachTurnLoop]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// Both fleet-reach `testWidgets` bodies in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` call this helper via the
/// AC1 barrel alias `fleetReachTurnLoop` to drive up to
/// `_kMaxNextTurnTapsForNwFleetReach (35)` next-turn taps inside the 5-minute
/// scenario wall-clock cap (Bottleneck 4 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism). A silent rename
/// or behavioural drift here would either:
///
///   - Burn the full 35 × ~5 s budget on a snapshot that already satisfies
///     `e2eFleetReachDoneFromCtSnapshotOnly` (the precheck short-circuit
///     keys the loop's "early exit" contract).
///   - Drop one of the `result=reached_*` enum branches and silently flip
///     the call site's `perf.timing('test_total', ..., meta: ...)` payload
///     to a stale label — breaking AC8 timing attribution.
///   - Stop bumping the `turn_loop_iterations` perf counter and orphan any
///     dashboard counting per-iteration cost.
///   - Stop emitting the canonical `ensureUnderWallClock` step labels and
///     surface as opaque `wall_clock_exceeded` failures with no
///     helper-level attribution.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test layer
/// carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 4.
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

import 'support/e2e_widget_pump_harness.dart';
import 'support/fleet_reach_turn_loop_bounded_group.dart';
import 'support/fleet_reach_turn_loop_barrel_group.dart';
import 'support/fleet_reach_turn_loop_fixtures.dart';
import 'support/fleet_reach_turn_loop_precheck_group.dart';

void main() {
  suppressLogsForTests();

  setUp(() {
    ctE2eNavalPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eNavalPanelSnapshot = null;
  });

  group('e2eFleetReachTurnLoop — default constants', () {
    test(
      'kE2eDefaultFleetReachLoopMaxTurns matches the legacy 35-turn cap',
      () {
        expect(
          kE2eDefaultFleetReachLoopMaxTurns,
          35,
          reason:
              'Lifted-from default must equal the legacy private '
              '`_kMaxNextTurnTapsForNwFleetReach = 35` literal in '
              '`new_game_fleet_reaches_new_world_e2e_helpers.dart`. A silent '
              'change would either burn additional turns past the documented '
              'Bottleneck 4 ceiling (#2336) or short-circuit the fleet-reach '
              'scenarios before they exercise the legacy reach window.',
        );
      },
    );
  });

  group('e2eFleetReachTurnLoop — step label format', () {
    testWidgets(
      'step label uses `turn loop start turnIdx=<idx>` form on iteration 0',
      (tester) async {
        await pumpE2eEmptyScaffold(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));
        ctE2eNavalPanelSnapshot = fleetReachReachedSnapshot();
        final perf = shared.E2ePerfLog('fleet_reach_loop_pin');
        final steps = <String>[];
        await e2eFleetReachTurnLoop(
          tester,
          l10n,
          perf: perf,
          ensureUnderWallClock: steps.add,
          maxTurns: 1,
        );
        expect(
          steps.single,
          matches(RegExp(r'^turn loop start turnIdx=\d+$')),
          reason:
              'Wall-clock guards captured for `#2336` debug runs key on '
              'the `turn loop start turnIdx=` label prefix to attribute '
              'loop overshoot to this helper. A silent rename would '
              'surface in CI as an opaque `wall_clock_exceeded` failure '
              'with no helper attribution.',
        );
        expect(
          steps.single,
          equals('turn loop start turnIdx=0'),
          reason:
              'Iteration index must be 0-based and embedded into the '
              'label so a regression that reset the counter or used '
              '1-based indexing surfaces here, not as a confusing '
              'off-by-one in CI logs.',
        );
      },
    );
  });

  registerFleetReachTurnLoopBoundedGroup();
  registerFleetReachTurnLoopPrecheckGroup();
  registerFleetReachTurnLoopBarrelGroup();
}
