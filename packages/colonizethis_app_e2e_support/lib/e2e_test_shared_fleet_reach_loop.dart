import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eNavalPanelSnapshot, ctE2eNavalPanelSnapshot;
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

export 'e2e_test_shared_fleet_reach_loop_types.dart';

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
