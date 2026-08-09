import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_panels.dart';

/// Default per-call UI wait for [e2eTryNavalMoveSegment] (naval panel open,
/// move-dialog picker budget). Matches the pre-lift private
/// `_kMaxUiResponseWait = Duration(seconds: 5)` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` (Refs GitHub #2336
/// Bottleneck 4 / H1–H3).
const Duration kE2eDefaultNavalMoveSegmentUiWait =
    kE2eDefaultMoveFleetDialogBudget;

/// Composes region-tab selection, optional naval-panel open, non-home Move tap,
/// and move-dialog destination pick for one fleet-reach turn iteration.
///
/// Lifted from the formerly private `_tryNavalMoveSegment` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` (Refs GitHub #2336 AC1
/// / AC2 / Bottleneck 4 / H1–H4). The fleet-reach loop in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper up to
/// `_kMaxNextTurnTapsForNwFleetReach (35)` times per scenario; the widget-test
/// pin in `app/test/e2e_try_naval_move_segment_test.dart` carries the
/// behavioural contract because the integration suite cannot validate it
/// directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
///
/// Contract:
///
/// - When [useNewWorldMapTabFirst] is `true`, taps the New World region tab
///   via [e2eTapNewWorldRegionTabIfPresent]; otherwise taps the Old World tab
///   via [e2eTapOldWorldRegionTab].
/// - Opens the naval panel via [e2eOpenNavalPanel] unless
///   [navalPanelAlreadyOpen] is `true` (Refs #2336 Bottleneck 4 — avoids
///   redundant close/reopen inside the 35-turn loop).
/// - Invokes [e2eTapMoveOnFirstNonHomeFleet]; when it returns `false`, records
///   `result=no_non_home_move_control` on [perf] and returns without opening a
///   move dialog.
/// - Waits up to 2 s for an [AlertDialog] after Move (`wait_until_found_move_
///   dialog_after_tap`).
/// - When `l10n.moveFleet_noAdjacentSeaZones` is visible, taps
///   `l10n.common_cancel`, pumps until the dialog dismisses, records
///   `result=no_legal_step` on [perf], and returns.
/// - Otherwise, when an [AlertDialog] remains mounted, delegates to
///   [e2ePickMoveDestinationAndConfirm] with [allowWarpDestinations] and
///   [maxUiResponseWait] as [moveDialogBudget].
Future<void> e2eTryNavalMoveSegment(
  WidgetTester tester,
  AppLocalizations l10n, {
  bool useNewWorldMapTabFirst = false,
  bool allowWarpDestinations = true,
  bool navalPanelAlreadyOpen = false,
  E2ePerfLog? perf,
  Duration maxUiResponseWait = kE2eDefaultNavalMoveSegmentUiWait,
}) async {
  final phaseSw = Stopwatch()..start();
  if (useNewWorldMapTabFirst) {
    await e2eTapNewWorldRegionTabIfPresent(tester);
  } else {
    await e2eTapOldWorldRegionTab(tester, l10n);
  }
  if (!navalPanelAlreadyOpen) {
    await e2eOpenNavalPanel(
      tester,
      perf: perf,
      timeout: maxUiResponseWait,
      bottomSheetCloseTimeout: maxUiResponseWait,
    );
  }
  final tappedMove = await e2eTapMoveOnFirstNonHomeFleet(tester);
  if (!tappedMove) {
    perf?.timing(
      'fleet_move_segment',
      phaseSw.elapsed,
      meta: 'result=no_non_home_move_control',
    );
    return;
  }
  await e2eWaitUntilFound(
    tester,
    e2eMoveFleetDialogFinder(),
    timeout: const Duration(seconds: 2),
    phaseName: 'wait_until_found_move_dialog_after_tap',
  );
  // No legal sea-step this turn: close dialog and rely on the outer loop +
  // next turn (Refs #1831 heuristic path).
  if (find.text(l10n.moveFleet_noAdjacentSeaZones).evaluate().isNotEmpty) {
    final cancel = find.text(l10n.common_cancel).hitTestable();
    expect(cancel, findsOneWidget);
    await tester.tap(cancel, warnIfMissed: false);
    await e2ePumpUntil(
      tester,
      () => e2eMoveFleetDialogFinder().evaluate().isEmpty,
      timeout: const Duration(seconds: 2),
      perf: perf,
      phaseName: 'pump_until_cancel_move_dialog_closed',
    );
    perf?.timing(
      'fleet_move_segment',
      phaseSw.elapsed,
      meta: 'result=no_legal_step',
    );
    return;
  }
  if (e2eMoveFleetDialogFinder().evaluate().isNotEmpty) {
    await e2ePickMoveDestinationAndConfirm(
      tester,
      l10n,
      allowWarpDestinations: allowWarpDestinations,
      moveDialogBudget: maxUiResponseWait,
    );
  }
  perf?.timing('fleet_move_segment', phaseSw.elapsed);
}
