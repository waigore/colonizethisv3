// Shared suggestWorkOrders logging scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const _playerId = 'gp1';
const _ow = 'oldWorld';

Player osgwPlayer({int treasury = 5000}) => Player(
      id: _playerId,
      displayName: 'Human',
      isHuman: true,
      treasury: treasury,
    );

({Game game, MapTopology topology, PlayerView view}) osgwFourCivilianUnitsGame() {
  final player = osgwPlayer();
  final p1 = Province(id: '$_ow|p1', regionId: _ow, ownerId: _playerId);
  final p2 = Province(id: '$_ow|p2', regionId: _ow, ownerId: _playerId);

  final explorer = Unit(
    id: 'u_explorer',
    type: kUnitTypeExplorer,
    ownerId: _playerId,
    locationProvinceId: p1.id,
    tileKey: '$_ow|p1|0|0',
    status: UnitStatus.idle,
  );
  final builder = Unit(
    id: 'u_builder',
    type: kUnitTypeBuilder,
    ownerId: _playerId,
    locationProvinceId: p1.id,
    tileKey: '$_ow|p1|0|0',
    status: UnitStatus.idle,
  );
  final spy = Unit(
    id: 'u_spy',
    type: kUnitTypeSpy,
    ownerId: _playerId,
    locationProvinceId: p1.id,
    tileKey: '$_ow|p1|0|0',
    status: UnitStatus.idle,
  );
  final merchant = Unit(
    id: 'u_merchant',
    type: kUnitTypeMerchant,
    ownerId: _playerId,
    locationProvinceId: p1.id,
    tileKey: '$_ow|p1|0|0',
    status: UnitStatus.idle,
  );

  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [p1, p2],
      units: [explorer, builder, spy, merchant],
    ),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      _playerId: {'$_ow|p1|0|0': 'fullyVisible', '$_ow|p2|0|0': 'fogged'},
    },
    tileKeysByRegionAndProvince: {
      _ow: {
        p1.id: ['$_ow|p1|0|0'],
        p2.id: ['$_ow|p2|0|0'],
      },
    },
    resourceByTileKey: {'$_ow|p1|0|0': 'grain'},
  );

  final game = Game(
    id: 'g1',
    worldState: world,
    players: [player],
    minorNations: const [],
    tribes: const [],
  );

  final topology = MapTopology(
    nodes: [
      TopologyNode(id: 'p1', regionId: _ow, type: TopologyNodeType.province),
      TopologyNode(id: 'p2', regionId: _ow, type: TopologyNodeType.province),
    ],
    edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
  );

  return (
    game: game,
    topology: topology,
    view: buildPlayerView(game, topology, _playerId),
  );
}

({Game game, MapTopology topology, PlayerView view}) osgwSingleExplorerGame() {
  final player = osgwPlayer();
  final p1 = Province(id: '$_ow|p1', regionId: _ow, ownerId: _playerId);
  final explorer = Unit(
    id: 'u_explorer',
    type: kUnitTypeExplorer,
    ownerId: _playerId,
    locationProvinceId: p1.id,
    tileKey: '$_ow|p1|0|0',
    status: UnitStatus.idle,
  );

  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [explorer]),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      _playerId: {'$_ow|p1|0|0': 'fullyVisible', '$_ow|p1|0|1': 'unknown'},
    },
    tileKeysByRegionAndProvince: {
      _ow: {
        p1.id: ['$_ow|p1|0|0', '$_ow|p1|0|1'],
      },
    },
    resourceByTileKey: const {'$_ow|p1|0|0': 'grain'},
  );

  final game = Game(
    id: 'g1',
    worldState: world,
    players: [player],
    minorNations: const [],
    tribes: const [],
  );

  final topology = MapTopology(
    nodes: [
      TopologyNode(id: 'p1', regionId: _ow, type: TopologyNodeType.province),
    ],
    edges: const [],
  );

  return (
    game: game,
    topology: topology,
    view: buildPlayerView(game, topology, _playerId),
  );
}
