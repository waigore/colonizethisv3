// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game shaped for the `military_units_panel_*` family.
///
/// Covers what those parts read from `game` / `humanPlayerIdWithUnits`:
/// - one human player ([kPanelTestHumanPlayerId]) owning military regiments in
///   **both** regions, each grouped under a non-home [Army] stationed in a
///   province that carries a `displayName` and a `townTileKey` (so region
///   headers, "N regiments · province" subtitles, Move/Split actions, and the
///   Locate tile-key all render exactly as with a generated map);
/// - the old-world army has two regiments so Split renders; the new-world army
///   keeps a single regiment to exercise the minimal block.
///
/// A non-owning player id (e.g. `'no-such-player'`) exercises the empty state.
/// No fleets are included: the part-family assertions only gate on land
/// military presence, so the lighter shape keeps coverage intact.
Game buildMilitaryPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const oldProvince = 'oldWorld|p1';
  const newProvince = 'newWorld|np1';
  const type = kPanelTestRegimentType;
  return buildPanelTestGame(
    id: 'military-panel-widget-test',
    oldWorldProvinces: const [
      Province(
        id: oldProvince,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Alpha',
        townTileKey: 'oldWorld|p1|0|0',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'reg_old_1',
        type: type,
        ownerId: human,
        locationProvinceId: oldProvince,
        medals: 1,
      ),
      Unit(
        id: 'reg_old_2',
        type: type,
        ownerId: human,
        locationProvinceId: oldProvince,
        medals: 2,
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: newProvince,
        regionId: 'newWorld',
        ownerId: human,
        displayName: 'Gamma',
        townTileKey: 'newWorld|np1|0|0',
      ),
    ],
    newWorldUnits: [
      Unit(
        id: 'reg_new_1',
        type: type,
        ownerId: human,
        locationProvinceId: newProvince,
        medals: 0,
      ),
    ],
    armies: const [
      Army(
        id: 'army_old',
        ownerId: human,
        regionId: 'oldWorld',
        stationedProvinceId: oldProvince,
        regimentUnitIds: ['reg_old_1', 'reg_old_2'],
        isHomeArmy: false,
      ),
      Army(
        id: 'army_new',
        ownerId: human,
        regionId: 'newWorld',
        stationedProvinceId: newProvince,
        regimentUnitIds: ['reg_new_1'],
        isHomeArmy: false,
      ),
    ],
  );
}
