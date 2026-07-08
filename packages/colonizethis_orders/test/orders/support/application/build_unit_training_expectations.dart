// Compact applyBuildAndWorkOrders build-unit / training assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'orders_application_military_ship_skip_test_support.dart';

/// Pins for [buildUnitTrainingScenarios] rows.
enum BuildUnitTrainingTarget {
  skipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog,
  skipsMilitaryBuildWhenZeroPeasants,
  skipsMilitaryBuildWhenTechNotUnlocked,
  skipsShipBuildWhenTechNotUnlocked,
  shipBuildWithTopologyNullDoesNotAddFleet,
  shipBuildWithCapitalProvinceIdNullDoesNotAddFleet,
  shipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip,
  rejectsBuildWhenTreasuryIsInsufficient,
  rejectsBuildWhenMaterialsAreInsufficient,
  appliesTreasuryStockpileAndWorkerCostsWhenValid,
  returnsGameUnchangedWhenNoBuildOrWorkOrders,
  shipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea,
  rejectsNavalBuildWhenPeasantsAreZero,
  secondNavalBuildAddsShipToExistingHomeFleet,
  rejectsCivilianBuildWhenTreasuryInsufficient,
  rejectsCivilianBuildWhenPaperInsufficient,
  appliesTreasuryAndPaperCostWhenCivilianBuildValid,
  merchantRequiresMerchantCompaniesTech,
}

void runBuildUnitTrainingExpectation(BuildUnitTrainingTarget target) {
  switch (target) {
    case BuildUnitTrainingTarget
        .skipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog:
      _skipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog();
    case BuildUnitTrainingTarget.skipsMilitaryBuildWhenZeroPeasants:
      _skipsMilitaryBuildWhenZeroPeasants();
    case BuildUnitTrainingTarget.skipsMilitaryBuildWhenTechNotUnlocked:
      _skipsMilitaryBuildWhenTechNotUnlocked();
    case BuildUnitTrainingTarget.skipsShipBuildWhenTechNotUnlocked:
      _skipsShipBuildWhenTechNotUnlocked();
    case BuildUnitTrainingTarget.shipBuildWithTopologyNullDoesNotAddFleet:
      _shipBuildWithTopologyNullDoesNotAddFleet();
    case BuildUnitTrainingTarget
        .shipBuildWithCapitalProvinceIdNullDoesNotAddFleet:
      _shipBuildWithCapitalProvinceIdNullDoesNotAddFleet();
    case BuildUnitTrainingTarget
        .shipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip:
      _shipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip();
    case BuildUnitTrainingTarget.rejectsBuildWhenTreasuryIsInsufficient:
      _rejectsBuildWhenTreasuryIsInsufficient();
    case BuildUnitTrainingTarget.rejectsBuildWhenMaterialsAreInsufficient:
      _rejectsBuildWhenMaterialsAreInsufficient();
    case BuildUnitTrainingTarget.appliesTreasuryStockpileAndWorkerCostsWhenValid:
      _appliesTreasuryStockpileAndWorkerCostsWhenValid();
    case BuildUnitTrainingTarget.returnsGameUnchangedWhenNoBuildOrWorkOrders:
      _returnsGameUnchangedWhenNoBuildOrWorkOrders();
    case BuildUnitTrainingTarget
        .shipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea:
      _shipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea();
    case BuildUnitTrainingTarget.rejectsNavalBuildWhenPeasantsAreZero:
      _rejectsNavalBuildWhenPeasantsAreZero();
    case BuildUnitTrainingTarget.secondNavalBuildAddsShipToExistingHomeFleet:
      _secondNavalBuildAddsShipToExistingHomeFleet();
    case BuildUnitTrainingTarget.rejectsCivilianBuildWhenTreasuryInsufficient:
      _rejectsCivilianBuildWhenTreasuryInsufficient();
    case BuildUnitTrainingTarget.rejectsCivilianBuildWhenPaperInsufficient:
      _rejectsCivilianBuildWhenPaperInsufficient();
    case BuildUnitTrainingTarget.appliesTreasuryAndPaperCostWhenCivilianBuildValid:
      _appliesTreasuryAndPaperCostWhenCivilianBuildValid();
    case BuildUnitTrainingTarget.merchantRequiresMerchantCompaniesTech:
      _merchantRequiresMerchantCompaniesTech();
  }
}

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

