// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game shaped for the `naval_units_panel_part*` family.
///
/// Covers what those parts read from `game` / `humanPlayerIdWithFleets`:
/// - one human player ([kPanelTestHumanPlayerId]) with a defined
///   `capitalProvinceId` + `capitalTile` in the **old world** (so the panel can
///   resolve and label the Home Fleet);
/// - a Home Fleet ([homeFleetIdFor]) in port at the capital carrying two ships,
///   so the Split action and split flow render for the home row;
/// - a **non-home** fleet (`fleet_nh1`) at sea in the old world with two ships,
///   so the `Fleet <id>` row renders with Move/Split actions and the empty
///   `humanPlayerIdWithFleets` fleet filters are non-vacuous;
/// - provinces in **both** regions carrying `townTileKey`, plus
///   `portsByProvinceSeaboard` / `tileKeysByRegionAndProvince` entries so
///   sea-zone and port locate tile keys resolve like a generated map.
///
/// A non-owning player id (e.g. `'no-such-player'`) exercises the empty state.
/// This is the shape the heavier `naval_units_panel_part1` map-derived
/// assertions need; lighter parts simply ignore the unused richness.
Game buildNavalPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const capProvince = 'oldWorld|cap';
  const oldPort = 'oldWorld|p2';
  const newPort = 'newWorld|np1';
  const seaZoneId = 'sz0';
  final homeFleetId = homeFleetIdFor(human);
  return buildPanelTestGame(
    id: 'naval-panel-widget-test',
    oldWorldProvinces: const [
      Province(
        id: capProvince,
        regionId: ow,
        ownerId: human,
        displayName: 'Capital',
        townTileKey: 'oldWorld|cap|0|0',
      ),
      Province(
        id: oldPort,
        regionId: ow,
        ownerId: human,
        displayName: 'Porto',
        townTileKey: 'oldWorld|p2|0|0',
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: newPort,
        regionId: nw,
        ownerId: human,
        displayName: 'Newhaven',
        townTileKey: 'newWorld|np1|0|0',
      ),
    ],
    fleets: [
      Fleet(
        id: homeFleetId,
        ownerId: human,
        regionId: ow,
        inPortAtProvinceId: capProvince,
        ships: const [
          ShipInstance(id: 'h1', typeId: 'carrack'),
          ShipInstance(id: 'h2', typeId: 'galleon'),
        ],
      ),
      Fleet(
        id: 'fleet_nh1',
        ownerId: human,
        regionId: ow,
        seaZoneId: seaZoneId,
        ships: const [
          ShipInstance(id: 'n1', typeId: 'carrack'),
          ShipInstance(id: 'n2', typeId: 'carrack'),
        ],
      ),
    ],
    portsByProvinceSeaboard: const {
      'oldWorld|cap|$seaZoneId': 'oldWorld|cap|0|0',
    },
    tileKeysByRegionAndProvince: const {
      ow: {
        capProvince: ['oldWorld|cap|0|0'],
        oldPort: ['oldWorld|p2|0|0'],
      },
      nw: {
        newPort: ['newWorld|np1|0|0'],
      },
    },
    seaZoneDisplayNameById: const {'oldWorld|$seaZoneId': 'Northern Sea'},
    players: const [
      Player(
        id: human,
        displayName: 'Test Human',
        isHuman: true,
        capitalProvinceId: capProvince,
        capitalTile: CapitalTile(
          regionId: ow,
          provinceId: capProvince,
          x: 0,
          y: 0,
        ),
      ),
    ],
  );
}
