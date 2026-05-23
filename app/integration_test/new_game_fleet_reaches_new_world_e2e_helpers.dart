part of 'new_game_fleet_reaches_new_world_e2e_test.dart';

/// Locked full-init may succeed only after [GameService] bumps `mapSeed` on a
/// topology/assigner retry (`effectiveSeed + 100003`, …), producing longer
/// coast→warp→New World paths than nominal seed-42 alone. Keep this above the
/// worst observed CI need (Refs #1849 / PR 1849).
const int _kMaxNextTurnTapsForNwFleetReach = 35;

/// Hard cap for any single “wait until UI shows X” poll (`waitUntilFound`,
/// next-turn label settle, panel-open loops). Fail immediately when exceeded.
const Duration _kMaxUiResponseWait = Duration(seconds: 5);

/// Entire fleet e2e must finish within this wall clock (success or guarded fail).
///
/// Aliases the shared [kE2eMaxWallClock] (`e2e_test_shared.dart`) so all three
/// E2E scenarios use the same 5-minute cap from
/// `SPEC/program/e2e-integration-tests.md` § Determinism PR runtime rule
/// (Refs GitHub #2336).
const Duration _kFleetE2eMaxWallClock = kE2eMaxWallClock;

/// Region-tab tap helpers `_tapNewWorldRegionTabIfPresent` and
/// `_tapOldWorldRegionTab` were lifted into [e2eTapNewWorldRegionTabIfPresent]
/// and [e2eTapOldWorldRegionTab] (`e2e_test_shared.dart`) so the
/// `kCtE2ERegionTabNewWorldKey` and `CtChoiceChip + region_oldWorld` tap
/// contracts are shared and unit-pinned (Refs GitHub #2336 AC1 / AC2). Call
/// sites consume the public names directly; `_tryNavalMoveSegment` below
/// composes them with [openNavalPanel] / [tapMoveOnFirstNonHomeFleet]
/// without changing observable behavior.

/// `_tapMoveOnFirstNonHomeFleet` was lifted into
/// [e2eTapMoveOnFirstNonHomeFleet] (`e2e_test_shared_panels.dart`) so the
/// non-home Move-tap contract is shared and unit-pinned (Refs GitHub #2336
/// AC1 / AC2). The fleet-reach loop calls this helper through
/// `_tryNavalMoveSegment` up to `_kMaxNextTurnTapsForNwFleetReach (35)`
/// times per scenario; the widget-test pin in
/// `app/test/e2e_tap_move_on_first_non_home_fleet_test.dart` carries the
/// behavioural contract because the integration suite cannot validate it
/// directly today (`SPEC/program/e2e-integration-tests.md` § CI).

/// Generic-instantiation `RadioListTile<…>` lookup inside any mounted
/// [AlertDialog] moved to [e2eRadioListTilesInAlertDialogs]
/// (`e2e_test_shared.dart`) so the `runtimeType.toString().startsWith`
/// contract is unit-pinned and shared across scenarios (Refs GitHub
/// #2336 AC1 / AC2). The widget-test pin in
/// `app/test/e2e_radio_list_tiles_in_alert_dialogs_test.dart` guards
/// against a silent rename / scope-removal that would re-introduce
/// false positives in move-segment dialogs.

/// `_pickMoveDestinationAndConfirm` was lifted into
/// [e2ePickMoveDestinationAndConfirm] (`e2e_test_shared_panels.dart`) so the
/// move-dialog warp-tap / sea-radio / drag-probe contract is shared and
/// unit-pinned (Refs GitHub #2336 AC1 / AC2 / AC4 / Bottleneck 4 / H4). The
/// fleet-reach loop calls the lifted form through the AC1 barrel alias
/// `pickMoveDestinationAndConfirm` (`e2e_helpers.dart`). The widget-test pin
/// in `app/test/e2e_pick_move_destination_and_confirm_test.dart` guards
/// against silent regressions because the integration suite cannot validate
/// this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). A regression here would
/// stall the fleet-reach loop at the per-call
/// [kE2eDefaultMoveFleetDialogBudget] cap × `_kMaxNextTurnTapsForNwFleetReach
/// (35)` turns — Bottleneck 4 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism.

Future<void> _tryNavalMoveSegment(
  WidgetTester tester,
  AppLocalizations l10n, {
  bool useNewWorldMapTabFirst = false,
  bool allowWarpDestinations = true,

  /// When true, the naval panel is already open from a prior [openNavalPanel]
  /// in the same turn iteration — skip close/reopen (Refs #2336 Bottleneck 4).
  bool navalPanelAlreadyOpen = false,
  E2ePerfLog? perf,
}) async {
  final phaseSw = Stopwatch()..start();
  if (useNewWorldMapTabFirst) {
    await e2eTapNewWorldRegionTabIfPresent(tester);
  } else {
    await e2eTapOldWorldRegionTab(tester, l10n);
  }
  if (!navalPanelAlreadyOpen) {
    await openNavalPanel(
      tester,
      perf: perf,
      timeout: _kMaxUiResponseWait,
      bottomSheetCloseTimeout: _kMaxUiResponseWait,
    );
  }
  final tappedMove = await tapMoveOnFirstNonHomeFleet(tester);
  if (!tappedMove) {
    perf?.timing(
      'fleet_move_segment',
      phaseSw.elapsed,
      meta: 'result=no_non_home_move_control',
    );
    return;
  }
  await waitUntilFound(
    tester,
    find.byType(AlertDialog),
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
      () => find.byType(AlertDialog).evaluate().isEmpty,
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
  if (find.byType(AlertDialog).evaluate().isNotEmpty) {
    await pickMoveDestinationAndConfirm(
      tester,
      l10n,
      allowWarpDestinations: allowWarpDestinations,
      moveDialogBudget: _kMaxUiResponseWait,
    );
  }
  perf?.timing('fleet_move_segment', phaseSw.elapsed);
}