void _rejectsBuildWhenMaterialsAreInsufficient() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  final game = _militaryBaseGame(
    peasants: 5,
    treasury: econ.buildTreasuryCost + 10,
  );
  final next = applyBuildAndWorkOrders(game, _ordersFor('peasant_levies'));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(
    next.players.single.workerPool.peasants,
    game.players.single.workerPool.peasants,
  );
}

void _appliesTreasuryStockpileAndWorkerCostsWhenValid() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  final stockpile = _stockpileCovering(econ.buildInputs);
  final player = Player(
    id: 'p1',
    displayName: 'Player 1',
    isHuman: true,
    stockpile: stockpile,
    workerPool: const WorkerPool(peasants: 3),
    treasury: econ.buildTreasuryCost + 5,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(
      provinces: [
        Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
      ],
      units: [],
    ),
    newWorld: const RegionData(),
  );
  final game = Game(id: 'g', worldState: world, players: [player]);
  final next = applyBuildAndWorkOrders(game, _ordersFor('peasant_levies'));
  final nextPlayer = next.players.single;
  expect(next.worldState.oldWorld.units.length, 1);
  expect(next.worldState.oldWorld.units.single.type, 'peasant_levies');
  expect(nextPlayer.treasury, player.treasury - econ.buildTreasuryCost);
  expect(nextPlayer.workerPool.peasants, player.workerPool.peasants - 1);
  for (final entry in econ.buildInputs.entries) {
    final before = player.stockpile.quantityOf(entry.key);
    final after = nextPlayer.stockpile.quantityOf(entry.key);
    expect(after, before - entry.value);
  }
}

void _returnsGameUnchangedWhenNoBuildOrWorkOrders() {
  final game = _militaryBaseGame(peasants: 2, treasury: 100);
  final next = applyBuildAndWorkOrders(game, const Orders());
  expect(
    next.worldState.oldWorld.units.length,
    game.worldState.oldWorld.units.length,
  );
  expect(next.players.single.treasury, game.players.single.treasury);
  expect(
    next.players.single.workerPool.peasants,
    game.players.single.workerPool.peasants,
  );
}

