part of 'build_unit_training_expectations.dart';

void _skipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog() {
  butExpectNoOwUnitsAfter(
    butMilitaryBaseGame(peasants: 5, treasury: 1000),
    butOrdersFor('unknown_regiment_xyz'),
  );
}

void _skipsMilitaryBuildWhenZeroPeasants() {
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

void _skipsMilitaryBuildWhenTechNotUnlocked() {
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

void _skipsShipBuildWhenTechNotUnlocked() {
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

void _shipBuildWithTopologyNullDoesNotAddFleet() {
  butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.nullTopology);
}

void _shipBuildWithCapitalProvinceIdNullDoesNotAddFleet() {
  butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.nullCapital);
}

void _shipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip() {
  butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.isolatedSea);
}

void _rejectsBuildWhenTreasuryIsInsufficient() {
  butExpectTreasuryInsufficientRegimentBuildRejected();
}
