// runBuildPhase O(1) index-map scenario fixtures (Refs #3949 wave 3,
// #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const runBuildPhasePlayerId = 'p1';
const runBuildPhaseCapProvinceId = 'oldWorld|P1';

Game runBuildPhaseMilitaryGame({required int regimentCount}) {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  var stockpile = const Stockpile();
  for (final entry in econ.buildInputs.entries) {
    stockpile = stockpile.applyDelta(
      entry.key,
      entry.value * regimentCount + 1,
    );
  }
  return ordersOwRegionGame(
    id: 'g',
    players: [
      Player(
        id: runBuildPhasePlayerId,
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: runBuildPhaseCapProvinceId,
        stockpile: stockpile,
        workerPool: WorkerPool(peasants: regimentCount + 1),
        treasury: econ.buildTreasuryCost * regimentCount + 100,
      ),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: runBuildPhaseCapProvinceId,
          regionId: 'oldWorld',
          ownerId: runBuildPhasePlayerId,
        ),
      ],
      units: [],
    ),
  );
}

Orders runBuildPhaseMilitaryOrders({required int regimentCount}) => Orders(
  buildUnitOrdersByPlayerId: {
    runBuildPhasePlayerId: [
      for (var i = 0; i < regimentCount; i++)
        const BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: runBuildPhaseCapProvinceId,
        ),
    ],
  },
);

const runBuildPhaseNavalTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'P1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'sea1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: [TopologyEdge(id1: 'P1', id2: 'sea1')],
);

Game runBuildPhaseNavalGame({required int shipCount}) {
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  var stockpile = const Stockpile();
  for (final e in shipEcon.buildInputs.entries) {
    stockpile = stockpile.applyDelta(e.key, e.value * shipCount + 1);
  }
  return ordersOwRegionGame(
    id: 'g',
    players: [
      Player(
        id: runBuildPhasePlayerId,
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: runBuildPhaseCapProvinceId,
        stockpile: stockpile,
        workerPool: WorkerPool(peasants: shipCount + 1),
        treasury: shipEcon.buildTreasuryCost * shipCount + 100,
        techUnlocked: const {kTechIdSuperiorHullDesign: true},
      ),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: 'P1',
          regionId: 'oldWorld',
          ownerId: runBuildPhasePlayerId,
        ),
      ],
      units: [],
    ),
  );
}

Orders runBuildPhaseNavalOrders({required int shipCount}) => Orders(
  buildUnitOrdersByPlayerId: {
    runBuildPhasePlayerId: [
      for (var i = 0; i < shipCount; i++)
        const BuildUnitOrder(
          unitType: 'fluyte',
          isMilitary: false,
          spawnProvinceId: runBuildPhaseCapProvinceId,
        ),
    ],
  },
);
