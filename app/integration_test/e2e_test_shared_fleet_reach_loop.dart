import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eNavalPanelSnapshot, ctE2eNavalPanelSnapshot;
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Default `maxTurns` bound for [e2eFleetReachTurnLoop].
///
/// Mirrors the legacy private `_kMaxNextTurnTapsForNwFleetReach = 35` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` so the lifted loop
/// keeps the same wall-clock ceiling the fleet-reach scenarios used before
/// the extraction (Refs GitHub #2336 AC1 / AC2 / Bottleneck 4). A silent
/// change would either burn additional turns past the documented Bottleneck
/// 4 budget or short-circuit early and skip otherwise-reachable arrival
/// conditions.
const int kE2eDefaultFleetReachLoopMaxTurns = 35;

/// Early-exit branches of [e2eFleetReachTurnLoop].
///
/// Each non-[loopExhausted] value corresponds to a specific reach predicate
/// firing at a specific point inside the per-iteration sequence; the call
/// site maps the value to the legacy `result=...` perf-timing meta label
/// (`result=reached_snapshot_precheck`, `result=reached_snapshot_after_dismiss`,
/// `result=reached_in_loop`, `result=reached_after_move`,
/// `result=reached_snapshot_after_turn`).
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 4.
enum E2eFleetReachLoopExit {
  /// `e2eFleetReachDoneFromCtSnapshotOnly(ctE2eNavalPanelSnapshot)` returned
  /// `true` at the start of an iteration, before any UI work for that turn.
  /// Mapped to legacy `meta: 'result=reached_snapshot_precheck'` by the
  /// call site.
  reachedSnapshotPrecheck,

  /// Snapshot precheck satisfied after the per-iteration
  /// `e2eDismissTransientUi(...)` call. Mapped to legacy
  /// `meta: 'result=reached_snapshot_after_dismiss'`.
  reachedSnapshotAfterDismiss,

  /// Snapshot precheck satisfied after the per-iteration
  /// `e2eTapNewWorldRegionTabIfPresent(...)` call.
  ///
  /// **Legacy label note:** the pre-lift loop in
  /// `new_game_fleet_reaches_new_world_e2e_test.dart` emitted
  /// `meta: 'result=reached_snapshot_precheck'` (not
  /// `..._after_region_tab`) here. The lifted helper preserves the legacy
  /// label by exposing the exit as a separate enum value so call sites can
  /// map it deliberately rather than carry the inconsistency unwittingly.
  reachedSnapshotAfterRegionTab,

  /// `e2eNavalPanelShowsNonHomeFleetInNewWorld(tester)` returned `true`
  /// after opening the naval sheet in the snapshot-unavailable branch
  /// (`ctE2eNavalPanelSnapshot == null`). The naval bottom sheet has been
  /// closed before the helper returns. Mapped to legacy
  /// `meta: 'result=reached_in_loop'`.
  reachedInLoop,

  /// `e2eHarnessDetectsNonHomeFleetInNewWorld(...)` returned `true` after
  /// a [e2eTryNavalMoveSegment] attempt + close-sheet. Mapped to legacy
  /// `meta: 'result=reached_after_move'`.
  reachedAfterMove,

  /// `e2eFleetReachDoneFromCtSnapshotOnly(...)` returned `true` after the
  /// per-iteration `e2eAdvanceOneHumanTurn(...)`. Mapped to legacy
  /// `meta: 'result=reached_snapshot_after_turn'`.
  reachedSnapshotAfterTurn,

  /// Loop ran the full [maxTurns] iterations without any reach predicate
  /// firing. The call site falls through to the post-loop "final naval
  /// check + fail()" path (test 1) or the bundled-Explore readiness wait
  /// (test 2).
  loopExhausted,
}

/// Result of [e2eFleetReachTurnLoop].
///
/// Carries the exit branch plus the last non-null `ctE2eNavalPanelSnapshot`
/// captured while the loop ran. Test 2 (`new_game_fleet_explore_enabled_post_bundle`)
/// uses [lastKnownNavalSnapshot] to compose the post-loop bundled-Explore
/// rejection diagnostics; test 1 (`new_game_fleet_reaches_new_world`) ignores
/// it. [iterationsRun] is exposed for telemetry-style assertions.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 4.
class E2eFleetReachLoopResult {
  const E2eFleetReachLoopResult({
    required this.exit,
    required this.lastKnownNavalSnapshot,
    required this.iterationsRun,
  });

  /// Which exit branch the loop took. [E2eFleetReachLoopExit.loopExhausted]
  /// means the loop ran [E2eFleetReachTurnLoop.maxTurns] without success.
  final E2eFleetReachLoopExit exit;

