/// Pins the widget-tree contract of
/// [e2ePickMoveDestinationAndConfirm]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The fleet-reach turn loop in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper via
/// `_tryNavalMoveSegment` up to `_kMaxNextTurnTapsForNwFleetReach (35)`
/// times per scenario. A silent rename / behavioural drift here would
/// either:
///
///   - Stall the loop at the per-call
///     [kE2eDefaultMoveFleetDialogBudget] cap (5 s) × 35 turns — Bottleneck
///     4 / H4 in `SPEC/program/e2e-integration-tests.md` § Determinism —
///     burning wall-clock issue #2336 § AC9 is shrinking; or
///   - Silently flip warp vs sea-radio selection and mask a real production
///     regression in `MoveFleetDialog`.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test layer
/// carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC4 / Bottleneck 4 / H4.
library;

// The production move-fleet dialog (`move_fleet_dialog.dart`) constructs
// `RadioListTile<_MovePick>` with the legacy `groupValue` / `onChanged` API;
// the AC1 helper matches on `runtimeType.toString().startsWith('RadioListTile<')`,
// so the test fixtures must build the same widget shape (not the newer
// RadioGroup-based API) for the pin to validate the production code path.
// Same pattern as `e2e_radio_list_tiles_in_alert_dialogs_test.dart`.
// ignore_for_file: deprecated_member_use

import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/move_dialog_widget_tester_harness.dart';


part 'support/pick_move_warp_part.dart';
part 'support/pick_move_sea_part.dart';
part 'support/pick_move_budget_part.dart';
part 'support/pick_move_constants_part.dart';

void main() {
  suppressLogsForTests();
  registerPickMoveWarpGroup();
  registerPickMoveSeaGroup();
  registerPickMoveBudgetGroup();
  registerPickMoveConstantsGroup();
}
