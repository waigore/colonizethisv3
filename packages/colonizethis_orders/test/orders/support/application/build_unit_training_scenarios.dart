// Table-driven applyBuildAndWorkOrders build-unit / training scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'build_unit_training_expectation_shorthand.dart';
import 'build_unit_training_fixtures.dart';

void butRunSkipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog() {
  butExpectNoOwUnitsAfter(
    butMilitaryBaseGame(peasants: 5, treasury: 1000),
    butOrdersFor('unknown_regiment_xyz'),
  );
}

void butRunSkipsMilitaryBuildWhenZeroPeasants() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  butExpectNoOwUnitsAfter(
    butRegimentBuildGame(
      buildInputs: econ.buildInputs,
      peasants: 0,
      treasury: econ.buildTreasuryCost + 10,
    ),
    butOrdersFor('peasant_levies'),
  );
}

void butRunSkipsMilitaryBuildWhenTechNotUnlocked() {
  final regimentWithTech = unlockingTechByRegimentId.keys.firstOrNull;
  if (regimentWithTech == null) return;
  final econ = RegimentEconomyCatalog.byId[regimentWithTech];
  if (econ == null) return;
  butExpectNoOwUnitsAfter(
    butRegimentBuildGame(
      buildInputs: econ.buildInputs,
      peasants: 3,
      treasury: econ.buildTreasuryCost + 10,
      techUnlocked: {},
    ),
    butOrdersFor(regimentWithTech),
  );
}

void butRunSkipsShipBuildWhenTechNotUnlocked() {
  const shipTypeId = 'fluyte';
  final shipEcon = ShipEconomyCatalog.byId[shipTypeId];
  if (shipEcon == null || unlockingTechByShipId[shipTypeId] == null) return;
  butExpectNoOwUnitsAfter(
    butShipBuildGame(
      player: butShipBuildPlayer(
        stockpile: butStockpileCovering(shipEcon.buildInputs),
        peasants: 0,
        treasury: shipEcon.buildTreasuryCost + 10,
        capitalProvinceId: ButIds.prov('P1'),
        techUnlocked: {},
      ),
    ),
    butOrdersFor(shipTypeId),
    topology: butCapitalAdjacentSeaTopology(),
  );
}

void butRunShipBuildWithTopologyNullDoesNotAddFleet() {
  butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.nullTopology);
}

void butRunShipBuildWithCapitalProvinceIdNullDoesNotAddFleet() {
  butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.nullCapital);
}

void butRunShipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip() {
  butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.isolatedSea);
}

void butRunRejectsBuildWhenTreasuryIsInsufficient() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  final game = butMilitaryBaseGame(
    peasants: 5,
    treasury: econ.buildTreasuryCost - 1,
  );
  butExpectNoUnitsTreasuryUnchanged(game, butOrdersFor('peasant_levies'));
  expect(
    butApply(
      game,
      butOrdersFor('peasant_levies'),
    ).players.single.workerPool.peasants,
    game.players.single.workerPool.peasants,
  );
}

void butRunRejectsBuildWhenMaterialsAreInsufficient() {
  final rejectGame = butMilitaryBaseGame(
    peasants: 5,
    treasury:
        RegimentEconomyCatalog.byId['peasant_levies']!.buildTreasuryCost + 10,
  );
  butExpectNoOwUnitsAfter(rejectGame, butOrdersFor('peasant_levies'));
  expect(
    butApply(
      rejectGame,
      butOrdersFor('peasant_levies'),
    ).players.single.workerPool.peasants,
    rejectGame.players.single.workerPool.peasants,
  );
}

