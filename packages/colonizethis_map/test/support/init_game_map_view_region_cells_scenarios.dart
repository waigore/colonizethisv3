import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_fixtures.dart';

/// Shared game/scenario builders for `init_game_map_view_builder_region_cells_test.dart`.
/// Refs #4112 wave-4 test densify.

Game regionCellsTerrainSliceGame() => minimalGame(
  id: 'slice-test',
  oldWorldProvinces: const [
    Province(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      ownerId: 'gp1',
      displayName: 'Alpha',
    ),
  ],
  players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
);

Game regionCellsOverlaySetupGame() => minimalGame(
  id: 'slice-test',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
  ],
  oldWorldUnits: [
    Unit(
      id: 'u-builder',
      type: kUnitTypeBuilder,
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|p1',
    ),
    Unit(
      id: 'u-regiment',
      type: 'pikemen',
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|p1',
    ),
  ],
  fleets: [
    Fleet(
      id: 'f1',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      inPortAtProvinceId: 'oldWorld|p1',
      ships: const [ShipInstance(id: 'ship-1', typeId: 'frigate')],
    ),
  ],
);

Game regionCellsMarkerHelpersGame() => minimalGame(
  id: 'slice-test',
  oldWorldProvinces: const [
    Province(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      townTileKey: 'oldWorld|p1|0|0',
    ),
  ],
  players: const [
    Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: true,
      capitalTile: CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      ),
    ),
  ],
  portsByProvinceSeaboard: const {'oldWorld|p1|s1': 'oldWorld|p1|0|0'},
);

DualRegionViewScenario regionCellsMarkerWarpScenario(Game game) =>
    oldWorldFocusedScenario(
      game: game,
      oldWorldGrid: const [
        ['p1', 's1'],
      ],
      oldWorldTopology: singleProvinceAndSeaTopology('oldWorld'),
      newWorldGrid: const [
        ['s9'],
      ],
      newWorldTopology: regionTopology(
        regionId: 'newWorld',
        seaZoneIds: const ['s9'],
      ),
    );

const regionCellsMarkerWarpLinks = <WarpLink>[
  WarpLink(
    regionId: 'oldWorld',
    seaZoneId: 's1',
    otherRegionId: 'newWorld',
    otherSeaZoneId: 's9',
  ),
];

Game regionCellsHomeFleetGame({required bool withFleet}) => minimalGame(
  id: 'slice-test',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
  ],
  fleets: withFleet
      ? [
          Fleet(
            id: 'fleet_gp1',
            ownerId: 'gp1',
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|p1',
            ships: const [],
            mission: FleetMission.none,
          ),
        ]
      : const [],
  players: const [
    Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: true,
      capitalTile: CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      ),
    ),
  ],
  portsByProvinceSeaboard: const {'oldWorld|p1|s1': 'oldWorld|p1|0|0'},
);

Game regionCellsVisibilityGame() => minimalGame(
  id: 'visibility',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
  ],
  newWorldProvinces: const [
    Province(id: 'newWorld|p1', regionId: 'newWorld', ownerId: 'gp2'),
  ],
  players: const [
    Player(id: 'gp1', displayName: 'GP1', isHuman: false),
    Player(id: 'gp2', displayName: 'GP2', isHuman: false),
  ],
);

Game regionCellsPresenceHiddenOtherGame() => minimalGame(
  id: 'presence_hidden_other',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|pOwn', regionId: 'oldWorld', ownerId: 'gp1'),
    Province(id: 'oldWorld|pOther', regionId: 'oldWorld', ownerId: 'gp2'),
  ],
  oldWorldUnits: [
    Unit(
      id: 'u_builder',
      type: kUnitTypeBuilder,
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|pOwn',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_pikemen',
      type: 'pikemen',
      ownerId: 'gp2',
      locationProvinceId: 'oldWorld|pOther',
      status: UnitStatus.idle,
    ),
  ],
  fleets: [
    Fleet(
      id: 'f_other',
      ownerId: 'gp2',
      regionId: 'oldWorld',
      inPortAtProvinceId: 'oldWorld|pOther',
      ships: const [ShipInstance(id: 'ship_1', typeId: 'frigate')],
    ),
  ],
  players: const [
    Player(id: 'gp1', displayName: 'GP1', isHuman: true),
    Player(id: 'gp2', displayName: 'GP2', isHuman: false),
  ],
);

Game regionCellsPresenceVisibleOtherGame() => minimalGame(
  id: 'presence_visible_other',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|pOther', regionId: 'oldWorld', ownerId: 'gp2'),
  ],
  oldWorldUnits: [
    Unit(
      id: 'u_builder_other',
      type: kUnitTypeBuilder,
      ownerId: 'gp2',
      locationProvinceId: 'oldWorld|pOther',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_pikemen_other',
      type: 'pikemen',
      ownerId: 'gp2',
      locationProvinceId: 'oldWorld|pOther',
      status: UnitStatus.idle,
    ),
  ],
  fleets: [
    Fleet(
      id: 'f_other_visible',
      ownerId: 'gp2',
      regionId: 'oldWorld',
      inPortAtProvinceId: 'oldWorld|pOther',
      ships: const [ShipInstance(id: 'ship_7', typeId: 'frigate')],
    ),
  ],
  players: const [
    Player(id: 'gp1', displayName: 'GP1', isHuman: true),
    Player(id: 'gp2', displayName: 'GP2', isHuman: false),
  ],
);

InitGameMapViewData buildRegionCellsMarkerWarpView(Game game) =>
    buildViewDataForScenario(
      regionCellsMarkerWarpScenario(game),
      warpLinks: regionCellsMarkerWarpLinks,
    );

InitGameMapViewData buildRegionCellsHomeFleetView({required bool withFleet}) =>
    buildRegionCellsMarkerWarpView(regionCellsHomeFleetGame(withFleet: withFleet));
