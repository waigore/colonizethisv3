part of 'build_unit_training_expectations.dart';

Game _militaryBaseGame({required int peasants, required int treasury}) {
  const playerId = 'p1';
  final player = Player(
    id: playerId,
    displayName: 'Player 1',
    isHuman: true,
    stockpile: const Stockpile(),
    workerPool: WorkerPool(peasants: peasants),
    treasury: treasury,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(
      provinces: [
        Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: playerId),
      ],
      units: [],
    ),
    newWorld: const RegionData(),
  );
  return Game(id: 'g', worldState: world, players: [player]);
}

Orders _ordersFor(String unitType, {String? spawnProvinceId}) {
  final spawn = spawnProvinceId ?? 'oldWorld|P1';
  return Orders(
    buildUnitOrdersByPlayerId: {
      'p1': [
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

Game _civilianGame({
  required int treasury,
  required int paper,
  Map<String, bool>? techUnlocked,
}) {
  const playerId = 'p1';
  var stockpile = const Stockpile();
  if (paper > 0) {
    stockpile = stockpile.applyDelta(CommodityCatalog.paper.id, paper);
  }
  final player = Player(
    id: playerId,
    displayName: 'Player 1',
    isHuman: true,
    capitalProvinceId: 'oldWorld|P1',
    capitalTile: const CapitalTile(
      regionId: 'oldWorld',
      provinceId: 'P1',
      x: 0,
      y: 0,
    ),
    stockpile: stockpile,
    workerPool: const WorkerPool(peasants: 0),
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(
      provinces: [
        Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: playerId),
      ],
      units: [],
    ),
    newWorld: const RegionData(),
  );
  return Game(id: 'g', worldState: world, players: [player]);
}

Stockpile _stockpileCovering(Map<String, int> inputs, {int surplus = 1}) {
  var stockpile = const Stockpile();
  for (final e in inputs.entries) {
    stockpile = stockpile.applyDelta(e.key, e.value + surplus);
  }
  return stockpile;
}

MapTopology _capitalAdjacentSeaTopology() {
  return const MapTopology(
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
}

void _skipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog() {
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        stockpile: Stockpile(),
        workerPool: WorkerPool(peasants: 5),
        treasury: 1000,
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    _ordersFor('unknown_regiment_xyz'),
  );
  expect(next.worldState.oldWorld.units, isEmpty);
}

void _skipsMilitaryBuildWhenZeroPeasants() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        stockpile: _stockpileCovering(econ.buildInputs),
        workerPool: const WorkerPool(peasants: 0),
        treasury: econ.buildTreasuryCost + 10,
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(game, _ordersFor('peasant_levies'));
  expect(next.worldState.oldWorld.units, isEmpty);
}

void _skipsMilitaryBuildWhenTechNotUnlocked() {
  final regimentWithTech = unlockingTechByRegimentId.keys.firstOrNull;
  if (regimentWithTech == null) return;
  final econ = RegimentEconomyCatalog.byId[regimentWithTech];
  if (econ == null) return;
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        stockpile: _stockpileCovering(econ.buildInputs),
        workerPool: const WorkerPool(peasants: 3),
        treasury: econ.buildTreasuryCost + 10,
        techUnlocked: {},
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(game, _ordersFor(regimentWithTech));
  expect(next.worldState.oldWorld.units, isEmpty);
}

void _skipsShipBuildWhenTechNotUnlocked() {
  const shipTypeId = 'fluyte';
  final shipEcon = ShipEconomyCatalog.byId[shipTypeId];
  if (shipEcon == null || unlockingTechByShipId[shipTypeId] == null) return;
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: 'oldWorld|P1',
        stockpile: _stockpileCovering(shipEcon.buildInputs),
        treasury: shipEcon.buildTreasuryCost + 10,
        techUnlocked: {},
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    _ordersFor(shipTypeId),
    topology: _capitalAdjacentSeaTopology(),
  );
  expect(next.worldState.fleets, isEmpty);
}

void _shipBuildWithTopologyNullDoesNotAddFleet() {
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final stockpile = _stockpileCovering(shipEcon.buildInputs);
  final player = Player(
    id: 'p1',
    displayName: 'P1',
    isHuman: true,
    capitalProvinceId: 'oldWorld|P1',
    stockpile: stockpile,
    workerPool: const WorkerPool(peasants: 1),
    treasury: shipEcon.buildTreasuryCost + 10,
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    ),
    players: [player],
  );
  final next = applyBuildAndWorkOrders(game, _ordersFor('fluyte'));
  expectShipBuildSpentButNoFleet(
    next: next,
    baselinePlayer: player,
    baselineStockpile: stockpile,
    buildTreasuryCost: shipEcon.buildTreasuryCost,
    buildInputs: shipEcon.buildInputs,
  );
}

void _shipBuildWithCapitalProvinceIdNullDoesNotAddFleet() {
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final stockpile = _stockpileCovering(shipEcon.buildInputs);
  final player = Player(
    id: 'p1',
    displayName: 'P1',
    isHuman: true,
    capitalProvinceId: null,
    stockpile: stockpile,
    workerPool: const WorkerPool(peasants: 1),
    treasury: shipEcon.buildTreasuryCost + 10,
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    ),
    players: [player],
  );
  final next = applyBuildAndWorkOrders(
    game,
    _ordersFor('fluyte'),
    topology: _capitalAdjacentSeaTopology(),
  );
  expectShipBuildSpentButNoFleet(
    next: next,
    baselinePlayer: player,
    baselineStockpile: stockpile,
    buildTreasuryCost: shipEcon.buildTreasuryCost,
    buildInputs: shipEcon.buildInputs,
  );
}

void _shipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip() {
  final topology = const MapTopology(
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
    edges: [],
  );
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final stockpile = _stockpileCovering(shipEcon.buildInputs);
  final player = Player(
    id: 'p1',
    displayName: 'P1',
    isHuman: true,
    capitalProvinceId: 'oldWorld|P1',
    stockpile: stockpile,
    workerPool: const WorkerPool(peasants: 1),
    treasury: shipEcon.buildTreasuryCost + 10,
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    ),
    players: [player],
  );
  final next = applyBuildAndWorkOrders(
    game,
    _ordersFor('fluyte'),
    topology: topology,
  );
  expectShipBuildSpentButNoFleet(
    next: next,
    baselinePlayer: player,
    baselineStockpile: stockpile,
    buildTreasuryCost: shipEcon.buildTreasuryCost,
    buildInputs: shipEcon.buildInputs,
  );
}

void _rejectsBuildWhenTreasuryIsInsufficient() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  final game = _militaryBaseGame(
    peasants: 5,
    treasury: econ.buildTreasuryCost - 1,
  );
  final next = applyBuildAndWorkOrders(game, _ordersFor('peasant_levies'));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.players.single.treasury, game.players.single.treasury);
  expect(
    next.players.single.workerPool.peasants,
    game.players.single.workerPool.peasants,
  );
}