  /// Last non-null value seen for the global `ctE2eNavalPanelSnapshot` at the
  /// post-`openNavalPanel` capture point inside the loop (mirrors the
  /// pre-lift `lastKnownNavalSnapshot` tracking in test 2). `null` when
  /// snapshot plumbing remained unavailable throughout the loop.
  final CtE2eNavalPanelSnapshot? lastKnownNavalSnapshot;

  /// Zero-based index of the iteration that produced the exit, or
  /// [E2eFleetReachTurnLoop.maxTurns] when [exit] is
  /// [E2eFleetReachLoopExit.loopExhausted]. Useful as a regression guard
  /// (e.g. a precheck exit must always carry `iterationsRun == 0`).
  final int iterationsRun;
}

/// Drives the per-turn fleet-reach loop shared by both `testWidgets` bodies
/// in `new_game_fleet_reaches_new_world_e2e_test.dart`.
///
/// Lifted from the pre-lift inline `for (var turnIdx = 0; ...)` loops that
/// were duplicated across both scenarios (fleet-reach + post-bundle
/// Explore). The two pre-lift bodies were structurally identical except for
/// (1) early-exit via `return` + per-branch `perf.timing('test_total', ...)`
/// in test 1 vs. `break` in test 2 and (2) the `lastKnownNavalSnapshot`
/// tracking used by test 2's post-loop diagnostics. The lifted form returns
/// an [E2eFleetReachLoopResult] so each call site can preserve its
/// scenario-specific post-loop behaviour without duplicating the loop body
/// (Refs GitHub #2336 AC1 / AC2 / Bottleneck 4).
///
/// The widget-test pin in `app/test/e2e_fleet_reach_turn_loop_test.dart`
/// carries the behavioural contract because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). A regression here would
/// either inflate the bundled-Explore retry path at `35 × ~5 s` (Bottleneck
/// 4) or cause the fleet-reach scenarios to short-circuit prematurely and
/// miss real regressions in `e2eFleetReachDoneFromCtSnapshotOnly` /
/// `e2eHarnessDetectsNonHomeFleetInNewWorld`.
///
/// Contract:
///
/// - Iterates at most [maxTurns] times (default
///   [kE2eDefaultFleetReachLoopMaxTurns]); each iteration starts with
///   `ensureUnderWallClock('turn loop start turnIdx=$turnIdx')` and
///   `perf.bumpCounter('turn_loop_iterations')` (mirrors the pre-lift
///   loops).
/// - Returns early with [E2eFleetReachLoopExit.reachedSnapshotPrecheck] /
///   [E2eFleetReachLoopExit.reachedSnapshotAfterDismiss] /
///   [E2eFleetReachLoopExit.reachedSnapshotAfterRegionTab] when
///   `e2eFleetReachDoneFromCtSnapshotOnly(ctE2eNavalPanelSnapshot)` holds at
///   the corresponding probe point.
/// - When `ctE2eNavalPanelSnapshot == null`, opens the naval panel via
///   [e2eOpenNavalPanel] (using [maxUiResponseWait] for both `timeout` and
///   `bottomSheetCloseTimeout`); when `e2eNavalPanelShowsNonHomeFleetInNewWorld`
///   then fires, closes the bottom sheet via [e2eCloseBottomSheet] and
///   returns [E2eFleetReachLoopExit.reachedInLoop].
/// - Captures `ctE2eNavalPanelSnapshot` into [E2eFleetReachLoopResult.lastKnownNavalSnapshot]
///   once per iteration before calling [e2eTryNavalMoveSegment] (matches
///   test 2's pre-lift `lastKnownNavalSnapshot = ctE2eNavalPanelSnapshot`).
/// - Calls [e2eTryNavalMoveSegment] with
///   `navalPanelAlreadyOpen: ctE2eNavalPanelSnapshot == null` (the
///   snapshot-backed path keeps the naval sheet open across iterations),
///   then [e2eCloseBottomSheet] regardless of outcome.
/// - Returns [E2eFleetReachLoopExit.reachedAfterMove] when
///   `e2eHarnessDetectsNonHomeFleetInNewWorld(tester, ctE2eNavalPanelSnapshot)`
///   fires after the move attempt.
/// - Calls [e2eAdvanceOneHumanTurn] and returns
///   [E2eFleetReachLoopExit.reachedSnapshotAfterTurn] when the snapshot
///   precheck satisfies post-turn.
/// - Closes the iteration with [e2eDismissTransientUi] +
///   `ensureUnderWallClock('after turn advance turnIdx=$turnIdx')`.
/// - Returns [E2eFleetReachLoopExit.loopExhausted] (with
///   `iterationsRun == maxTurns`) when no predicate fires within the
///   budget; callers fall through to their scenario-specific post-loop
///   behaviour.
///
/// The helper deliberately does **not** emit a `perf.timing('test_total', ...)`
/// marker — call sites map the [E2eFleetReachLoopResult.exit] to the legacy
/// `result=...` meta label themselves so the pre-lift telemetry keys remain
/// byte-identical.
Future<E2eFleetReachLoopResult> e2eFleetReachTurnLoop(
  WidgetTester tester,
  AppLocalizations l10n, {
  required E2ePerfLog perf,
  required void Function(String step) ensureUnderWallClock,
  Duration maxUiResponseWait = kE2eDefaultNavalMoveSegmentUiWait,
  int maxTurns = kE2eDefaultFleetReachLoopMaxTurns,
}) async {
  CtE2eNavalPanelSnapshot? lastKnownNavalSnapshot;
  for (var turnIdx = 0; turnIdx < maxTurns; turnIdx++) {
    ensureUnderWallClock('turn loop start turnIdx=$turnIdx');
    perf.bumpCounter('turn_loop_iterations');
    if (e2eFleetReachDoneFromCtSnapshotOnly(ctE2eNavalPanelSnapshot)) {
      return E2eFleetReachLoopResult(
        exit: E2eFleetReachLoopExit.reachedSnapshotPrecheck,
        lastKnownNavalSnapshot: lastKnownNavalSnapshot,
        iterationsRun: turnIdx,
      );
    }
    await e2eDismissTransientUi(tester, perf: perf);
    if (e2eFleetReachDoneFromCtSnapshotOnly(ctE2eNavalPanelSnapshot)) {
      return E2eFleetReachLoopResult(
        exit: E2eFleetReachLoopExit.reachedSnapshotAfterDismiss,
        lastKnownNavalSnapshot: lastKnownNavalSnapshot,
        iterationsRun: turnIdx,
      );
    }
    await e2eTapNewWorldRegionTabIfPresent(tester);
    if (e2eFleetReachDoneFromCtSnapshotOnly(ctE2eNavalPanelSnapshot)) {
      return E2eFleetReachLoopResult(
        exit: E2eFleetReachLoopExit.reachedSnapshotAfterRegionTab,
        lastKnownNavalSnapshot: lastKnownNavalSnapshot,
        iterationsRun: turnIdx,
      );
    }
    if (ctE2eNavalPanelSnapshot == null) {
      await e2eOpenNavalPanel(
        tester,
        perf: perf,
        timeout: maxUiResponseWait,
        bottomSheetCloseTimeout: maxUiResponseWait,
      );
      if (e2eNavalPanelShowsNonHomeFleetInNewWorld(tester)) {
        await e2eCloseBottomSheet(
          tester,
          perf: perf,
          overallTimeout: maxUiResponseWait,
        );
        return E2eFleetReachLoopResult(
          exit: E2eFleetReachLoopExit.reachedInLoop,
          lastKnownNavalSnapshot: lastKnownNavalSnapshot,
          iterationsRun: turnIdx,
        );
      }
    }
    if (ctE2eNavalPanelSnapshot != null) {
      lastKnownNavalSnapshot = ctE2eNavalPanelSnapshot;
    }
    await e2eTryNavalMoveSegment(
      tester,
      l10n,
      perf: perf,
      maxUiResponseWait: maxUiResponseWait,
      navalPanelAlreadyOpen: ctE2eNavalPanelSnapshot == null,
    );
    await e2eCloseBottomSheet(
      tester,
      perf: perf,
      overallTimeout: maxUiResponseWait,
    );
    if (e2eHarnessDetectsNonHomeFleetInNewWorld(
      tester,
      ctE2eNavalPanelSnapshot,
    )) {
      return E2eFleetReachLoopResult(
        exit: E2eFleetReachLoopExit.reachedAfterMove,
        lastKnownNavalSnapshot: lastKnownNavalSnapshot,
        iterationsRun: turnIdx,
      );
    }
    await e2eAdvanceOneHumanTurn(tester, l10n: l10n, perf: perf);
    if (e2eFleetReachDoneFromCtSnapshotOnly(ctE2eNavalPanelSnapshot)) {
      return E2eFleetReachLoopResult(
        exit: E2eFleetReachLoopExit.reachedSnapshotAfterTurn,
        lastKnownNavalSnapshot: lastKnownNavalSnapshot,
        iterationsRun: turnIdx,
      );
    }
    await e2eDismissTransientUi(tester, perf: perf);
    ensureUnderWallClock('after turn advance turnIdx=$turnIdx');
  }
  return E2eFleetReachLoopResult(
    exit: E2eFleetReachLoopExit.loopExhausted,
    lastKnownNavalSnapshot: lastKnownNavalSnapshot,
    iterationsRun: maxTurns,
  );
}
