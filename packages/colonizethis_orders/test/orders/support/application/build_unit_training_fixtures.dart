// Shared fixtures for build-unit / training scenarios (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Canonical ids for build-unit / training expectation bodies.
abstract final class ButIds {
  static const playerId = 'p1';
  static const ow = 'oldWorld';

  static String prov(String local) => '$ow|$local';
}

Game butOwGame({
  required List<Player> players,
  List<Province>? provinces,
  List<Fleet>? fleets,
  String provinceId = 'oldWorld|P1',
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces:
            provinces ??
            [
              Province(
                id: provinceId,
                regionId: ButIds.ow,
                ownerId: ButIds.playerId,
              ),
            ],
        units: [],
      ),
      newWorld: const RegionData(),
      fleets: fleets ?? const [],
    ),
    players: players,
  );
}

Game butMilitaryBaseGame({required int peasants, required int treasury}) {
  return butOwGame(
    players: [
      Player(
        id: ButIds.playerId,
        displayName: 'Player 1',
        isHuman: true,
        stockpile: const Stockpile(),
        workerPool: WorkerPool(peasants: peasants),
        treasury: treasury,
      ),
    ],
  );
}

Orders butOrdersFor(String unitType, {String? spawnProvinceId}) {
  final spawn = spawnProvinceId ?? ButIds.prov('P1');
  return Orders(
    buildUnitOrdersByPlayerId: {
      ButIds.playerId: [
        BuildUnitOrder(
          unitType: unitType,
          isMilitary:
              buildUnitCategoryForUnitType(unitType) ==
              BuildUnitCategory.military,
          spawnProvinceId: spawn,
        ),
      ],
    },
  );
}

Game butCivilianGame({
  required int treasury,
  required int paper,
  Map<String, bool>? techUnlocked,
}) {
  var stockpile = const Stockpile();
  if (paper > 0) {
    stockpile = stockpile.applyDelta(CommodityCatalog.paper.id, paper);
  }
  return butOwGame(
    players: [
      Player(
        id: ButIds.playerId,
        displayName: 'Player 1',
        isHuman: true,
        capitalProvinceId: ButIds.prov('P1'),
        capitalTile: const CapitalTile(
          regionId: ButIds.ow,
          provinceId: 'P1',
          x: 0,
          y: 0,
        ),
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 0),
        treasury: treasury,
        techUnlocked: techUnlocked,
      ),
    ],
  );
}

Stockpile butStockpileCovering(Map<String, int> inputs, {int surplus = 1}) {
  var stockpile = const Stockpile();
  for (final e in inputs.entries) {
    stockpile = stockpile.applyDelta(e.key, e.value + surplus);
  }
  return stockpile;
}

MapTopology butCapitalAdjacentSeaTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: 'P1',
        regionId: ButIds.ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'sea1',
        regionId: ButIds.ow,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: 'P1', id2: 'sea1')],
  );
}

MapTopology butCapitalIsolatedSeaTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: 'P1',
        regionId: ButIds.ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'sea1',
        regionId: ButIds.ow,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [],
  );
}

Game butRegimentBuildGame({
  required Map<String, int> buildInputs,
  required int peasants,
  required int treasury,
  Map<String, bool>? techUnlocked,
}) {
  return butOwGame(
    players: [
      Player(
        id: ButIds.playerId,
        displayName: 'P1',
        isHuman: true,
        stockpile: butStockpileCovering(buildInputs),
        workerPool: WorkerPool(peasants: peasants),
        treasury: treasury,
        techUnlocked: techUnlocked,
      ),
    ],
  );
}

Player butShipBuildPlayer({
  required Stockpile stockpile,
  required int peasants,
  required int treasury,
  Map<String, bool>? techUnlocked,
  String? capitalProvinceId,
  String displayName = 'P1',
}) {
  return Player(
    id: ButIds.playerId,
    displayName: displayName,
    isHuman: true,
    capitalProvinceId: capitalProvinceId,
    stockpile: stockpile,
    workerPool: WorkerPool(peasants: peasants),
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
}

Game butShipBuildGame({
  required Player player,
  String provinceId = 'oldWorld|P1',
}) {
  return butOwGame(players: [player], provinceId: provinceId);
}

Stockpile butDoubleShipBuildStockpile(Map<String, int> buildInputs) {
  var stockpile = const Stockpile();
  for (final e in buildInputs.entries) {
    stockpile = stockpile.applyDelta(e.key, e.value * 2 + 1);
  }
  return stockpile;
}

Game butSecondNavalBuildGame({
  required Player player,
  required List<Fleet> fleets,
}) {
  return butOwGame(
    players: [player],
    provinceId: ButIds.prov('P1'),
    fleets: fleets,
  );
}
