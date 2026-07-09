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

({Game game, MapTopology topology, PlayerView view})
    osgwTwoIronTilesFoggedGame() {
  const provinceId = '$_ow|p1';
  const t0 = '$_ow|p1|0|0';
  const t1 = '$_ow|p1|1|0';
  final player = Player(
    id: _playerId,
    displayName: 'GP',
    isHuman: false,
  );
  final province = Province(
    id: provinceId,
    regionId: _ow,
    ownerId: _playerId,
  );
  final explorer = Unit(
    id: 'u_explorer',
    type: kUnitTypeExplorer,
    ownerId: _playerId,
    locationProvinceId: provinceId,
    tileKey: t0,
    status: UnitStatus.idle,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [province], units: [explorer]),
    newWorld: const RegionData(),
    tileKeysByRegionAndProvince: {
      _ow: {
        provinceId: [t0, t1],
      },
    },
    resourceByTileKey: const {t0: 'iron', t1: 'iron'},
    playerVisibilityByTile: const {
      _playerId: {t0: 'fogged', t1: 'fogged'},
    },
  );
  final game = Game(
    id: 'g-prospect-log',
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

({Game game, MapTopology topology, PlayerView view, Orders orders})
    osgwExplorerPendingDuplicateGame() {
  const provinceId = '$_ow|p1';
  const tile = '$_ow|p1|0|0';
  final player = osgwPlayer();
  final province = Province(
    id: provinceId,
    regionId: _ow,
    ownerId: _playerId,
  );
  final explorer = Unit(
    id: 'u_explorer',
    type: kUnitTypeExplorer,
    ownerId: _playerId,
    locationProvinceId: provinceId,
    tileKey: tile,
    status: UnitStatus.idle,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [province], units: [explorer]),
    newWorld: const RegionData(),
    tileKeysByRegionAndProvince: {
      _ow: {
        provinceId: [tile],
      },
    },
    playerVisibilityByTile: {
      _playerId: {tile: 'fullyVisible'},
    },
  );
  final game = Game(
    id: 'g-order',
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
  final orders = Orders(
    workOrdersByPlayerId: {
      _playerId: const [
        WorkOrder(
          unitId: 'u_explorer',
          target: kWorkTargetExplore,
          targetTileKey: tile,
        ),
        WorkOrder(
          unitId: 'u_explorer',
          target: kWorkTargetProspect,
          targetTileKey: tile,
        ),
      ],
    },
  );
  return (
    game: game,
    topology: topology,
    view: buildPlayerView(game, topology, _playerId),
    orders: orders,
  );
}
