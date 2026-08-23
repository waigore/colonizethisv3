/// Pins the widget-tree contract of
/// [e2eAwaitNwCoastalOrVisibleLandForBundledExplore]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The post-bundle Explore scenario in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper via
/// the AC1 barrel alias `awaitNwCoastalOrVisibleLandForBundledExplore` to
/// bridge `e2eHarnessDetectsNonHomeFleetInNewWorld` (fleet has reached open
/// NW sea) and the strict `anyExplorerHasEnabledExploreAssignFleet` check
/// (Explore is enabled, requiring coastal land visibility per
/// `SPEC/program/fog-and-exploration-resolution.md`). A silent rename or
/// fail-open would either skip the readiness wait — masking a real Explore
/// regression — or stall the loop at
/// `kE2eDefaultBundledExploreReadinessMaxTurns (35) × ~5 s per iteration`,
/// directly inflating the wall-clock cap #2336 is reducing
/// (Bottleneck 4 in `SPEC/program/e2e-integration-tests.md` § Determinism).
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test layer
/// carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 4.
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

import 'support/await_nw_coastal_barrel_group.dart';
import 'support/await_nw_coastal_fixtures.dart';
import 'support/await_nw_coastal_short_circuit_group.dart';
import 'support/e2e_widget_pump_harness.dart';

void main() {
  suppressLogsForTests();

  setUp(() {
    ctE2eNavalPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eNavalPanelSnapshot = null;
  });

  group('e2eAwaitNwCoastalOrVisibleLandForBundledExplore — defaults', () {
    test(
      'kE2eDefaultBundledExploreReadinessMaxTurns matches the legacy 35-turn cap',
      () {
        expect(
          kE2eDefaultBundledExploreReadinessMaxTurns,
          35,
          reason:
              'Lifted-from constant must match the legacy private '
              '`maxTurns = 35` literal so the bundled-Explore readiness '
              'loop ceiling stays aligned with '
              '`_kMaxNextTurnTapsForNwFleetReach (35)` in '
              '`new_game_fleet_reaches_new_world_e2e_helpers.dart`. A '
              'silent change would either let the loop run longer than '
              'the documented Bottleneck 4 ceiling (#2336) or '
              'short-circuit early and skip the readiness wait.',
        );
      },
    );
  });

  group('e2eAwaitNwCoastalOrVisibleLandForBundledExplore — bounded loop', () {
    testWidgets(
      'maxTurns: 0 is a complete no-op — ensureUnderWallClock never invoked',
      (tester) async {
        await pumpE2eEmptyScaffold(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));
        final steps = <String>[];
        await e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
          tester,
          l10n,
          ensureUnderWallClock: steps.add,
          maxTurns: 0,
        );
        expect(
          steps,
          isEmpty,
          reason:
              'A zero-iteration call must not enter the for-body, '
              'must not invoke the wall-clock guard, and must not '
              'attempt to open the naval panel — otherwise callers '
              'cannot pass `maxTurns: 0` as a safe disarm during '
              'tests or stub scenarios.',
        );
      },
    );

    testWidgets(
      'maxTurns honours the caller override (uses the parameter, not the default)',
      (tester) async {
        await pumpE2eEmptyScaffold(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));
        final steps = <String>[];
        // Snapshot satisfies neither predicate; the helper would normally
        // attempt naval-panel work, but with maxTurns: 0 the loop must
        // not enter even when the snapshot is non-null.
        ctE2eNavalPanelSnapshot = awaitNwSnapshot();
        await e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
          tester,
          l10n,
          ensureUnderWallClock: steps.add,
          maxTurns: 0,
        );
        expect(
          steps,
          isEmpty,
          reason:
              'maxTurns: 0 must short-circuit before the first '
              'iteration even when the snapshot is non-null but '
              'fails both readiness predicates — a regression that '
              'silently used the default 35 here would burn the '
              'full Bottleneck 4 budget in any test that disabled '
              'the loop.',
        );
      },
    );
  });

  registerAwaitNwCoastalShortCircuitGroup();
  registerAwaitNwCoastalBarrelGroup();
}
