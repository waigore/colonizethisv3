import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_fixtures.dart';

/// Shared game/scenario builders for `init_game_map_view_builder_marker_policy_test.dart`.
/// Refs #4297 wave-5 test densify.

Game markerPolicyTwoGpGame({
  required bool gp1Human,
  required bool gp2Human,
}) =>
    minimalGame(
      id: 'civilian_owner_ids',
      oldWorldProvinces: const [
        Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
        Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
      ],
      oldWorldUnits: [
        Unit(
          id: 'gp1_builder',
          type: kUnitTypeBuilder,
          ownerId: 'gp1',
          locationProvinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|0|0',
          status: UnitStatus.idle,
        ),
        Unit(
          id: 'gp2_explorer',
          type: kUnitTypeExplorer,
          ownerId: 'gp2',
          locationProvinceId: 'oldWorld|p2',
          tileKey: 'oldWorld|p2|1|0',
          status: UnitStatus.idle,
        ),
      ],
      newWorldProvinces: const [
        Province(id: 'newWorld|p1', regionId: 'newWorld'),
      ],
      players: [
        Player(id: 'gp1', displayName: 'GP1', isHuman: gp1Human),
        Player(id: 'gp2', displayName: 'GP2', isHuman: gp2Human),
      ],
    );

DualRegionViewScenario markerPolicyTwoGpScenario(Game game) =>
    dualRegionScenario(
      game: game,
      oldWorldGrid: const [
        ['p1', 'p2'],
      ],
      oldWorldTopology: regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['p1', 'p2'],
      ),
    );

Game markerPolicyTownPortColocGame() => minimalGame(
  id: 'townPortColoc',
  oldWorldProvinces: const [
    Province(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      townTileKey: 'oldWorld|p1|1|1',
    ),
  ],
  portsByProvinceSeaboard: const {
    'oldWorld|p1|seaboard': 'oldWorld|p1|1|1',
  },
);

DualRegionViewScenario markerPolicyTownPortColocScenario(Game game) =>
    dualRegionScenario(
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

Game markerPolicyNonCapitalPortKeyGame() => minimalGame(
  id: 'nonCapitalPortKey',
  oldWorldProvinces: const [
    Province(
      id: 'oldWorld|p2',
      regionId: 'oldWorld',
      townTileKey: 'oldWorld|p2|0|0',
    ),
  ],
  portsByProvinceSeaboard: const {
    'oldWorld|p2|sb': 'oldWorld|p1|2|0',
  },
);

DualRegionViewScenario markerPolicyNonCapitalPortKeyScenario(Game game) =>
    dualRegionScenario(
      game: game,
      oldWorldGrid: [
        ['p2', 'p2', 'p2'],
        ['p2', 'p2', 's1'],
      ],
      oldWorldTopology: regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['p2'],
        seaZoneIds: const ['s1'],
        edges: const [TopologyEdge(id1: 'p2', id2: 's1')],
      ),
    );

Game markerPolicyObserveCivilianGame() => minimalGame(
  id: 'observe_civilian_markers',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
    Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
    Province(id: 'oldWorld|p3', regionId: 'oldWorld'),
  ],
  oldWorldUnits: [
    Unit(
      id: 'u_gp1',
      type: kUnitTypeBuilder,
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|p1',
      tileKey: 'oldWorld|p1|0|0',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_gp2',
      type: kUnitTypeExplorer,
      ownerId: 'gp2',
      locationProvinceId: 'oldWorld|p3',
      tileKey: 'oldWorld|p3|2|0',
      status: UnitStatus.idle,
    ),
  ],
  newWorldProvinces: const [
    Province(id: 'newWorld|p1', regionId: 'newWorld'),
  ],
  players: const [
    Player(id: 'gp1', displayName: 'Spain', isHuman: false),
    Player(id: 'gp2', displayName: 'France', isHuman: false),
  ],
);

DualRegionViewScenario markerPolicyObserveCivilianScenario(Game game) =>
    dualRegionScenario(
      game: game,
      oldWorldGrid: const [
        ['p1', 'p2', 'p3'],
      ],
      oldWorldTopology: regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['p1', 'p2', 'p3'],
      ),
    );