void butRunAppliesTreasuryStockpileAndWorkerCostsWhenValid() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  final player = Player(
    id: ButIds.playerId,
    displayName: 'Player 1',
    isHuman: true,
    stockpile: butStockpileCovering(econ.buildInputs),
    workerPool: const WorkerPool(peasants: 3),
    treasury: econ.buildTreasuryCost + 5,
  );
  final validGame = butOwGame(players: [player]);
  final validNext = butApply(validGame, butOrdersFor('peasant_levies'));
  final nextPlayer = validNext.players.single;
  expect(validNext.worldState.oldWorld.units.length, 1);
  expect(validNext.worldState.oldWorld.units.single.type, 'peasant_levies');
  expect(nextPlayer.treasury, player.treasury - econ.buildTreasuryCost);
  expect(nextPlayer.workerPool.peasants, player.workerPool.peasants - 1);
  for (final entry in econ.buildInputs.entries) {
    expect(
      nextPlayer.stockpile.quantityOf(entry.key),
      player.stockpile.quantityOf(entry.key) - entry.value,
    );
  }
}

void butRunReturnsGameUnchangedWhenNoBuildOrWorkOrders() {
  final game = butMilitaryBaseGame(peasants: 2, treasury: 100);
  final next = butApply(game, const Orders());
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

void butRunShipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea() {
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final stockpile = butStockpileCovering(shipEcon.buildInputs);
  final player = butFluytePlayer(
    stockpile: stockpile,
    peasants: 2,
    capitalProvinceId: ButIds.prov('P1'),
    displayName: 'Spain',
  );
  final next = butApply(
    butShipBuildGame(player: player, provinceId: 'P1').copyWith(
      players: [
        player.copyWith(
          stockpile: stockpile,
          treasury: shipEcon.buildTreasuryCost + 10,
        ),
      ],
    ),
    butOrdersFor('fluyte'),
    topology: butCapitalAdjacentSeaTopology(),
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

void butRunRejectsNavalBuildWhenPeasantsAreZero() {
  final player = butFluytePlayer(
    stockpile: butStockpileCovering(
      ShipEconomyCatalog.byId['fluyte']!.buildInputs,
    ),
    peasants: 0,
    capitalProvinceId: ButIds.prov('P1'),
    displayName: 'Spain',
  );
  final next = butApply(
    butShipBuildGame(player: player, provinceId: 'P1'),
    butOrdersFor('fluyte'),
    topology: butCapitalAdjacentSeaTopology(),
  );
  expect(next.worldState.fleets, isEmpty);
  expect(next.players.single.workerPool.peasants, 0);
  expect(next.players.single.treasury, player.treasury);
}

void butRunSecondNavalBuildAddsShipToExistingHomeFleet() {
  final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
  final player = butFluytePlayer(
    stockpile: butDoubleShipBuildStockpile(shipEcon.buildInputs),
    peasants: 2,
    capitalProvinceId: ButIds.prov('P1'),
    treasury: shipEcon.buildTreasuryCost * 2 + 10,
  );
  final next = butApply(
    butSecondNavalBuildGame(
      player: player,
      fleets: [
        Fleet(
          id: 'fleet_p1',
          ownerId: ButIds.playerId,
          seaZoneId: 'sea1',
          regionId: ButIds.ow,
          shipTypeIds: ['fluyte'],
        ),
      ],
    ),
    butOrdersFor('fluyte', spawnProvinceId: ButIds.prov('P1')),
    topology: butCapitalAdjacentSeaTopology(),
  );
  final p1Fleet = next.worldState.fleets
      .where((f) => f.ownerId == ButIds.playerId)
      .single;
  expect(p1Fleet.shipTypeIds.length, 2);
  expect(p1Fleet.shipTypeIds, contains('fluyte'));
  expect(next.players.single.workerPool.peasants, 1);
}

void butRunRejectsCivilianBuildWhenTreasuryInsufficient() {
  final game = butCivilianGame(treasury: 999, paper: 2);
  butExpectCivilianRejected(game);
  expect(
    butApply(
      game,
      butOrdersFor(kUnitTypeBuilder),
    ).players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
    game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
  );
}

void butRunRejectsCivilianBuildWhenPaperInsufficient() {
  butExpectCivilianRejected(butCivilianGame(treasury: 1000, paper: 0));
}

void butRunAppliesTreasuryAndPaperCostWhenCivilianBuildValid() {
  final game = butCivilianGame(treasury: 1100, paper: 3);
  final next = butApply(game, butOrdersFor(kUnitTypeBuilder));
  expect(next.worldState.oldWorld.units.single.type, kUnitTypeBuilder);
  expect(next.players.single.treasury, game.players.single.treasury - 1000);
  expect(
    next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
    game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id) - 2,
  );
}

void butRunMerchantRequiresMerchantCompaniesTech() {
  const cash = 2000;
  const paperQty = 4;
  final orders = butOrdersFor(kUnitTypeMerchant);
  final noTech = butCivilianGame(
    treasury: cash + 100,
    paper: paperQty + 1,
    techUnlocked: {},
  );
  butExpectNoUnitsTreasuryUnchanged(noTech, orders);
  final withTech = butCivilianGame(
    treasury: cash + 100,
    paper: paperQty + 1,
    techUnlocked: {kTechIdMerchantCompanies: true},
  );
  final next = butApply(withTech, orders);
  expect(next.worldState.oldWorld.units.single.type, kUnitTypeMerchant);
  expect(next.players.single.treasury, withTech.players.single.treasury - cash);
  expect(
    next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
    withTech.players.single.stockpile.quantityOf(CommodityCatalog.paper.id) -
        paperQty,
  );
}

List<RunnableScenario> buildUnitTrainingScenarios() => const [
  // dart format off
  RunnableScenario(
    label: 'skips build when unitType unknown in RegimentEconomyCatalog',
    run: butRunSkipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog,
  ),
  RunnableScenario(
    label: 'skips military build when zero peasants',
    run: butRunSkipsMilitaryBuildWhenZeroPeasants,
  ),
  RunnableScenario(
    label: 'skips military build when tech not unlocked',
    run: butRunSkipsMilitaryBuildWhenTechNotUnlocked,
  ),
  RunnableScenario(
    label: 'skips ship build when tech not unlocked',
    run: butRunSkipsShipBuildWhenTechNotUnlocked,
  ),
  RunnableScenario(
    label: 'ship build with topology null does not add fleet',
    run: butRunShipBuildWithTopologyNullDoesNotAddFleet,
  ),
  RunnableScenario(
    label: 'ship build with capitalProvinceId null does not add fleet',
    run: butRunShipBuildWithCapitalProvinceIdNullDoesNotAddFleet,
  ),
  RunnableScenario(
    label: 'ship build with capital not adjacent to sea does not add ship',
    run: butRunShipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip,
  ),
  RunnableScenario(
    label: 'rejects build when treasury is insufficient',
    run: butRunRejectsBuildWhenTreasuryIsInsufficient,
  ),
  RunnableScenario(
    label: 'rejects build when materials are insufficient',
    run: butRunRejectsBuildWhenMaterialsAreInsufficient,
  ),
  RunnableScenario(
    label: 'applies treasury, stockpile and worker costs when valid',
    run: butRunAppliesTreasuryStockpileAndWorkerCostsWhenValid,
  ),
  RunnableScenario(
    label: 'returns game unchanged when no build or work orders',
    run: butRunReturnsGameUnchangedWhenNoBuildOrWorkOrders,
  ),
  RunnableScenario(
    label: 'ship build adds ship to fleet when topology and capital with sea',
    run: butRunShipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea,
  ),
  RunnableScenario(
    label: 'rejects naval build when peasants are zero',
    run: butRunRejectsNavalBuildWhenPeasantsAreZero,
  ),
  RunnableScenario(
    label: 'second naval build adds ship to existing home fleet',
    run: butRunSecondNavalBuildAddsShipToExistingHomeFleet,
  ),
  RunnableScenario(
    label: 'rejects civilian build when treasury insufficient',
    run: butRunRejectsCivilianBuildWhenTreasuryInsufficient,
  ),
  RunnableScenario(
    label: 'rejects civilian build when paper insufficient',
    run: butRunRejectsCivilianBuildWhenPaperInsufficient,
  ),
  RunnableScenario(
    label: 'applies treasury and paper cost when civilian build valid',
    run: butRunAppliesTreasuryAndPaperCostWhenCivilianBuildValid,
  ),
  RunnableScenario(
    label: 'Merchant requires merchant_companies tech',
    run: butRunMerchantRequiresMerchantCompaniesTech,
  ),
  // dart format on
];
