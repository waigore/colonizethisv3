// Shared DefaultOrderSuggestionAPI suggestion fixtures (Refs #3949 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const apiImplPlayerId = 'gp1';
const apiImplOw = 'oldWorld';

// dart format off
final apiImplBaseTopology = MapTopology(
  nodes: const [
    TopologyNode(id: 'p1', regionId: apiImplOw, type: TopologyNodeType.province),
    TopologyNode(id: 'p2', regionId: apiImplOw, type: TopologyNodeType.province),
  ],
  edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
);

Game apiImplDefaultGame() => ordersOwRegionGame(
  turnNumber: 1,
  players: const [Player(id: apiImplPlayerId, displayName: 'A', isHuman: true)],
  oldWorld: RegionData(
    provinces: [
      Province(id: '$apiImplOw|p1', regionId: apiImplOw, ownerId: apiImplPlayerId),
      Province(id: '$apiImplOw|p2', regionId: apiImplOw, displayName: 'P2'),
    ],
    units: [Unit(id: 'u1', type: 'inf', ownerId: apiImplPlayerId, locationProvinceId: '$apiImplOw|p1')],
  ),
  playerVisibilityByTile: const {apiImplPlayerId: {'oldWorld|p1|0|0': 'fullyVisible', 'oldWorld|p2|0|0': 'fullyVisible'}},
  tileKeysByRegionAndProvince: {apiImplOw: {'$apiImplOw|p1': ['oldWorld|p1|0|0'], '$apiImplOw|p2': ['oldWorld|p2|0|0']}},
);

final apiImplSingleProvinceTopology = MapTopology(
  nodes: const [TopologyNode(id: 'p1', regionId: apiImplOw, type: TopologyNodeType.province)],
  edges: const [],
);

Game apiImplAffordableShipGame() {
  final affordableShipTreasury = ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost;
  final stockpile = const Stockpile().applyDelta(CommodityCatalog.lumber.id, 2).applyDelta(CommodityCatalog.fabric.id, 2);
  return ordersOwRegionGame(
    turnNumber: 1,
    players: [Player(id: apiImplPlayerId, displayName: 'A', isHuman: false, capitalProvinceId: '$apiImplOw|p1', workerPool: const WorkerPool(peasants: 1), treasury: affordableShipTreasury, stockpile: stockpile)],
    oldWorld: RegionData(provinces: [Province(id: '$apiImplOw|p1', regionId: apiImplOw, ownerId: apiImplPlayerId)], units: []),
  );
}

Game apiImplFabricRecruitGame() {
  final stockpile = const Stockpile().applyDelta(CommodityCatalog.fabric.id, 4);
  return ordersOwRegionGame(
    turnNumber: 1,
    players: [Player(id: apiImplPlayerId, displayName: 'A', isHuman: false, capitalProvinceId: '$apiImplOw|p1', stockpile: stockpile)],
    oldWorld: RegionData(provinces: [Province(id: '$apiImplOw|p1', regionId: apiImplOw, ownerId: apiImplPlayerId)]),
  );
}

PlayerView apiImplViewFor(Game game, MapTopology topology) => buildPlayerView(game, topology, apiImplPlayerId);

const apiImplEmptyOrders = Orders();
// dart format on
