part of 'build_unit_training_expectations.dart';

void _rejectsBuildWhenMaterialsAreInsufficient() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  final game = butMilitaryBaseGame(
    peasants: 5,
    treasury: econ.buildTreasuryCost + 10,
  );
  final next = applyBuildAndWorkOrders(game, butOrdersFor('peasant_levies'));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(
    next.players.single.workerPool.peasants,
    game.players.single.workerPool.peasants,
  );
}

void _appliesTreasuryStockpileAndWorkerCostsWhenValid() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  final stockpile = butStockpileCovering(econ.buildInputs);
  final player = Player(
    id: ButIds.playerId,
    displayName: 'Player 1',
    isHuman: true,
    stockpile: stockpile,
    workerPool: const WorkerPool(peasants: 3),
    treasury: econ.buildTreasuryCost + 5,
  );
  final game = butOwGame(players: [player]);
  final next = applyBuildAndWorkOrders(game, butOrdersFor('peasant_levies'));
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
  final game = butMilitaryBaseGame(peasants: 2, treasury: 100);
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
  final topology = butCapitalAdjacentSeaTopology();
  final player = butShipBuildPlayer(
    stockpile: const Stockpile(),
    peasants: 2,
    treasury: 100,
    capitalProvinceId: ButIds.prov('P1'),
    techUnlocked: {kTechIdSuperiorHullDesign: true},
    displayName: 'Spain',
  );
  final game = butShipBuildGame(player: player, provinceId: 'P1');
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final stockpile = butStockpileCovering(shipEcon.buildInputs);
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
    butOrdersFor('fluyte'),
    topology: topology,
  );
  expect(next.worldState.fleets, isNotEmpty);
  expect(
    next.worldState.fleets.any(
      (f) => f.ownerId == ButIds.playerId && f.shipTypeIds.contains('fluyte'),
    ),
    isTrue,
  );
  expect(next.players.single.workerPool.peasants, 1);
}

void _rejectsNavalBuildWhenPeasantsAreZero() {
  final topology = butCapitalAdjacentSeaTopology();
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final stockpile = butStockpileCovering(shipEcon.buildInputs);
  final player = butShipBuildPlayer(
    stockpile: stockpile,
    peasants: 0,
    treasury: shipEcon.buildTreasuryCost + 10,
    capitalProvinceId: ButIds.prov('P1'),
    techUnlocked: {kTechIdSuperiorHullDesign: true},
    displayName: 'Spain',
  );
  final game = butShipBuildGame(player: player, provinceId: 'P1');
  final next = applyBuildAndWorkOrders(
    game,
    butOrdersFor('fluyte'),
    topology: topology,
  );
  expect(next.worldState.fleets, isEmpty);
  expect(next.players.single.workerPool.peasants, 0);
  expect(next.players.single.treasury, player.treasury);
}

void _secondNavalBuildAddsShipToExistingHomeFleet() {
  final topology = const MapTopology(
    nodes: [
      TopologyNode(
        id: 'P1',
        regionId: ButIds.ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'Sea1',
        regionId: ButIds.ow,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: 'P1', id2: 'Sea1')],
  );
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final player = butShipBuildPlayer(
    stockpile: butDoubleShipBuildStockpile(shipEcon.buildInputs),
    peasants: 2,
    treasury: shipEcon.buildTreasuryCost * 2 + 10,
    capitalProvinceId: ButIds.prov('P1'),
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  final game = butSecondNavalBuildGame(
    player: player,
    fleets: [
      Fleet(
        id: 'fleet_p1',
        ownerId: ButIds.playerId,
        seaZoneId: 'Sea1',
        regionId: ButIds.ow,
        shipTypeIds: ['fluyte'],
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    butOrdersFor('fluyte', spawnProvinceId: ButIds.prov('P1')),
    topology: topology,
  );
  final p1Fleet = next.worldState.fleets
      .where((f) => f.ownerId == ButIds.playerId)
      .single;
  expect(p1Fleet.shipTypeIds.length, 2);
  expect(p1Fleet.shipTypeIds, contains('fluyte'));
  expect(next.players.single.workerPool.peasants, 1);
}

void _rejectsCivilianBuildWhenTreasuryInsufficient() {
  final game = butCivilianGame(treasury: 999, paper: 2);
  final next = applyBuildAndWorkOrders(game, butOrdersFor(kUnitTypeBuilder));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.players.single.treasury, game.players.single.treasury);
  expect(
    next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
    game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
  );
}

void _rejectsCivilianBuildWhenPaperInsufficient() {
  final game = butCivilianGame(treasury: 1000, paper: 0);
  final next = applyBuildAndWorkOrders(game, butOrdersFor(kUnitTypeBuilder));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.players.single.treasury, game.players.single.treasury);
}

void _appliesTreasuryAndPaperCostWhenCivilianBuildValid() {
  const cash = 1000;
  const paperQty = 2;
  final game = butCivilianGame(treasury: cash + 100, paper: paperQty + 1);
  final next = applyBuildAndWorkOrders(game, butOrdersFor(kUnitTypeBuilder));
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
  final gameNoTech = butCivilianGame(
    treasury: cash + 100,
    paper: paperQty + 1,
    techUnlocked: {},
  );
  final orders = butOrdersFor(kUnitTypeMerchant);
  final nextNoTech = applyBuildAndWorkOrders(gameNoTech, orders);
  expect(nextNoTech.worldState.oldWorld.units, isEmpty);
  expect(
    nextNoTech.players.single.treasury,
    gameNoTech.players.single.treasury,
  );

  final gameWithTech = butCivilianGame(
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
