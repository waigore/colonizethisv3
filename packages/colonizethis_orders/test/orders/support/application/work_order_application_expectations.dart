// Compact applyBuildAndWorkOrders work-order application assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'orders_application_test_support.dart';
import 'work_application_fixtures.dart';
import 'work_order_application_expectation_shorthand.dart';

/// Pins for [workOrderApplicationScenarios] rows.
part 'work_order_application_expectations_part1.dart';
part 'work_order_application_expectations_part2.dart';

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
      _prospectAddsTilePlayerProspectedTilesWhenTerrainEligible();
    case WorkOrderApplicationTarget
        .prospectOnNonMineralEligibleTerrainDoesNotAddTile:
      _prospectOnNonMineralEligibleTerrainDoesNotAddTile();
    case WorkOrderApplicationTarget
        .prospectAddsTileWhenMineralResourcePresentWithoutTileMap:
      _prospectAddsTileWhenMineralResourcePresentWithoutTileMap();
    case WorkOrderApplicationTarget
        .prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap:
      _prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap();
    case WorkOrderApplicationTarget
        .buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1:
      _buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1();
    case WorkOrderApplicationTarget
        .buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel:
      _buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel();
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnit:
      _counterSpyWorkOrderSetsCurrentWorkForSpyUnit();
    case WorkOrderApplicationTarget
        .purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey:
      _purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey();
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe:
      _purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe();
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe:
      _purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe();
    case WorkOrderApplicationTarget
        .purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite:
      _purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite();
    case WorkOrderApplicationTarget
        .buildFortWithSufficientMaterialsDeductsMaterials:
      _buildFortWithSufficientMaterialsDeductsMaterials();
    case WorkOrderApplicationTarget
        .buildFortLevel2SkippedWithoutMineEngineering:
      _buildFortLevel2SkippedWithoutMineEngineering();
    case WorkOrderApplicationTarget.buildFortLevel3SkippedWithoutModernForts:
      _buildFortLevel3SkippedWithoutModernForts();
    case WorkOrderApplicationTarget
        .upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel:
      _upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel();
    case WorkOrderApplicationTarget
        .counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork:
      _counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork();
    case WorkOrderApplicationTarget.unknownWorkTargetSkippedUnitStaysIdle:
      _unknownWorkTargetSkippedUnitStaysIdle();
    case WorkOrderApplicationTarget
        .buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile:
      _buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile();
    case WorkOrderApplicationTarget
        .buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork:
      _buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork();
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince:
      _counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince();
    case WorkOrderApplicationTarget
        .exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles:
      _exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles();
    case WorkOrderApplicationTarget
        .exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion:
      _exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion();
    case WorkOrderApplicationTarget.engineerBuildRoadWorkOrderSetsCurrentWork:
      _engineerBuildRoadWorkOrderSetsCurrentWork();
    case WorkOrderApplicationTarget
        .buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient:
      _buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient();
  }
}


