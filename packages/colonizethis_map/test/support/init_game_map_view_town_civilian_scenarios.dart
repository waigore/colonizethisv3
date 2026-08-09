import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_fixtures.dart';

/// Shared game/scenario builders for town and civilian marker view-builder tests.
/// Refs #4297 wave-5 test densify.

Game townPortSepGame() => minimalGame(
  id: 'townPortSep',
  oldWorldProvinces: const [
    Province(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      townTileKey: 'oldWorld|p1|0|0',
    ),
  ],
  portsByProvinceSeaboard: const {
    'oldWorld|p1|seaboard': 'oldWorld|p1|2|0',
  },
);

DualRegionViewScenario townPortSepScenario(Game game) => dualRegionScenario(
  game: game,
  oldWorldGrid: [
    ['p1', 'p1', 'p1'],
    ['p1', 'p1', 's1'],
  ],
  oldWorldTopology: regionTopology(
    regionId: 'oldWorld',
    provinceIds: const ['p1'],
    seaZoneIds: const ['s1'],
    edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
  ),
);

Game townNonPlayerGame() => minimalGame(
  id: 'town_non_player',
  oldWorldProvinces: const [
    Province(
      id: 'oldWorld|pPlayer',
      regionId: 'oldWorld',
      ownerId: 'gp1',
      townTileKey: 'oldWorld|pPlayer|0|0',
    ),
    Province(
      id: 'oldWorld|pMinor',
      regionId: 'oldWorld',
      ownerId: 'minor1',
      townTileKey: 'oldWorld|pMinor|1|0',
    ),
  ],
  players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
  minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
);

DualRegionViewScenario townNonPlayerScenario(Game game) => dualRegionScenario(
  game: game,
  oldWorldGrid: const [
    ['pPlayer', 'pMinor'],
  ],
  oldWorldTopology: regionTopology(
    regionId: 'oldWorld',
    provinceIds: const ['pPlayer', 'pMinor'],
    edges: const [TopologyEdge(id1: 'pPlayer', id2: 'pMinor')],
  ),
);

Game townPortCapGame() => minimalGame(
  id: 'townPortCap',
  oldWorldProvinces: const [
    Province(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      ownerId: 'gp1',
      townTileKey: 'oldWorld|p1|1|1',
    ),
  ],
  players: const [
    Player(
      id: 'gp1',
      displayName: 'GP',
      isHuman: true,
      capitalProvinceId: 'oldWorld|p1',
      capitalTile: CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      ),
    ),
  ],
  portsByProvinceSeaboard: const {'oldWorld|p1|sb': 'oldWorld|p1|0|0'},
);

DualRegionViewScenario townPortCapScenario(Game game) => dualRegionScenario(
  game: game,
  oldWorldGrid: [
    ['p1', 's1'],
    ['p1', 'p1'],
  ],
  oldWorldTopology: regionTopology(
    regionId: 'oldWorld',
    provinceIds: const ['p1'],
    seaZoneIds: const ['s1'],
    edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
  ),
);

Game townPortFallGame() => minimalGame(
  id: 'townPortFall',
  oldWorldProvinces: const [
    Province(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      townTileKey: 'oldWorld|p1|1|1',
    ),
  ],
  portsByProvinceSeaboard: const {'oldWorld|p1|sb': 'oldWorld|p1|1|1'},
);

DualRegionViewScenario townPortFallScenario(Game game) => dualRegionScenario(
  game: game,
  oldWorldGrid: [
    ['p1', 'p1'],
    ['p1', 'p1'],
  ],
  oldWorldTopology: regionTopology(
    regionId: 'oldWorld',
    provinceIds: const ['p1'],
    seaZoneIds: const ['s1'],
    edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
  ),
);

Game civilianMarkersGame() => minimalGame(
  id: 'civilian_markers',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
    Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
    Province(id: 'oldWorld|p3', regionId: 'oldWorld'),
  ],
  oldWorldUnits: [
    Unit(
      id: 'u_builder',
      type: kUnitTypeBuilder,
      ownerId: 'gp_human',
      locationProvinceId: 'oldWorld|p1',
      tileKey: 'oldWorld|p1|0|0',
      status: UnitStatus.working,
      assignedTileKey: 'oldWorld|p1|0|0',
    ),
    Unit(
      id: 'u_spy',
      type: kUnitTypeSpy,
      ownerId: 'gp_human',
      locationProvinceId: 'oldWorld|p1',
      tileKey: 'oldWorld|p1|0|0',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_engineer',
      type: kUnitTypeEngineer,
      ownerId: 'gp_human',
      locationProvinceId: 'oldWorld|p2',
      tileKey: 'oldWorld|p2|1|0',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_ai_builder',
      type: kUnitTypeBuilder,
      ownerId: 'gp_ai',
      locationProvinceId: 'oldWorld|p3',
      tileKey: 'oldWorld|p3|2|0',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_human_military',
      type: 'pikemen',
      ownerId: 'gp_human',
      locationProvinceId: 'oldWorld|p1',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_other_region',
      type: kUnitTypeMerchant,
      ownerId: 'gp_human',
      locationProvinceId: 'newWorld|p1',
      tileKey: 'newWorld|p1|0|0',
      status: UnitStatus.idle,
    ),
  ],
  newWorldProvinces: const [
    Province(id: 'newWorld|p1', regionId: 'newWorld'),
  ],
  players: const [
    Player(id: 'gp_human', displayName: 'Human', isHuman: true),
    Player(id: 'gp_ai', displayName: 'AI', isHuman: false),
  ],
);

DualRegionViewScenario civilianMarkersScenario(Game game) => dualRegionScenario(
  game: game,
  oldWorldGrid: const [
    ['p1', 'p2', 'p3'],
  ],
  oldWorldTopology: regionTopology(
    regionId: 'oldWorld',
    provinceIds: const ['p1', 'p2', 'p3'],
  ),
);

Game capitalCivilianOverlapGame() => minimalGame(
  id: 'capital_civilian_overlap',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
  ],
  oldWorldUnits: [
    Unit(
      id: 'u_builder',
      type: kUnitTypeBuilder,
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|p1',
      tileKey: 'oldWorld|p1|0|0',
    ),
    Unit(
      id: 'u_explorer',
      type: kUnitTypeExplorer,
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|p1',
      tileKey: 'oldWorld|p1|0|0',
    ),
  ],
  newWorldProvinces: const [
    Province(id: 'newWorld|p1', regionId: 'newWorld'),
  ],
  players: const [
    Player(
      id: 'gp1',
      displayName: 'Human',
      isHuman: true,
      capitalProvinceId: 'oldWorld|p1',
      capitalTile: CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      ),
    ),
  ],
);

DualRegionViewScenario capitalCivilianOverlapScenario(Game game) =>
    dualRegionScenario(
      game: game,
      oldWorldGrid: const [
        ['p1'],
      ],
      oldWorldTopology: regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['p1'],
      ),
    );
