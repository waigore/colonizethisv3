part of 'work_order_application_expectations.dart';

void _prospectAddsTilePlayerProspectedTilesWhenTerrainEligible() {
  waaExpectProspectEligible(terrain: TerrainType.hills);
}

void _prospectOnNonMineralEligibleTerrainDoesNotAddTile() {
  waaExpectProspectIneligible(terrain: TerrainType.plains);
}

void _prospectAddsTileWhenMineralResourcePresentWithoutTileMap() {
  waaExpectProspectEligible(resourceByTileKey: {WorkAppIds.tileKey: 'iron'});
}

void _prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap() {
  waaExpectProspectIneligible(resourceByTileKey: {WorkAppIds.tileKey: 'grain'});
}

void _buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1() {
  waaExpectBuildImprovementCompletesIdle();
}

void _buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel() {
  waaExpectBuildFortCurrentWork();
}

void _counterSpyWorkOrderSetsCurrentWorkForSpyUnit() {
  waaExpectCounterSpyForeignCurrentWork();
}

void _purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey() {
  waaExpectPurchaseLandSuccess();
}

void _purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe() {
  waaExpectPurchaseLandRejected(waaPurchaseLandNoEmbassyGame());
}

void _purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe() {
  waaExpectPurchaseLandRejected(waaPurchaseLandAtWarGame());
}

void _purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite() {
  waaExpectDualGpPurchaseLandFirstWins();
}

void _buildFortWithSufficientMaterialsDeductsMaterials() {
  waaExpectBuildFortMaterialsDeducted();
}

void _buildFortLevel2SkippedWithoutMineEngineering() {
  waaExpectBuildFortSkipped(
    fortLevel: 1,
    stockpile: const Stockpile(),
    techUnlocked: const {},
    expectedFortLevel: 1,
  );
}

void _buildFortLevel3SkippedWithoutModernForts() {
  waaExpectBuildFortSkipped(
    fortLevel: 2,
    stockpile: const Stockpile(),
    techUnlocked: const {kTechIdMineEngineering: true},
    expectedFortLevel: 2,
  );
}

void _upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel() {
  waaExpectUpgradeTownDevelopmentApplied();
}

void _counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork() {
  waaExpectCounterSpyOngoingAssignmentPreservesUnits();
}
