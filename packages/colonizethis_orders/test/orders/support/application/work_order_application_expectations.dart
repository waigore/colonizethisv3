// Compact applyBuildAndWorkOrders work-order application assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'work_application_fixtures.dart';
import 'work_order_application_expectation_shorthand.dart';

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
      waaExpectProspectEligible(terrain: TerrainType.hills);
    case WorkOrderApplicationTarget
        .prospectOnNonMineralEligibleTerrainDoesNotAddTile:
      waaExpectProspectIneligible(terrain: TerrainType.plains);
    case WorkOrderApplicationTarget
        .prospectAddsTileWhenMineralResourcePresentWithoutTileMap:
      waaExpectProspectEligible(resourceByTileKey: {WorkAppIds.tileKey: 'iron'});
    case WorkOrderApplicationTarget
        .prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap:
      waaExpectProspectIneligible(resourceByTileKey: {WorkAppIds.tileKey: 'grain'});
    case WorkOrderApplicationTarget
        .buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1:
      waaExpectBuildImprovementCompletesIdle();
    case WorkOrderApplicationTarget
        .buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel:
      waaExpectBuildFortCurrentWork();
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnit:
      waaExpectCounterSpyForeignCurrentWork();
    case WorkOrderApplicationTarget
        .purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey:
      waaExpectPurchaseLandSuccess();
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe:
      waaExpectPurchaseLandRejected(waaPurchaseLandNoEmbassyGame());
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe:
      waaExpectPurchaseLandRejected(waaPurchaseLandAtWarGame());
    case WorkOrderApplicationTarget
        .purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite:
      waaExpectDualGpPurchaseLandFirstWins();
    case WorkOrderApplicationTarget
        .buildFortWithSufficientMaterialsDeductsMaterials:
      waaExpectBuildFortMaterialsDeducted();
    case WorkOrderApplicationTarget
        .buildFortLevel2SkippedWithoutMineEngineering:
      waaExpectBuildFortLevel2SkippedWithoutMineEngineering();
    case WorkOrderApplicationTarget.buildFortLevel3SkippedWithoutModernForts:
      waaExpectBuildFortLevel3SkippedWithoutModernForts();
    case WorkOrderApplicationTarget
        .upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel:
      waaExpectUpgradeTownDevelopmentApplied();
    case WorkOrderApplicationTarget
        .counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork:
      waaExpectCounterSpyOngoingAssignmentPreservesUnits();
    case WorkOrderApplicationTarget.unknownWorkTargetSkippedUnitStaysIdle:
      waaExpectUnknownTargetIdle();
    case WorkOrderApplicationTarget
        .buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile:
      waaExpectBuildRoadInsufficientMaterials();
    case WorkOrderApplicationTarget
        .buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork:
      waaExpectBuildRoadWithMaterialsDeductsStockpile();
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince:
      waaExpectCounterSpyOnCapital();
    case WorkOrderApplicationTarget
        .exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles:
      waaExpectExploreWorkStarted();
    case WorkOrderApplicationTarget
        .exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion:
      waaExpectExploreFormulaTiming();
    case WorkOrderApplicationTarget.engineerBuildRoadWorkOrderSetsCurrentWork:
      waaExpectEngineerBuildRoadApplied();
    case WorkOrderApplicationTarget
        .buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient:
      waaExpectBuildPortApplied();
  }
}
