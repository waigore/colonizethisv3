part of 'work_order_application_expectations.dart';

void _prospectAddsTilePlayerProspectedTilesWhenTerrainEligible() {
  final next = waaProspectApply(terrain: TerrainType.hills);
  waaExpectProspected(next, expected: true);
  waaExpectUnitIdleAfterWork(next);
}

void _prospectOnNonMineralEligibleTerrainDoesNotAddTile() {
  final next = waaProspectApply(terrain: TerrainType.plains);
  waaExpectProspected(next, expected: false);
}

void _prospectAddsTileWhenMineralResourcePresentWithoutTileMap() {
  final next = waaProspectApply(
    resourceByTileKey: {WorkAppIds.tileKey: 'iron'},
  );
  waaExpectProspected(next, expected: true);
}

void _prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap() {
  final next = waaProspectApply(
    resourceByTileKey: {WorkAppIds.tileKey: 'grain'},
  );
  waaExpectProspected(next, expected: false);
}

void _buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1() {
  final next = waaApplyBuildImprovement();
  waaExpectUnitIdle(next);
  waaExpectImprovementLevel(next, 1);
}

void _buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel() {
  const fortLevel = 1;
  final next = waaApplyBuildFort(
    fortLevel: fortLevel,
    techUnlocked: const {kTechIdMineEngineering: true},
  );
  waaExpectCurrentWorkTiming(
    next,
    workTarget: kWorkTargetBuildFort,
    totalTurns: totalTurnsForWork(kWorkTargetBuildFort, fortLevel: fortLevel),
    remainingTurns: 1,
    originTileKey: WorkAppIds.tileKey,
    assignedTileKey: WorkAppIds.tileKey,
  );
  waaExpectFortLevel(next, fortLevel);
}

void _counterSpyWorkOrderSetsCurrentWorkForSpyUnit() {
  final next = waaApply(
    waaCounterSpyForeignProvinceGame(),
    workAppSingleWorkOrder(unitId: 'spy1', target: kWorkTargetCounterSpy),
  );
  waaExpectCurrentWorkTiming(
    next,
    unitId: 'spy1',
    workTarget: kWorkTargetCounterSpy,
    totalTurns: 0,
    remainingTurns: 1,
  );
}

void _purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppPurchaseLandGame(
    units: [waaMerchantOnMinor()],
    players: [workAppPlayer(treasury: cost + 100)],
    overtureStates: [waaEmbassyOverture()],
  );
  final next = waaApply(game, waaPurchaseLandOrders());
  waaExpectPurchased(next, ownerId: 'p1');
  waaExpectTreasuryDelta(game, next, 'p1', -cost);
  waaExpectUnitIdleAfterWork(next, tileKey: WorkAppIds.tileKeyMinor);
}

void _purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe() {
  final game = waaPurchaseLandNoEmbassyGame();
  waaExpectPurchaseLandRejected(game);
}

void _purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe() {
  waaExpectPurchaseLandRejected(waaPurchaseLandAtWarGame());
}

void _purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = waaDualGpPurchaseLandGame();
  final next = waaApply(game, waaDualPurchaseLandOrders());
  waaExpectPurchased(next, ownerId: 'p1');
  waaExpectTreasuryDelta(game, next, 'p1', -cost);
  waaExpectTreasuryUnchanged(game, next, 'p2');
}

void _buildFortWithSufficientMaterialsDeductsMaterials() {
  final cost = workOrderCostBuildFort(0);
  final game = waaEngineerFortGame();
  final next = waaApply(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  waaExpectStockpileDeducted(game, next, cost);
}

void _buildFortLevel2SkippedWithoutMineEngineering() {
  final next = waaApplyBuildFort(
    fortLevel: 1,
    stockpile: const Stockpile(),
    techUnlocked: const {},
  );
  waaExpectFortLevel(next, 1);
  waaExpectUnitCurrentWorkNull(next);
}

void _buildFortLevel3SkippedWithoutModernForts() {
  final next = waaApplyBuildFort(
    fortLevel: 2,
    stockpile: const Stockpile(),
    techUnlocked: const {kTechIdMineEngineering: true},
  );
  waaExpectFortLevel(next, 2);
  waaExpectUnitCurrentWorkNull(next);
}

void _upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel() {
  final next = waaApply(
    workAppOwnedGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeBuilder,
          workTarget: kWorkTargetUpgradeTown,
        ),
      ],
      provinces: [workAppOwnedProvince(townDevelopmentLevel: 1)],
      players: [
        workAppPlayer(techUnlocked: const {kTechIdNationalBureaucracy: true}),
      ],
    ),
    workAppProcessWorkOrders(),
  );
  waaExpectTownDevelopmentLevel(next, 2);
}

void _counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork() {
  waaExpectCounterSpyOngoingAssignmentPreservesUnits();
}
