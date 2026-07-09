// Compact applyBuildAndWorkOrders build-unit / training assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'build_unit_training_expectation_shorthand.dart';
import 'build_unit_training_fixtures.dart';

/// Pins for [buildUnitTrainingScenarios] rows.
part 'build_unit_training_expectations_part1.dart';
part 'build_unit_training_expectations_part2.dart';

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