void _shipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea() {
  final topology = _capitalAdjacentSeaTopology();
  final player = Player(
    id: 'p1',
    displayName: 'Spain',
    isHuman: true,
    capitalProvinceId: 'oldWorld|P1',
    stockpile: const Stockpile(),
    workerPool: const WorkerPool(peasants: 2),
    treasury: 100,
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(
      provinces: [Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1')],
      units: [],
    ),
    newWorld: const RegionData(),
  );
  final game = Game(id: 'g', worldState: world, players: [player]);
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final stockpile = _stockpileCovering(shipEcon.buildInputs);
  final gameWithStock = game.copyWith(
    players: [
      player.copyWith(
        stockpile: stockpile,
        treasury: shipEcon.buildTreasuryCost + 10,
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(
    gameWithStock,
    _ordersFor('fluyte'),
    topology: topology,
  );
  expect(next.worldState.fleets, isNotEmpty);
  expect(
    next.worldState.fleets.any(
      (f) => f.ownerId == 'p1' && f.shipTypeIds.contains('fluyte'),
    ),
    isTrue,
  );
  expect(next.players.single.workerPool.peasants, 1);
}

void _rejectsNavalBuildWhenPeasantsAreZero() {
  final topology = _capitalAdjacentSeaTopology();
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final stockpile = _stockpileCovering(shipEcon.buildInputs);
  final player = Player(
    id: 'p1',
    displayName: 'Spain',
    isHuman: true,
    capitalProvinceId: 'oldWorld|P1',
    stockpile: stockpile,
    workerPool: const WorkerPool(peasants: 0),
    treasury: shipEcon.buildTreasuryCost + 10,
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(
      provinces: [Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1')],
      units: [],
    ),
    newWorld: const RegionData(),
  );
  final game = Game(id: 'g', worldState: world, players: [player]);
  final next = applyBuildAndWorkOrders(
    game,
    _ordersFor('fluyte'),
    topology: topology,
  );
  expect(next.worldState.fleets, isEmpty);
  expect(next.players.single.workerPool.peasants, 0);
  expect(next.players.single.treasury, player.treasury);
}

void _secondNavalBuildAddsShipToExistingHomeFleet() {
  const ow = 'oldWorld';
  final topology = const MapTopology(
    nodes: [
      TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: 'Sea1', regionId: ow, type: TopologyNodeType.seaZone),
    ],
    edges: [TopologyEdge(id1: 'P1', id2: 'Sea1')],
  );
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  var stockpile = const Stockpile();
  for (final e in shipEcon.buildInputs.entries) {
    stockpile = stockpile.applyDelta(e.key, e.value * 2 + 1);
  }
  final player = Player(
    id: 'p1',
    displayName: 'P1',
    isHuman: true,
    capitalProvinceId: '$ow|P1',
    stockpile: stockpile,
    workerPool: const WorkerPool(peasants: 2),
    treasury: shipEcon.buildTreasuryCost * 2 + 10,
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(
      provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
      units: [],
    ),
    newWorld: const RegionData(),
    fleets: [
      Fleet(
        id: 'fleet_p1',
        ownerId: 'p1',
        seaZoneId: 'Sea1',
        regionId: ow,
        shipTypeIds: ['fluyte'],
      ),
    ],
  );
  final game = Game(id: 'g', worldState: world, players: [player]);
  final next = applyBuildAndWorkOrders(
    game,
    _ordersFor('fluyte', spawnProvinceId: '$ow|P1'),
    topology: topology,
  );
  final p1Fleet = next.worldState.fleets.where((f) => f.ownerId == 'p1').single;
  expect(p1Fleet.shipTypeIds.length, 2);
  expect(p1Fleet.shipTypeIds, contains('fluyte'));
  expect(next.players.single.workerPool.peasants, 1);
}

void _rejectsCivilianBuildWhenTreasuryInsufficient() {
  final game = _civilianGame(treasury: 999, paper: 2);
  final next = applyBuildAndWorkOrders(game, _ordersFor(kUnitTypeBuilder));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.players.single.treasury, game.players.single.treasury);
  expect(
    next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
    game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
  );
}

void _rejectsCivilianBuildWhenPaperInsufficient() {
  final game = _civilianGame(treasury: 1000, paper: 0);
  final next = applyBuildAndWorkOrders(game, _ordersFor(kUnitTypeBuilder));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.players.single.treasury, game.players.single.treasury);
}

void _appliesTreasuryAndPaperCostWhenCivilianBuildValid() {
  const cash = 1000;
  const paperQty = 2;
  final game = _civilianGame(treasury: cash + 100, paper: paperQty + 1);
  final next = applyBuildAndWorkOrders(game, _ordersFor(kUnitTypeBuilder));
  expect(next.worldState.oldWorld.units.length, 1);
  expect(next.worldState.oldWorld.units.single.type, kUnitTypeBuilder);
  expect(next.players.single.treasury, game.players.single.treasury - cash);
  expect(
    next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
    game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id) -
        paperQty,
  );
}

void _merchantRequiresMerchantCompaniesTech() {
  const cash = 2000;
  const paperQty = 4;
  final gameNoTech = _civilianGame(
    treasury: cash + 100,
    paper: paperQty + 1,
    techUnlocked: {},
  );
  final orders = _ordersFor(kUnitTypeMerchant);
  final nextNoTech = applyBuildAndWorkOrders(gameNoTech, orders);
  expect(nextNoTech.worldState.oldWorld.units, isEmpty);
  expect(
    nextNoTech.players.single.treasury,
    gameNoTech.players.single.treasury,
  );

  final gameWithTech = _civilianGame(
    treasury: cash + 100,
    paper: paperQty + 1,
    techUnlocked: {kTechIdMerchantCompanies: true},
  );
  final nextWithTech = applyBuildAndWorkOrders(gameWithTech, orders);
  expect(nextWithTech.worldState.oldWorld.units.length, 1);
  expect(nextWithTech.worldState.oldWorld.units.single.type, kUnitTypeMerchant);
  expect(
    nextWithTech.players.single.treasury,
    gameWithTech.players.single.treasury - cash,
  );
  expect(
    nextWithTech.players.single.stockpile.quantityOf(
      CommodityCatalog.paper.id,
    ),
    gameWithTech.players.single.stockpile.quantityOf(
          CommodityCatalog.paper.id,
        ) -
        paperQty,
  );
}
