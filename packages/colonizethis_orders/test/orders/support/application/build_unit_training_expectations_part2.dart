part of 'build_unit_training_expectations.dart';

void _rejectsBuildWhenMaterialsAreInsufficient() {
  butExpectInsufficientMaterialsBuildRejected(
    game: butMilitaryBaseGame(
      peasants: 5,
      treasury: RegimentEconomyCatalog.byId['peasant_levies']!.buildTreasuryCost +
          10,
    ),
    regimentId: 'peasant_levies',
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
  butExpectFluyteShipBuildApplied();
}

void _rejectsNavalBuildWhenPeasantsAreZero() {
  butExpectNavalBuildRejectedWhenNoPeasants();
}

void _secondNavalBuildAddsShipToExistingHomeFleet() {
  butExpectSecondFluyteAddsToHomeFleet();
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
  butExpectMerchantTechGate(cash: 2000, paperQty: 4);
}
