import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eNavalPanelSnapshot, ctE2eNavalPanelSnapshot;
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Default per-call UI response cap for [e2eEnsureNonHomeFleetInNwAfterLoop].
///
/// Mirrors the legacy private `_kMaxUiResponseWait = 5s` used by the
/// pre-lift inline post-loop blocks in both `testWidgets` bodies of
/// `new_game_fleet_reaches_new_world_e2e_test.dart` (Refs GitHub #2336
/// AC1 / AC2 / Bottleneck 4). A silent change would either burn extra
/// time per scenario on the conditional `openNavalPanel` /
/// `closeBottomSheet` calls or short-circuit them before the snapshot
/// plumbing settles, masking a real reach regression as a clean pass.
const Duration kE2eDefaultFinalNavalReachCheckUiWait = Duration(seconds: 5);

/// Result of [e2eEnsureNonHomeFleetInNwAfterLoop].
///
/// Carries the `ctE2eNavalPanelSnapshot` value observed after the
/// conditional [e2eOpenNavalPanel] probe so test 2
/// (`new_game_fleet_explore_enabled_post_bundle`) can update its
/// `lastKnownNavalSnapshot` tracker — the diagnostic surface composed by
/// [e2eBundledExploreRejectionDiagnostics] depends on the most recently
/// observed naval snapshot rather than the live global, which a later
/// `e2eAdvanceOneHumanTurn` may have nulled out.
///
/// Test 1 (`new_game_fleet_reaches_new_world`) ignores
/// [lastKnownNavalSnapshot] because its failure path does not include
/// the bundled-Explore diagnostics.
class E2eFinalNavalReachCheckResult {
  const E2eFinalNavalReachCheckResult({required this.lastKnownNavalSnapshot});

  /// `ctE2eNavalPanelSnapshot` captured at the post-conditional-open
  /// probe point. `null` when snapshot plumbing remained unavailable
  /// throughout the helper's execution; mirrors the pre-lift conditional
  /// `if (ctE2eNavalPanelSnapshot != null) { lastKnownNavalSnapshot = ... }`
  /// guard in test 2.
  final CtE2eNavalPanelSnapshot? lastKnownNavalSnapshot;
}

/// Verifies that a non-home human fleet has reached the New World after
/// the per-turn [e2eFleetReachTurnLoop] body either exhausted its
/// [kE2eDefaultFleetReachLoopMaxTurns] budget (test 1) or returned
/// without firing a precheck (test 2).
///
/// Lifted from the duplicated post-loop blocks in both `testWidgets`
/// bodies of `new_game_fleet_reaches_new_world_e2e_test.dart` (Refs
/// GitHub #2336 AC1 / AC2 / Bottleneck 4). The two pre-lift inline
/// blocks were structurally identical except for (1) the
/// scenario-specific fail message and (2) test 2's conditional
/// `lastKnownNavalSnapshot` capture consumed by the bundled-Explore
/// rejection diagnostics. Call sites compose the fail message via
/// [failureMessageBuilder] and assign the captured snapshot through
/// [E2eFinalNavalReachCheckResult.lastKnownNavalSnapshot] when they
/// need it.
///
/// Contract:
///
/// - Calls [e2eDismissTransientUi] first to clear any leftover dialog
///   or snackbar that the loop's last iteration may have left mounted.
/// - Calls [e2eTapNewWorldRegionTabIfPresent] so the naval panel scopes
///   to the New World region before the harness + widget snapshot is
///   read.
/// - If `!e2eFleetReachDoneFromCtSnapshotOnly(ctE2eNavalPanelSnapshot)`,
///   opens the naval panel via [e2eOpenNavalPanel] using
///   [maxUiResponseWait] for both `timeout` and
///   `bottomSheetCloseTimeout` so the snapshot plumbing + widget tree
///   can be inspected. When the snapshot already reports reach, the
///   open call is skipped to keep the legacy short-circuit semantics.
/// - Captures the current `ctE2eNavalPanelSnapshot` (which may have
///   been updated by the conditional open) into
///   [E2eFinalNavalReachCheckResult.lastKnownNavalSnapshot]. Call
///   sites that mirror test 2's `if (ctE2eNavalPanelSnapshot != null)`
///   guard can apply the same null check on the returned field.
/// - If `!e2eHarnessDetectsNonHomeFleetInNewWorld(tester, snapshot)`,
///   calls `fail(failureMessageBuilder(tester.takeException()))` so the
///   scenario-specific fail message preserves the legacy "Last
///   exception: ${tester.takeException()}" suffix the inline blocks
///   appended.
/// - Calls [e2eCloseBottomSheet] using [maxUiResponseWait] for the
///   overall timeout so the panel does not leak across into the
///   caller's next phase (matches the pre-lift bookend).
/// - Returns [E2eFinalNavalReachCheckResult] with the captured
///   snapshot.
///
/// The widget-test pin in
/// `app/test/e2e_ensure_non_home_fleet_in_nw_after_loop_test.dart`
/// carries the behavioural contract because the integration suite
/// cannot validate this directly today (`app_e2e_linux` is a no-op
/// per `SPEC/program/e2e-integration-tests.md` § CI). A regression
/// that swapped the order of `dismissTransientUi` /
/// `tapNewWorldRegionTabIfPresent` would either leave a stale region
/// chip selected or read the harness against the wrong region; one
/// that dropped the conditional `openNavalPanel` would mask a real
/// reach failure as a clean exit; one that called the failure
/// builder with the wrong argument shape would orphan the legacy
/// "Last exception:" suffix and degrade triage on CI failures.
Future<E2eFinalNavalReachCheckResult> e2eEnsureNonHomeFleetInNwAfterLoop(
  WidgetTester tester, {
  required E2ePerfLog perf,
  required String Function(Object? lastException) failureMessageBuilder,
  Duration maxUiResponseWait = kE2eDefaultFinalNavalReachCheckUiWait,
}) async {
  await e2eDismissTransientUi(tester, perf: perf);
  await e2eTapNewWorldRegionTabIfPresent(tester);
  if (!e2eFleetReachDoneFromCtSnapshotOnly(ctE2eNavalPanelSnapshot)) {
    await e2eOpenNavalPanel(
      tester,
      perf: perf,
      timeout: maxUiResponseWait,
      bottomSheetCloseTimeout: maxUiResponseWait,
    );
  }
  final CtE2eNavalPanelSnapshot? capturedSnapshot = ctE2eNavalPanelSnapshot;
  if (!e2eHarnessDetectsNonHomeFleetInNewWorld(tester, capturedSnapshot)) {
    fail(failureMessageBuilder(tester.takeException()));
  }
  await e2eCloseBottomSheet(
    tester,
    perf: perf,
    overallTimeout: maxUiResponseWait,
  );
  return E2eFinalNavalReachCheckResult(
    lastKnownNavalSnapshot: capturedSnapshot,
  );
}
