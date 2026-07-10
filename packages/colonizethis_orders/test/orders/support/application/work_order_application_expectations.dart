// Compact applyBuildAndWorkOrders work-order application assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'orders_application_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'work_application_fixtures.dart';
import 'work_order_application_expectation_shorthand.dart';

part 'work_order_application_expectations_part1.dart';
part 'work_order_application_expectations_part2.dart';

/// Pins for [workOrderApplicationScenarios] rows.
enum WorkOrderApplicationTarget {
  prospectAddsTilePlayerProspectedTilesWhenTerrainEligible,
  prospectOnNonMineralEligibleTerrainDoesNotAddTile,
  prospectAddsTileWhenMineralResourcePresentWithoutTileMap,
  prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap,
  buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1,
  buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel,
  counterSpyWorkOrderSetsCurrentWorkForSpyUnit,
  purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey,
  purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe,
  purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe,
  purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite,
  buildFortWithSufficientMaterialsDeductsMaterials,
  buildFortLevel2SkippedWithoutMineEngineering,
  buildFortLevel3SkippedWithoutModernForts,
  upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel,
  counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork,
  unknownWorkTargetSkippedUnitStaysIdle,
  buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile,
  buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork,
  counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince,
  exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles,
  exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion,
  engineerBuildRoadWorkOrderSetsCurrentWork,
  buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient,
}

void runWorkOrderApplicationExpectation(WorkOrderApplicationTarget target) {
  switch (target) {
    case WorkOrderApplicationTarget
        .prospectAddsTilePlayerProspectedTilesWhenTerrainEligible:
    case WorkOrderApplicationTarget
        .prospectOnNonMineralEligibleTerrainDoesNotAddTile:
    case WorkOrderApplicationTarget
        .prospectAddsTileWhenMineralResourcePresentWithoutTileMap:
    case WorkOrderApplicationTarget
        .prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap:
    case WorkOrderApplicationTarget
        .buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1:
    case WorkOrderApplicationTarget
        .buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel:
    case WorkOrderApplicationTarget.counterSpyWorkOrderSetsCurrentWorkForSpyUnit:
    case WorkOrderApplicationTarget
        .purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey:
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe:
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe:
    case WorkOrderApplicationTarget
        .purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite:
      runWorkOrderApplicationExpectationPart1(target);
    case WorkOrderApplicationTarget.buildFortWithSufficientMaterialsDeductsMaterials:
    case WorkOrderApplicationTarget.buildFortLevel2SkippedWithoutMineEngineering:
    case WorkOrderApplicationTarget.buildFortLevel3SkippedWithoutModernForts:
    case WorkOrderApplicationTarget
        .upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel:
    case WorkOrderApplicationTarget
        .counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork:
    case WorkOrderApplicationTarget.unknownWorkTargetSkippedUnitStaysIdle:
    case WorkOrderApplicationTarget
        .buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile:
    case WorkOrderApplicationTarget
        .buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork:
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince:
    case WorkOrderApplicationTarget.exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles:
    case WorkOrderApplicationTarget
        .exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion:
    case WorkOrderApplicationTarget.engineerBuildRoadWorkOrderSetsCurrentWork:
    case WorkOrderApplicationTarget
        .buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient:
      runWorkOrderApplicationExpectationPart2(target);
  }
}
