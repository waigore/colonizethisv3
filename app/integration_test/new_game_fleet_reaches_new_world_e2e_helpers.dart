part of 'new_game_fleet_reaches_new_world_e2e_test.dart';

/// Legacy file-scope constants (`_kMaxNextTurnTapsForNwFleetReach`,
/// `_kMaxUiResponseWait`, `_kFleetE2eMaxWallClock`) were retired from this
/// `part` file because each was a value-identical private alias for a
/// shared public constant on the AC1 barrel (Refs GitHub #2336 AC1 / AC2).
/// Call sites in `new_game_fleet_reaches_new_world_e2e_test.dart` now consume
/// the public names directly:
///
/// | Retired private (legacy literal)                | Public replacement                  | Source                                  |
/// |-------------------------------------------------|-------------------------------------|-----------------------------------------|
/// | `_kMaxNextTurnTapsForNwFleetReach` (`35`)       | [kE2eDefaultFleetReachLoopMaxTurns] | `e2e_test_shared_fleet_reach_loop.dart` |
/// | `_kMaxUiResponseWait` (`Duration(seconds: 5)`)  | [kE2eDefaultNavalMoveSegmentUiWait] | `e2e_test_shared_panels.dart`           |
/// | `_kFleetE2eMaxWallClock` (`kE2eMaxWallClock`)   | [kE2eMaxWallClock]                  | `e2e_test_shared.dart`                  |
///
/// The byte-identical legacy-literal contract is unit-pinned in
/// `app/test/e2e_fleet_reach_turn_loop_test.dart` (35-turn cap),
/// `app/test/e2e_try_naval_move_segment_test.dart` (5 s UI response cap),
/// `app/test/e2e_make_wall_clock_guard_test.dart` (5-minute wall-clock cap),
/// and the AC2 source-of-truth pin in
/// `app/test/new_game_fleet_reaches_new_world_e2e_test_no_private_constants_test.dart`
/// guards against silent re-introduction of any file-scope `_k*` constant in
/// the integration test library.

/// Region-tab tap helpers `_tapNewWorldRegionTabIfPresent` and
/// `_tapOldWorldRegionTab` were lifted into [e2eTapNewWorldRegionTabIfPresent]
/// and [e2eTapOldWorldRegionTab] (`e2e_test_shared.dart`) so the
/// `kCtE2ERegionTabNewWorldKey` and `CtChoiceChip + region_oldWorld` tap
/// contracts are shared and unit-pinned (Refs GitHub #2336 AC1 / AC2). Call
/// sites consume the public names directly; [tryNavalMoveSegment] composes
/// them with [openNavalPanel] / [tapMoveOnFirstNonHomeFleet] /
/// [pickMoveDestinationAndConfirm] without changing observable behavior.

/// `_tapMoveOnFirstNonHomeFleet` was lifted into
/// [e2eTapMoveOnFirstNonHomeFleet] (`e2e_test_shared_panels.dart`) so the
/// non-home Move-tap contract is shared and unit-pinned (Refs GitHub #2336
/// AC1 / AC2). The fleet-reach loop calls this helper through
/// [tryNavalMoveSegment] up to [kE2eDefaultFleetReachLoopMaxTurns] (35)
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
/// [kE2eDefaultMoveFleetDialogBudget] cap ×
/// [kE2eDefaultFleetReachLoopMaxTurns] (35) turns — Bottleneck 4 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism.

/// `_tryNavalMoveSegment` was lifted into [e2eTryNavalMoveSegment]
/// (`e2e_test_shared_panels.dart`) so the region-tab / naval-open / Move-tap /
/// move-dialog contract is shared and unit-pinned (Refs GitHub #2336 AC1 /
/// AC2 / Bottleneck 4 / H1–H4). The fleet-reach loop calls the lifted form
/// through the AC1 barrel alias `tryNavalMoveSegment` (`e2e_helpers.dart`).
/// The widget-test pin in `app/test/e2e_try_naval_move_segment_test.dart`
/// guards against silent regressions because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
