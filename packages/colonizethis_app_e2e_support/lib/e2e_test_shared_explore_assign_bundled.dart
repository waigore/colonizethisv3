import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show ctE2eNavalPanelSnapshot;
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

/// Default bound on the outer turn loop that drives the bundled-Explore
/// readiness wait (see [e2eAwaitNwCoastalOrVisibleLandForBundledExplore]).
///
/// Mirrors the legacy `maxTurns = 35` constant the helper carried as a
/// private literal before the lift (Refs GitHub #2336 AC1 / AC2). The 35-turn
/// budget tracks `_kMaxNextTurnTapsForNwFleetReach` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` so the bundled-Explore
/// readiness loop and the upstream fleet-reach loop share a common ceiling.
const int kE2eDefaultBundledExploreReadinessMaxTurns = 35;

/// Drives the bundled-Explore readiness wait: probes the live naval-panel
/// snapshot every loop iteration, opens the naval panel only when snapshot
/// plumbing is unavailable, attempts one bounded New-World move via
/// [e2eTryNavalMoveSegment], advances one human turn, and exits as soon as
/// either coastal-NW arrival or any NW fogged-or-better visibility is
/// observed.
///
/// Lifted from the formerly private
/// `_awaitNwCoastalOrVisibleLandForBundledExploreE2e` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2 / Bottleneck 4). The post-bundle Explore test calls this
/// helper exactly once per scenario to bridge the gap between
/// `e2eHarnessDetectsNonHomeFleetInNewWorld` (fleet has arrived at NW open
/// sea) and the strict `anyExplorerHasEnabledExploreAssignFleet` check that
/// requires coastal land visibility. The widget-test pin in
/// `app/test/e2e_await_nw_coastal_or_visible_land_for_bundled_explore_test.dart`
/// guards against silent regressions because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
///
/// Contract:
///
/// - Loops at most [maxTurns] iterations (default
///   [kE2eDefaultBundledExploreReadinessMaxTurns]); each iteration invokes
///   [ensureUnderWallClock] with `'NW bundled-explore readiness i=<idx>'`.
/// - Returns immediately when
///   [e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot] **or**
///   [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] holds for
///   [ctE2eNavalPanelSnapshot] at any of the three probe points:
///   start-of-iteration, post-naval-open (when snapshot was null), and
///   post-`advanceOneHumanTurn`.
/// - When the snapshot is null, opens the naval panel via
///   [e2eOpenNavalPanel] (using [maxUiResponseWait] for both the open and
///   close timeouts), re-probes, and closes the bottom sheet via
///   [e2eCloseBottomSheet] before returning on success.
/// - Calls [e2eTryNavalMoveSegment] with `useNewWorldMapTabFirst: true`,
///   `allowWarpDestinations: false`, and `navalPanelAlreadyOpen` set to
///   `ctE2eNavalPanelSnapshot == null` (mirroring the pre-lift contract so
///   the snapshot-backed path keeps the naval sheet open across iterations).
/// - Closes the bottom sheet after each move attempt and advances one human
///   turn via [e2eAdvanceOneHumanTurn].
/// - Returns normally — without throwing — when the loop exhausts
///   [maxTurns] without satisfying either predicate. The caller is
///   responsible for the strict Explore-enabled assertion that follows.

Future<void> e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
  WidgetTester tester,
  AppLocalizations l10n, {
  required void Function(String step) ensureUnderWallClock,
  int maxTurns = kE2eDefaultBundledExploreReadinessMaxTurns,
  Duration maxUiResponseWait = kE2eDefaultNavalMoveSegmentUiWait,
}) async {
  for (var i = 0; i < maxTurns; i++) {
    ensureUnderWallClock('NW bundled-explore readiness i=$i');
    await e2eDismissTransientUi(tester);
    await e2eTapNewWorldRegionTabIfPresent(tester);
    if (e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        ) ||
        e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        )) {
      return;
    }
    if (ctE2eNavalPanelSnapshot == null) {
      await e2eOpenNavalPanel(
        tester,
        timeout: maxUiResponseWait,
        bottomSheetCloseTimeout: maxUiResponseWait,
      );
      if (e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            ctE2eNavalPanelSnapshot,
          ) ||
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            ctE2eNavalPanelSnapshot,
          )) {
        await e2eCloseBottomSheet(tester, overallTimeout: maxUiResponseWait);
        return;
      }
    }
    await e2eTryNavalMoveSegment(
      tester,
      l10n,
      useNewWorldMapTabFirst: true,
      allowWarpDestinations: false,
      maxUiResponseWait: maxUiResponseWait,
      navalPanelAlreadyOpen: ctE2eNavalPanelSnapshot == null,
    );
    await e2eCloseBottomSheet(tester, overallTimeout: maxUiResponseWait);
    await e2eAdvanceOneHumanTurn(tester, l10n: l10n);
    if (e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        ) ||
        e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        )) {
      return;
    }
  }
}

