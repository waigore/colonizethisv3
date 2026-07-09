part of 'work_order_application_expectation_shorthand.dart';

void waaExpectCounterSpyOnCapital({String spyId = 'spy1'}) {
  final next = waaApply(
    waaCounterSpyCapitalGame(spyId: spyId),
    workAppSingleWorkOrder(unitId: spyId, target: kWorkTargetCounterSpy),
  );
  waaExpectCounterSpyWork(next);
}

Game waaExploreTwoTileGame() => workAppOwnedGame(
      units: [workAppUnit(type: kUnitTypeExplorer)],
      tileKeysByRegionAndProvince: {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey, WorkAppIds.originTileKey],
        },
      },
    );

void waaExpectExploreWorkStarted() {
  final next = waaApply(
    waaExploreTwoTileGame(),
    workAppSingleWorkOrder(target: kWorkTargetExplore),
  );
  final u = waaSingleUnit(next);
  expect(u.currentWork!.totalTurns, greaterThanOrEqualTo(1));
  waaExpectExploreWork(
    next,
    remainingTurns: u.currentWork!.totalTurns - 1,
  );
}

Game waaExploreFormulaGame() {
  const provinceSmall = '${WorkAppIds.ow}|P1';
  const provinceLarge = '${WorkAppIds.ow}|P2';
  const tileSmall1 = '${WorkAppIds.ow}|P1|0|0';
  const tileSmall2 = '${WorkAppIds.ow}|P1|1|0';
  const tileLarge1 = '${WorkAppIds.ow}|P2|0|0';
  const tileLarge2 = '${WorkAppIds.ow}|P2|1|0';
  const tileLarge3 = '${WorkAppIds.ow}|P2|2|0';
  const tileLarge4 = '${WorkAppIds.ow}|P2|3|0';

  return workAppOwnedGame(
    units: [
      workAppUnit(
        type: kUnitTypeExplorer,
        locationProvinceId: provinceSmall,
        tileKey: tileSmall1,
      ),
    ],
    provinces: const [
      Province(id: provinceSmall, regionId: WorkAppIds.ow, ownerId: 'p1'),
      Province(id: provinceLarge, regionId: WorkAppIds.ow, ownerId: 'p1'),
    ],
    tileKeysByRegionAndProvince: const {
      WorkAppIds.ow: {
        provinceSmall: [tileSmall1, tileSmall2],
        provinceLarge: [tileLarge1, tileLarge2, tileLarge3, tileLarge4],
      },
    },
  );
}

void waaExpectExploreFormulaTiming() {
  const tileSmall1 = '${WorkAppIds.ow}|P1|0|0';
  final next = waaApply(
    waaExploreFormulaGame(),
    workAppSingleWorkOrder(
      target: kWorkTargetExplore,
      targetTileKey: tileSmall1,
    ),
  );
  waaExpectExploreWork(next, totalTurns: 2, remainingTurns: 1);
}

void waaExpectEngineerBuildRoadApplied() {
  final next = waaApplyBuildRoad(waaEngineerRoadGame());
  waaExpectUnitIdle(next);
  waaExpectRoadLevel(next, 1);
}

void waaExpectBuildPortApplied() {
  final cost = workOrderMaterialCost(kWorkTargetBuildPort);
  expect(cost, isNotNull);
  final next = waaApply(
    workAppOwnedGame(
      units: [workAppUnit(type: kUnitTypeEngineer)],
      players: [
        workAppPlayer(
          stockpile: OrdersApplicationTestSupport.stockpileCovering(cost!),
        ),
      ],
    ),
    workAppSingleWorkOrder(target: kWorkTargetBuildPort),
  );
  waaExpectUnitIdle(next);
}

Game waaPurchaseLandNoEmbassyGame() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  return workAppPurchaseLandGame(
    units: [waaMerchantOnMinor()],
    players: [workAppPlayer(treasury: cost + 100)],
  );
}

Game waaPurchaseLandAtWarGame() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  return workAppPurchaseLandGame(
    units: [waaMerchantOnMinor()],
    players: [
      workAppPlayer(treasury: cost + 100),
    ],
    overtureStates: [waaEmbassyOverture()],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'p1',
        factionId2: 'minor1',
        state: RelationState.atWar,
      ),
    ],
  );
}

void waaExpectPurchaseLandRejected(Game game) {
  final next = waaApply(game, waaPurchaseLandOrders());
  waaExpectPurchased(next, ownerId: null);
  waaExpectTreasuryUnchanged(game, next, 'p1');
}

