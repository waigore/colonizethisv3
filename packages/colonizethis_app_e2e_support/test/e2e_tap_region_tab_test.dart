/// Pins the **tap-and-settle** contract of `e2eTapNewWorldRegionTabIfPresent`
/// and `e2eTapOldWorldRegionTab` (`app/integration_test/e2e_test_shared.dart`),
/// including the **already-selected short-circuit** that skips the tap +
/// post-tap settle when the corresponding chip is already selected.
///
/// Both helpers were lifted from
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` so the
/// `kCtE2ERegionTabNewWorldKey` and `CtChoiceChip + region_oldWorld` tap
/// contracts are shared, canonical, and unit-pinned at the widget layer
/// (Refs GitHub #2336 AC1 / AC2 / AC5). They sit on the fleet-reach hot path
/// (`_tryNavalMoveSegment`, `_awaitNwCoastalOrVisibleLandForBundledExploreE2e`)
/// inside the `_kMaxNextTurnTapsForNwFleetReach = 35` turn loop, so a silent
/// regression — for example dropping the `.hitTestable()` guard, throwing on
/// timeout, skipping the chip-selected poll, or dropping the
/// already-selected short-circuit — would regress the wall-clock-bound paths
/// #2336 is shrinking. The short-circuit in particular removes the redundant
/// tap + 500ms-bounded post-tap settle that would otherwise fire on every
/// fleet-reach turn iteration after the first call selects the NW chip.
///
/// Because `integration_test/` runs behind a no-op `app_e2e_linux` lane today
/// (`SPEC/program/e2e-integration-tests.md` § CI), these widget-test pins are
/// the only per-PR enforcement gate for the tap contracts. The existing
/// `e2e_region_chip_selected_test.dart` pins the **predicate** branches of the
/// `e2eOldWorldRegionChipAppearsSelected` / `e2eNewWorldRegionChipAppearsSelected`
/// helpers; this file pins the **tap-and-poll wrappers** that compose them.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/tap_region_tab_harness.dart';
import 'support/tap_region_tab_nw_group.dart';
import 'support/tap_region_tab_ow_group.dart';
import 'support/tap_region_tab_ow_ignore_pointer_group.dart';

void main() {
  suppressLogsForTests();
  registerTapRegionTabNwGroup();
  registerTapRegionTabOwGroup();
  registerTapRegionTabOwIgnorePointerGroup();
}
