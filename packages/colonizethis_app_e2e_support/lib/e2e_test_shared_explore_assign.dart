import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show ctE2eCivilianPanelSnapshot, ctE2eNavalPanelSnapshot;
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

const Duration kE2eDefaultBundledExploreSweepWait = Duration(seconds: 5);

/// Returns `true` when at least one civilian unit row exposes an **enabled**
/// `Explore` assign target reachable through the civilian panel
/// ([kCtE2ECivilianPanelRootKey]).
///
/// Lifted from the formerly private `_anyExplorerHasEnabledExploreAssignFleetE2e`
/// in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2 / AC5 / Bottleneck 5). The fleet bundled-Explore retry
/// loop in `new_game_fleet_reaches_new_world_e2e_test.dart` calls this
/// helper through the AC1 barrel alias `anyExplorerHasEnabledExploreAssignFleet`
/// up to `maxBoundedTurnRetries (8)` times per scenario, so a silent rename
/// / fail-open here would stall the retry loop on the slow `maxPanelSweepSteps
/// (16) × per-step Assign sweep` path — Bottleneck 5 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in `app/test/e2e_any_explorer_has_enabled_explore_assign_fleet_test.dart`
/// carries the behavioural contract.
///
/// Contract:
///
/// - First, consults [e2eExploreAssignEnabledFromCivilianSnapshot] with the
///   current [ctE2eCivilianPanelSnapshot]. A non-`null` snapshot result is
///   returned verbatim (`true` / `false`); the panel-sweep walk is only
///   entered when the snapshot is `null` (no plumbing yet this turn).
/// - Expects exactly one [ListView] descendant of [kCtE2ECivilianPanelRootKey];
///   throws via [expect] otherwise (fail-fast on a malformed panel — the
///   pre-#2336 helper had the same precondition).
/// - Walks `Assign` text rows under that ListView in tree order, tapping
///   each unique button (identityHashCode-deduped) and bounded-polling for
///   an `Explore` [ListTile] to mount.
/// - When the tapped row's `Explore` tile appears and reports
///   `enabled == true`, returns `true`. When `enabled == false`, dismisses
///   the assign sheet and continues the sweep.
/// - When the sweep exhausts [maxPanelSweepSteps] (defaults to **16**, the
///   narrowed bound from issue #2336 § Bottleneck 5 / AC1; the pre-#2336
///   helper used 24), returns `false`.
/// - **Fast-path exit when the panel has stabilized** (Refs GitHub #2336
///   § Bottleneck 5 / AC5 / Proposed work item 5): when two consecutive
///   sweep steps add zero new `Assign` widgets to the `visitedAssignWidgets`
///   identity set, the helper returns `false` without paying the remaining
///   drag-and-pump cycles. The two-step buffer absorbs a single transient
///   frame where freshly dragged rows have not yet attached to the tree,
///   matching the conservative "settle once before declaring stable"
///   contract the rest of the bundled-Explore retry path uses. A single
///   empty step never short-circuits.
/// - Between sweep steps, drags the panel `Scrollable` upward by
///   `Offset(0, -180)` and pumps a single 25 ms frame so the next iteration
///   can short-circuit on freshly revealed `Assign` rows without paying a
///   leading fixed-delay settle (AC5 adaptive polling).
/// - The `Explore`-tile-settled and assign-sheet-dismissed waits are
///   bounded by [maxUiResponseWait] (5 s default, the legacy constant) and
///   a 400 ms dismissed-poll respectively; both ramp via
///   [e2eAdaptivePollRampAfterIdle].
Future<bool> e2eAnyExplorerHasEnabledExploreAssignFleet(
  WidgetTester tester, {
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  int maxPanelSweepSteps = 16,
}) async {
  final snapshotHint = e2eExploreAssignEnabledFromCivilianSnapshot(
    ctE2eCivilianPanelSnapshot,
  );
  if (snapshotHint != null) {
    return snapshotHint;
  }

  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  final listView = find.descendant(of: root, matching: find.byType(ListView));
  expect(listView, findsOneWidget);
  final panelScrollable = find.descendant(
    of: listView,
    matching: find.byType(Scrollable),
  );
  expect(panelScrollable, findsOneWidget);
  final exploreTile = find.widgetWithText(ListTile, 'Explore');
  // Adaptive replacement (#2336 AC5 / Bottleneck 5): the prior 300ms post-tap
  // settle plus 50ms fixed wait loop is replaced by a single condition-based
  // wait that evaluates [exploreTile] before the first pump and ramps the
  // pump interval via [e2eAdaptivePollRampAfterIdle]. The hard
  // [maxUiResponseWait] cap is preserved.
  Future<void> waitForAssignSheetSettled() async {
    final wait = Stopwatch()..start();
    var assignPollMs = 25;
    while (wait.elapsed < maxUiResponseWait) {
      if (exploreTile.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(Duration(milliseconds: assignPollMs));
      assignPollMs = e2eAdaptivePollRampAfterIdle(assignPollMs);
    }
  }

  // After [handlePopRoute] the assign sheet can take a frame or two to leave
  // the tree. Replace the prior fixed 200ms pump with a bounded adaptive
  // poll that returns as soon as the sheet finishes dismissing.
  Future<void> waitForAssignSheetDismissed() async {
    await e2ePumpUntilConditionOrIdle(
      tester,
      () => exploreTile.evaluate().isEmpty,
      timeout: const Duration(milliseconds: 400),
      phaseName: 'pump_until_assign_sheet_dismissed',
    );
  }

  final visitedAssignWidgets = <int>{};
  // Refs GitHub #2336 § Bottleneck 5 / AC5 / Proposed work item 5: track
  // consecutive sweep steps that added zero new Assign widgets so the helper
  // can exit early once the panel has stopped revealing new rows. A
  // single empty step is tolerated to absorb one transient post-drag frame
  // before the freshly dragged rows are attached to the element tree; a
  // second consecutive empty step is treated as evidence the panel has
  // stabilized and the remaining sweep budget is unproductive.
  var consecutiveEmptyStepsAfterDrag = 0;
  for (var step = 0; step < maxPanelSweepSteps; step++) {
    final assignCandidates = find
        .descendant(of: listView, matching: find.text('Assign'))
        .evaluate()
        .toList();
    var newAssignWidgetsThisStep = 0;
    for (final assignElement in assignCandidates) {
      final marker = identityHashCode(assignElement.widget);
      if (!visitedAssignWidgets.add(marker)) {
        continue;
      }
      newAssignWidgetsThisStep++;
      final assignFinder = find.byWidget(assignElement.widget);
      try {
        await tester.ensureVisible(assignFinder);
      } catch (_) {
        continue;
      }
      await tester.tap(assignFinder.first, warnIfMissed: false);
      await waitForAssignSheetSettled();
      if (exploreTile.evaluate().isNotEmpty) {
        final enabled = tester.widget<ListTile>(exploreTile.first).enabled;
        await tester.binding.handlePopRoute();
        await waitForAssignSheetDismissed();
        if (enabled == true) {
          return true;
        }
      } else {
        await tester.binding.handlePopRoute();
        await waitForAssignSheetDismissed();
      }
    }

    if (newAssignWidgetsThisStep == 0) {
      consecutiveEmptyStepsAfterDrag++;
      if (consecutiveEmptyStepsAfterDrag >= 2) {
        return false;
      }
    } else {
      consecutiveEmptyStepsAfterDrag = 0;
    }

    await tester.drag(panelScrollable, const Offset(0, -180));
    // Adaptive replacement for the prior 120ms post-drag settle (#2336 AC5):
    // pump a single short frame and let the next iteration short-circuit if
    // new Assign rows are already visible.
    await tester.pump(const Duration(milliseconds: 25));
  }
  return false;
}

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
