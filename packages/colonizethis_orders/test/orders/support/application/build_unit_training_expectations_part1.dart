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
  butExpectTechLockedRegimentSkipped();
}

void _skipsShipBuildWhenTechNotUnlocked() {
  butExpectTechLockedShipSkipped();
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
