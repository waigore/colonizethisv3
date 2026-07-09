part of 'build_unit_training_expectations.dart';

void _rejectsBuildWhenMaterialsAreInsufficient() {
  final game = butMilitaryBaseGame(
    peasants: 5,
    treasury: RegimentEconomyCatalog.byId['peasant_levies']!.buildTreasuryCost +
        10,
  );
  final next = butApply(game, butOrdersFor('peasant_levies'));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(
    next.players.single.workerPool.peasants,
    game.players.single.workerPool.peasants,
  );
}

void _appliesTreasuryStockpileAndWorkerCostsWhenValid() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  final player = Player(
    id: ButIds.playerId,
    displayName: 'Player 1',
    isHuman: true,
    stockpile: butStockpileCovering(econ.buildInputs),
    workerPool: const WorkerPool(peasants: 3),
    treasury: econ.buildTreasuryCost + 5,
  );
  butExpectValidRegimentBuild(
    game: butOwGame(players: [player]),
    regimentId: 'peasant_levies',
    baselinePlayer: player,
  );
}

void _returnsGameUnchangedWhenNoBuildOrWorkOrders() {
  butExpectGameUnchangedAfterEmptyOrders(
    butMilitaryBaseGame(peasants: 2, treasury: 100),
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
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final gameWithStock = butShipBuildGame(player: player, provinceId: 'P1')
      .copyWith(
        players: [
          player.copyWith(
            stockpile: butStockpileCovering(shipEcon.buildInputs),
            treasury: shipEcon.buildTreasuryCost + 10,
          ),
        ],
      );
  final next = butApply(
    gameWithStock,
    butOrdersFor('fluyte'),
    topology: topology,
  );
  butExpectFleetContainsShip(next, 'fluyte');
  expect(next.players.single.workerPool.peasants, 1);
}

void _rejectsNavalBuildWhenPeasantsAreZero() {
  final topology = butCapitalAdjacentSeaTopology();
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final player = butShipBuildPlayer(
    stockpile: butStockpileCovering(shipEcon.buildInputs),
    peasants: 0,
    treasury: shipEcon.buildTreasuryCost + 10,
    capitalProvinceId: ButIds.prov('P1'),
    techUnlocked: {kTechIdSuperiorHullDesign: true},
    displayName: 'Spain',
  );
  final game = butShipBuildGame(player: player, provinceId: 'P1');
  final next = butApply(game, butOrdersFor('fluyte'), topology: topology);
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
  final next = butApply(
    butSecondNavalBuildGame(
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
    ),
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
  final next = butApply(game, butOrdersFor(kUnitTypeBuilder));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.players.single.treasury, game.players.single.treasury);
  expect(
    next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
    game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
  );
}

void _rejectsCivilianBuildWhenPaperInsufficient() {
  butExpectCivilianBuildRejected(
    butCivilianGame(treasury: 1000, paper: 0),
    kUnitTypeBuilder,
  );
}

void _appliesTreasuryAndPaperCostWhenCivilianBuildValid() {
  butExpectCivilianBuildApplied(
    game: butCivilianGame(treasury: 1100, paper: 3),
    unitType: kUnitTypeBuilder,
    treasuryDelta: 1000,
    paperDelta: 2,
  );
}

void _merchantRequiresMerchantCompaniesTech() {
  const cash = 2000;
  const paperQty = 4;
  final orders = butOrdersFor(kUnitTypeMerchant);
  final gameNoTech = butCivilianGame(
    treasury: cash + 100,
    paper: paperQty + 1,
    techUnlocked: {},
  );
  final nextNoTech = butApply(gameNoTech, orders);
  expect(nextNoTech.worldState.oldWorld.units, isEmpty);
  expect(nextNoTech.players.single.treasury, gameNoTech.players.single.treasury);

  butExpectCivilianBuildApplied(
    game: butCivilianGame(
      treasury: cash + 100,
      paper: paperQty + 1,
      techUnlocked: {kTechIdMerchantCompanies: true},
    ),
    unitType: kUnitTypeMerchant,
    treasuryDelta: cash,
    paperDelta: paperQty,
  );
}