/// Default `perf.timing` phase label emitted by
/// [e2eCheckExploreEnabledFromCivilianPanel].
///
/// Mirrors the pre-lift inline-closure literal in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` so downstream
/// `E2E_TIMING|phase=...` log scrapers and dashboards remain stable across
/// the lift (Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 5). A silent
/// rename would orphan any existing telemetry keyed on this phase name.
const String kE2eDefaultBundledExploreRetryLoopPhase =
    'bundled_explore_retry_loop';

/// Default `afterSheetPanelsClearPhase` override forwarded into
/// [e2eOpenCivilianPanel] by [e2eCheckExploreEnabledFromCivilianPanel].
///
/// Mirrors the pre-lift fleet-scenario literal so the
/// `pump_until_panels_cleared_after_close_sheet_fleet_civilian_open` phase
/// label keeps attributing post-sheet-close settle time to the fleet
/// scenario rather than to the generic civilian-open path. The full-turn
/// scenario keeps the default `_civilian_open` label by going through
/// [e2eOpenCivilianPanel] directly (Refs GitHub #2336 AC1 / AC2).
const String kE2eDefaultFleetCivilianOpenAfterSheetClearPhase =
    'pump_until_panels_cleared_after_close_sheet_fleet_civilian_open';

/// Opens the civilian panel from the fleet bundled-Explore retry context and
/// returns `true` when at least one civilian unit row exposes an enabled
/// `Explore` assign target.
///
/// Lifted from the formerly inline `checkExploreEnabledFromCivilianPanel`
/// closure in `new_game_fleet_reaches_new_world_e2e_test.dart` (Refs GitHub
/// #2336 AC1 / AC2 / AC5 / Bottleneck 5). The post-bundle Explore scenario
/// invokes this helper inside a bounded `maxBoundedTurnRetries (8)` retry
/// loop, so a silent rename / fail-open would either inflate the bundled-
/// Explore wall clock or mask a real Explore regression. The widget-test
/// pin in
/// `app/test/e2e_check_explore_enabled_from_civilian_panel_test.dart`
/// guards against silent regressions because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
///
/// Contract:
///
/// - Starts a fresh stopwatch and forwards [perf] / [maxUiResponseWait]
///   into [e2eOpenCivilianPanel]; the `afterSheetPanelsClearPhase` default
///   ([kE2eDefaultFleetCivilianOpenAfterSheetClearPhase]) preserves the
///   pre-lift fleet-scenario attribution label.
/// - Calls [e2eWaitUntilFound] on [kCtE2ECivilianPanelRootKey] with
///   `phaseName: 'wait_until_found_civilian_panel'` before evaluating any
///   Assign rows, matching the pre-lift closure exactly.
/// - Delegates to [e2eAnyExplorerHasEnabledExploreAssignFleet] for the
///   actual sweep, forwarding [maxUiResponseWait]. The Assign-sweep is the
///   only place where snapshot short-circuit / panel-walk semantics are
///   defined (Bottleneck 5).
/// - Calls [e2eCloseBottomSheet] with [maxUiResponseWait] regardless of
///   the Explore-enabled outcome so the next retry iteration starts from a
///   clean panel state. A regression that skipped the close would stall
///   the retry loop on a stale Assign sheet.
/// - When [perf] is non-`null`, emits a single `perf.timing(...)` event on
///   return with phase [phaseTimingLabel] (default
///   [kE2eDefaultBundledExploreRetryLoopPhase]) and
///   `meta: 'result=enabled'` or `meta: 'result=not_enabled'`.
/// - Returns the boolean reported by
///   [e2eAnyExplorerHasEnabledExploreAssignFleet] verbatim.
Future<bool> e2eCheckExploreEnabledFromCivilianPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  String afterSheetPanelsClearPhase =
      kE2eDefaultFleetCivilianOpenAfterSheetClearPhase,
  String phaseTimingLabel = kE2eDefaultBundledExploreRetryLoopPhase,
}) async {
  final phaseSw = Stopwatch()..start();
  await e2eOpenCivilianPanel(
    tester,
    perf: perf,
    afterSheetPanelsClearPhase: afterSheetPanelsClearPhase,
    bottomSheetCloseTimeout: maxUiResponseWait,
  );
  await e2eWaitUntilFound(
    tester,
    find.byKey(kCtE2ECivilianPanelRootKey),
    timeout: maxUiResponseWait,
    perf: perf,
    phaseName: 'wait_until_found_civilian_panel',
  );
  final enabled = await e2eAnyExplorerHasEnabledExploreAssignFleet(
    tester,
    maxUiResponseWait: maxUiResponseWait,
  );
  await e2eCloseBottomSheet(
    tester,
    perf: perf,
    overallTimeout: maxUiResponseWait,
  );
  perf?.timing(
    phaseTimingLabel,
    phaseSw.elapsed,
    meta: 'result=${enabled ? "enabled" : "not_enabled"}',
  );
  return enabled;
}
