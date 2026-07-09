part of 'build_unit_training_expectations.dart';

void _skipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog() {
  final game = butMilitaryBaseGame(peasants: 5, treasury: 1000);
  final next = applyBuildAndWorkOrders(
    game,
    butOrdersFor('unknown_regiment_xyz'),
  );
  expect(next.worldState.oldWorld.units, isEmpty);
}

void _skipsMilitaryBuildWhenZeroPeasants() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  final game = butRegimentBuildGame(
    buildInputs: econ.buildInputs,
    peasants: 0,
    treasury: econ.buildTreasuryCost + 10,
  );
  final next = applyBuildAndWorkOrders(game, butOrdersFor('peasant_levies'));
  expect(next.worldState.oldWorld.units, isEmpty);
}

void _skipsMilitaryBuildWhenTechNotUnlocked() {
  final regimentWithTech = unlockingTechByRegimentId.keys.firstOrNull;
  if (regimentWithTech == null) return;
  final econ = RegimentEconomyCatalog.byId[regimentWithTech];
  if (econ == null) return;
  final game = butRegimentBuildGame(
    buildInputs: econ.buildInputs,
    peasants: 3,
    treasury: econ.buildTreasuryCost + 10,
    techUnlocked: {},
  );
  final next = applyBuildAndWorkOrders(game, butOrdersFor(regimentWithTech));
  expect(next.worldState.oldWorld.units, isEmpty);
}

void _skipsShipBuildWhenTechNotUnlocked() {
  const shipTypeId = 'fluyte';
  final shipEcon = ShipEconomyCatalog.byId[shipTypeId];
  if (shipEcon == null || unlockingTechByShipId[shipTypeId] == null) return;
  final game = butShipBuildGame(
    player: butShipBuildPlayer(
      stockpile: butStockpileCovering(shipEcon.buildInputs),
      peasants: 0,
      treasury: shipEcon.buildTreasuryCost + 10,
      capitalProvinceId: ButIds.prov('P1'),
      techUnlocked: {},
    ),
  );
  final next = applyBuildAndWorkOrders(
    game,
    butOrdersFor(shipTypeId),
    topology: butCapitalAdjacentSeaTopology(),
  );
  expect(next.worldState.fleets, isEmpty);
}

void _shipBuildWithTopologyNullDoesNotAddFleet() {
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final stockpile = butStockpileCovering(shipEcon.buildInputs);
  final player = butShipBuildPlayer(
    stockpile: stockpile,
    peasants: 1,
    treasury: shipEcon.buildTreasuryCost + 10,
    capitalProvinceId: ButIds.prov('P1'),
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  final game = butShipBuildGame(player: player);
  final next = applyBuildAndWorkOrders(game, butOrdersFor('fluyte'));
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
  final stockpile = butStockpileCovering(shipEcon.buildInputs);
  final player = butShipBuildPlayer(
    stockpile: stockpile,
    peasants: 1,
    treasury: shipEcon.buildTreasuryCost + 10,
    capitalProvinceId: null,
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  final game = butShipBuildGame(player: player);
  final next = applyBuildAndWorkOrders(
    game,
    butOrdersFor('fluyte'),
    topology: butCapitalAdjacentSeaTopology(),
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
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final stockpile = butStockpileCovering(shipEcon.buildInputs);
  final player = butShipBuildPlayer(
    stockpile: stockpile,
    peasants: 1,
    treasury: shipEcon.buildTreasuryCost + 10,
    capitalProvinceId: ButIds.prov('P1'),
    techUnlocked: {kTechIdSuperiorHullDesign: true},
  );
  final game = butShipBuildGame(player: player);
  final next = applyBuildAndWorkOrders(
    game,
    butOrdersFor('fluyte'),
    topology: butCapitalIsolatedSeaTopology(),
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
  final game = butMilitaryBaseGame(
    peasants: 5,
    treasury: econ.buildTreasuryCost - 1,
  );
  final next = applyBuildAndWorkOrders(game, butOrdersFor('peasant_levies'));
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.players.single.treasury, game.players.single.treasury);
  expect(
    next.players.single.workerPool.peasants,
    game.players.single.workerPool.peasants,
  );
}
