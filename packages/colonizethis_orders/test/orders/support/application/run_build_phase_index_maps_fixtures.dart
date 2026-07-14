// runBuildPhase O(1) index-map scenario fixtures (Refs #3949 wave 3,
// #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const runBuildPhasePlayerId = 'p1';
const runBuildPhaseCapProvinceId = 'oldWorld|P1';

// dart format off
Player _rbpPlayer({required Stockpile stockpile, required int peasants, required int treasury, Map<String, bool>? techUnlocked}) => Player(
  id: runBuildPhasePlayerId,
  displayName: 'P1',
  isHuman: true,
  capitalProvinceId: runBuildPhaseCapProvinceId,
  stockpile: stockpile,
  workerPool: WorkerPool(peasants: peasants),
  treasury: treasury,
  techUnlocked: techUnlocked,
);

Province _rbpCapProvince({String id = runBuildPhaseCapProvinceId}) =>
    Province(id: id, regionId: 'oldWorld', ownerId: runBuildPhasePlayerId);

Stockpile _rbpStockpileFor(Map<String, int> buildInputs, int count) {
  var stockpile = const Stockpile();
  for (final entry in buildInputs.entries) {
    stockpile = stockpile.applyDelta(entry.key, entry.value * count + 1);
  }
  return stockpile;
}

Game runBuildPhaseMilitaryGame({required int regimentCount}) {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  return ordersOwRegionGame(
    id: 'g',
    players: [_rbpPlayer(stockpile: _rbpStockpileFor(econ.buildInputs, regimentCount), peasants: regimentCount + 1, treasury: econ.buildTreasuryCost * regimentCount + 100)],
    oldWorld: RegionData(provinces: [_rbpCapProvince()], units: const []),
  );
}

Orders runBuildPhaseMilitaryOrders({required int regimentCount}) => Orders(
  buildUnitOrdersByPlayerId: {
    runBuildPhasePlayerId: [
      for (var i = 0; i < regimentCount; i++)
        const BuildUnitOrder(unitType: 'peasant_levies', isMilitary: true, spawnProvinceId: runBuildPhaseCapProvinceId),
    ],
  },
);

const runBuildPhaseNavalTopology = MapTopology(
  nodes: [
    TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
  ],
  edges: [TopologyEdge(id1: 'P1', id2: 'sea1')],
);

Game runBuildPhaseNavalGame({required int shipCount}) {
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  return ordersOwRegionGame(
    id: 'g',
    players: [_rbpPlayer(stockpile: _rbpStockpileFor(shipEcon.buildInputs, shipCount), peasants: shipCount + 1, treasury: shipEcon.buildTreasuryCost * shipCount + 100, techUnlocked: const {kTechIdSuperiorHullDesign: true})],
    oldWorld: RegionData(provinces: [_rbpCapProvince(id: 'P1')], units: const []),
  );
}

Orders runBuildPhaseNavalOrders({required int shipCount}) => Orders(
  buildUnitOrdersByPlayerId: {
    runBuildPhasePlayerId: [
      for (var i = 0; i < shipCount; i++)
        const BuildUnitOrder(unitType: 'fluyte', isMilitary: false, spawnProvinceId: runBuildPhaseCapProvinceId),
    ],
  },
);
// dart format on
