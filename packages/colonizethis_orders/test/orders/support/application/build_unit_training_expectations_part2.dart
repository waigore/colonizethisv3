part of 'build_unit_training_expectations.dart';


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
