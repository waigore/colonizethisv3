import 'e2e_test_shared_fleet_reach_loop.dart';

/// Maps an [E2eFleetReachLoopExit] to the `meta` label
/// `perf.timing('test_total', ..., meta: '...')` should emit when the
/// fleet-reach scenario in `new_game_fleet_reaches_new_world_e2e_test.dart`
/// early-returns after [e2eFleetReachTurnLoop].
///
/// Lifted from the inline `switch (loopResult.exit) { ... }` block in the
/// `new_game → non-home fleet at sea in New World` `testWidgets` so the
/// exit-to-`test_total`-meta mapping is shared and unit-pinned (Refs GitHub
/// #2336 AC1 / AC2 / Bottleneck 4). The post-bundle scenario does not call
/// this helper because it always continues with the post-loop checks
/// regardless of the loop's exit branch.
///
/// Returns the legacy `result=<branch>` string verbatim for every
/// non-[E2eFleetReachLoopExit.loopExhausted] value so downstream log
/// scrapers and AC8 dashboards keyed on those labels remain stable across
/// the lift. A regression that renamed any of the strings, dropped the
/// special **`reachedSnapshotAfterRegionTab` → `result=reached_snapshot_precheck`**
/// legacy mapping, or returned a non-null value for
/// [E2eFleetReachLoopExit.loopExhausted] would either orphan a dashboard
/// or short-circuit the post-loop final-naval-check path that the
/// `loopExhausted` branch deliberately falls through into.
///
/// Returns `null` for [E2eFleetReachLoopExit.loopExhausted] so the caller
/// continues with the post-loop final-naval-check path; that check emits
/// its own `result=final_check` meta when it completes. The widget-test
/// pin in
/// `app/test/e2e_fleet_reach_loop_exit_test_total_meta_label_test.dart`
/// carries the behavioural contract because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
String? e2eFleetReachLoopExitTestTotalMetaLabel(E2eFleetReachLoopExit exit) {
  switch (exit) {
    case E2eFleetReachLoopExit.reachedSnapshotPrecheck:
      return 'result=reached_snapshot_precheck';
    case E2eFleetReachLoopExit.reachedSnapshotAfterDismiss:
      return 'result=reached_snapshot_after_dismiss';
    case E2eFleetReachLoopExit.reachedSnapshotAfterRegionTab:
      // Legacy label pin: pre-lift loop emitted `reached_snapshot_precheck`
      // here (not `..._after_region_tab`). Preserved byte-identical so the
      // downstream `E2E_TIMING|...|meta=result=...` log scrapers and
      // dashboards keyed on the legacy label stay attributed to the same
      // exit — see [E2eFleetReachLoopExit.reachedSnapshotAfterRegionTab]
      // doc-comment for the historical context (Refs GitHub #2336 AC1 /
      // AC2).
      return 'result=reached_snapshot_precheck';
    case E2eFleetReachLoopExit.reachedInLoop:
      return 'result=reached_in_loop';
    case E2eFleetReachLoopExit.reachedAfterMove:
      return 'result=reached_after_move';
    case E2eFleetReachLoopExit.reachedSnapshotAfterTurn:
      return 'result=reached_snapshot_after_turn';
    case E2eFleetReachLoopExit.loopExhausted:
      return null;
  }
}
