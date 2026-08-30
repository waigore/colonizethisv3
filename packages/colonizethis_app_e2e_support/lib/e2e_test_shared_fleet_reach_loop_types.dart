import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eNavalPanelSnapshot;

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
