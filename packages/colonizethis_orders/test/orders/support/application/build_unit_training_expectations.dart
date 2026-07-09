// Compact applyBuildAndWorkOrders build-unit / training assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'build_unit_training_expectation_shorthand.dart';
import 'build_unit_training_fixtures.dart';

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
      butExpectNoOwUnitsAfter(
        butMilitaryBaseGame(peasants: 5, treasury: 1000),
        butOrdersFor('unknown_regiment_xyz'),
      );
    case BuildUnitTrainingTarget.skipsMilitaryBuildWhenZeroPeasants:
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      butExpectNoOwUnitsAfter(
        butRegimentBuildGame(
          buildInputs: econ.buildInputs,
          peasants: 0,
          treasury: econ.buildTreasuryCost + 10,
        ),
        butOrdersFor('peasant_levies'),
      );
    case BuildUnitTrainingTarget.skipsMilitaryBuildWhenTechNotUnlocked:
      butExpectTechLockedRegimentSkipped();
    case BuildUnitTrainingTarget.skipsShipBuildWhenTechNotUnlocked:
      butExpectTechLockedShipSkipped();
    case BuildUnitTrainingTarget.shipBuildWithTopologyNullDoesNotAddFleet:
      butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.nullTopology);
    case BuildUnitTrainingTarget
        .shipBuildWithCapitalProvinceIdNullDoesNotAddFleet:
      butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.nullCapital);
    case BuildUnitTrainingTarget
        .shipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip:
      butExpectFluyteSpentNoFleet(ButFluyteNoFleetVariant.isolatedSea);
    case BuildUnitTrainingTarget.rejectsBuildWhenTreasuryIsInsufficient:
      butExpectTreasuryInsufficientRegimentBuildRejected();
    case BuildUnitTrainingTarget.rejectsBuildWhenMaterialsAreInsufficient:
      butExpectInsufficientMaterialsBuildRejected(
        game: butMilitaryBaseGame(
          peasants: 5,
          treasury:
              RegimentEconomyCatalog.byId['peasant_levies']!.buildTreasuryCost +
              10,
        ),
        regimentId: 'peasant_levies',
      );
    case BuildUnitTrainingTarget.appliesTreasuryStockpileAndWorkerCostsWhenValid:
      butExpectPeasantLevyBuildApplied();
    case BuildUnitTrainingTarget.returnsGameUnchangedWhenNoBuildOrWorkOrders:
      butExpectGameUnchangedAfterEmptyOrders(
        butMilitaryBaseGame(peasants: 2, treasury: 100),
      );
    case BuildUnitTrainingTarget
        .shipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea:
      butExpectFluyteShipBuildApplied();
    case BuildUnitTrainingTarget.rejectsNavalBuildWhenPeasantsAreZero:
      butExpectNavalBuildRejectedWhenNoPeasants();
    case BuildUnitTrainingTarget.secondNavalBuildAddsShipToExistingHomeFleet:
      butExpectSecondFluyteAddsToHomeFleet();
    case BuildUnitTrainingTarget.rejectsCivilianBuildWhenTreasuryInsufficient:
      butExpectCivilianTreasuryInsufficientRejected();
    case BuildUnitTrainingTarget.rejectsCivilianBuildWhenPaperInsufficient:
      butExpectCivilianBuildRejected(
        butCivilianGame(treasury: 1000, paper: 0),
        kUnitTypeBuilder,
      );
    case BuildUnitTrainingTarget.appliesTreasuryAndPaperCostWhenCivilianBuildValid:
      butExpectCivilianBuildApplied(
        game: butCivilianGame(treasury: 1100, paper: 3),
        unitType: kUnitTypeBuilder,
        treasuryDelta: 1000,
        paperDelta: 2,
      );
    case BuildUnitTrainingTarget.merchantRequiresMerchantCompaniesTech:
      butExpectMerchantTechGate(cash: 2000, paperQty: 4);
  }
}
