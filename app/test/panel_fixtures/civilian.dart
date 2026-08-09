// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game shaped for the `civilian_units_panel_part*` family.
///
/// Covers what those parts read from `game`:
/// - one human player ([kPanelTestHumanPlayerId]) owning idle civilians of the
///   types the panel groups/labels (Builder, Explorer, Engineer, Merchant), in
///   **both** regions, each with a `tileKey` and a `locationProvinceId`;
/// - allowed work targets exist for those types so the assign-menu assertions
///   run;
/// - one in-progress (working) civilian so the in-progress cancel path renders.
///
/// A non-owning player id (e.g. `'no-such-player'`) exercises the empty state.
Game buildCivilianPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const p1 = 'oldWorld|p1';
  const np1 = 'newWorld|np1';
  return buildPanelTestGame(
    id: 'civilian-panel-widget-test',
    oldWorldProvinces: const [
      Province(
        id: p1,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Alpha',
      ),
      Province(
        id: 'oldWorld|p2',
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Beta',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'civ_builder',
        type: kUnitTypeBuilder,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|0|0',
      ),
      Unit(
        id: 'civ_explorer',
        type: kUnitTypeExplorer,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|0|1',
      ),
      Unit(
        id: 'civ_engineer',
        type: kUnitTypeEngineer,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|1|0',
      ),
      Unit(
        id: 'civ_merchant',
        type: kUnitTypeMerchant,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|1|1',
      ),
      Unit(
        id: 'civ_working',
        type: kUnitTypeBuilder,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|2|0',
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetBuildImprovement,
          tileKey: 'oldWorld|p1|2|0',
          totalTurns: 5,
          remainingTurns: 2,
        ),
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: np1,
        regionId: 'newWorld',
        ownerId: human,
        displayName: 'Gamma',
      ),
    ],
    newWorldUnits: [
      Unit(
        id: 'civ_explorer_nw',
        type: kUnitTypeExplorer,
        ownerId: human,
        locationProvinceId: np1,
        tileKey: 'newWorld|np1|0|0',
      ),
    ],
  );
}