Game waaCounterSpyOngoingAssignmentGame() => workAppOwnedGame(
      turnNumber: 1,
      globalGameSeed: 12345,
      units: [
        workAppWorkingUnit(
          id: 'spy1',
          type: kUnitTypeSpy,
          workTarget: kWorkTargetCounterSpy,
          totalTurns: 0,
          remainingTurns: 1,
        ),
        workAppUnit(id: 'spy2', type: kUnitTypeSpy, ownerId: 'p2'),
      ],
      tileKeysByRegionAndProvince: {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey],
        },
      },
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: true),
      ],
    );

void waaExpectCounterSpyOngoingAssignmentPreservesUnits() {
  final next = waaApply(
    waaCounterSpyOngoingAssignmentGame(),
    workAppProcessWorkOrders(playerIds: const ['p1', 'p2']),
  );
  waaExpectUnitIdsPresent(next, const ['spy1', 'spy2']);
}

void waaExpectProspectEligible({
  TerrainType? terrain,
  Map<String, String>? resourceByTileKey,
}) {
  final next = waaProspectApply(
    terrain: terrain,
    resourceByTileKey: resourceByTileKey,
  );
  waaExpectProspected(next, expected: true);
  waaExpectUnitIdleAfterWork(next);
}

void waaExpectProspectIneligible({
  TerrainType? terrain,
  Map<String, String>? resourceByTileKey,
}) {
  final next = waaProspectApply(
    terrain: terrain,
    resourceByTileKey: resourceByTileKey,
  );
  waaExpectProspected(next, expected: false);
}

void waaExpectPurchaseLandSuccess() {
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

void waaExpectDualGpPurchaseLandFirstWins() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = waaDualGpPurchaseLandGame();
  final next = waaApply(game, waaDualPurchaseLandOrders());
  waaExpectPurchased(next, ownerId: 'p1');
  waaExpectTreasuryDelta(game, next, 'p1', -cost);
  waaExpectTreasuryUnchanged(game, next, 'p2');
}

void waaExpectBuildImprovementCompletesIdle() {
  final next = waaApplyBuildImprovement();
  waaExpectUnitIdle(next);
  waaExpectImprovementLevel(next, 1);
}

void waaExpectBuildFortCurrentWork({int fortLevel = 1}) {
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

void waaExpectCounterSpyForeignCurrentWork({String spyId = 'spy1'}) {
  final next = waaApply(
    waaCounterSpyForeignProvinceGame(spyId: spyId),
    workAppSingleWorkOrder(unitId: spyId, target: kWorkTargetCounterSpy),
  );
  waaExpectCurrentWorkTiming(
    next,
    unitId: spyId,
    workTarget: kWorkTargetCounterSpy,
    totalTurns: 0,
    remainingTurns: 1,
  );
}

void waaExpectBuildFortMaterialsDeducted() {
  final cost = workOrderCostBuildFort(0);
  final game = waaEngineerFortGame();
  final next = waaApply(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  waaExpectStockpileDeducted(game, next, cost);
}

void waaExpectBuildFortSkipped({
  required int fortLevel,
  required Stockpile stockpile,
  required Map<String, bool> techUnlocked,
  required int expectedFortLevel,
}) {
  final next = waaApplyBuildFort(
    fortLevel: fortLevel,
    stockpile: stockpile,
    techUnlocked: techUnlocked,
  );
  waaExpectFortLevel(next, expectedFortLevel);
  waaExpectUnitCurrentWorkNull(next);
}

void waaExpectUpgradeTownDevelopmentApplied({int before = 1, int after = 2}) {
  final next = waaApply(
    workAppOwnedGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeBuilder,
          workTarget: kWorkTargetUpgradeTown,
        ),
      ],
      provinces: [workAppOwnedProvince(townDevelopmentLevel: before)],
      players: [
        workAppPlayer(techUnlocked: const {kTechIdNationalBureaucracy: true}),
      ],
    ),
    workAppProcessWorkOrders(),
  );
  waaExpectTownDevelopmentLevel(next, after);
}

void waaExpectUnknownTargetIdle() {
  final next = waaApply(
    workAppOwnedGame(units: [workAppUnit(type: kUnitTypeBuilder)]),
    workAppSingleWorkOrder(target: 'unknown_target'),
  );
  waaExpectUnitIdle(next);
}

void waaExpectBuildFortLevel2SkippedWithoutMineEngineering() {
  waaExpectBuildFortSkipped(
    fortLevel: 1,
    stockpile: const Stockpile(),
    techUnlocked: const {},
    expectedFortLevel: 1,
  );
}

void waaExpectBuildFortLevel3SkippedWithoutModernForts() {
  waaExpectBuildFortSkipped(
    fortLevel: 2,
    stockpile: const Stockpile(),
    techUnlocked: const {kTechIdMineEngineering: true},
    expectedFortLevel: 2,
  );
}
