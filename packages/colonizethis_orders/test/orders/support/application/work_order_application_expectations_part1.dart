part of 'work_order_application_expectations.dart';

void _prospectAddsTilePlayerProspectedTilesWhenTerrainEligible() {
  final next = waaApply(
    waaProspectGame(),
    waaProspectOrders(),
    tileMapByRegion: {
      WorkAppIds.ow: OrdersApplicationTestSupport.tileMapWithTerrain(
        TerrainType.hills,
      ),
    },
  );
  waaExpectProspected(next, expected: true);
  waaExpectUnitIdleAfterWork(next);
}

void _prospectOnNonMineralEligibleTerrainDoesNotAddTile() {
  final next = waaApply(
    waaProspectGame(),
    waaProspectOrders(),
    tileMapByRegion: {
      WorkAppIds.ow: OrdersApplicationTestSupport.tileMapWithTerrain(
        TerrainType.plains,
      ),
    },
  );
  waaExpectProspected(next, expected: false);
}

void _prospectAddsTileWhenMineralResourcePresentWithoutTileMap() {
  final next = waaApply(
    waaProspectGame(resourceByTileKey: {WorkAppIds.tileKey: 'iron'}),
    waaProspectOrders(),
  );
  waaExpectProspected(next, expected: true);
}

void _prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap() {
  final next = waaApply(
    waaProspectGame(resourceByTileKey: {WorkAppIds.tileKey: 'grain'}),
    waaProspectOrders(),
  );
  waaExpectProspected(next, expected: false);
}

void _buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1() {
  final cost = workOrderCostBuildImprovement(0);
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeBuilder)],
    resourceByTileKey: {WorkAppIds.tileKey: 'grain'},
    players: [
      workAppPlayer(
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
      ),
    ],
  );
  final next = waaApply(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildImprovement),
  );
  waaExpectUnitIdle(next);
  waaExpectImprovementLevel(next, 1);
}

void _buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel() {
  final cost = workOrderCostBuildFort(1);
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeEngineer)],
    provinces: [workAppOwnedProvince(fortLevel: 1)],
    players: [
      workAppPlayer(
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
        techUnlocked: const {kTechIdMineEngineering: true},
      ),
    ],
  );
  final next = waaApply(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  final u = waaSingleUnit(next);
  expect(
    u.currentWork!.totalTurns,
    totalTurnsForWork(kWorkTargetBuildFort, fortLevel: 1),
  );
  expect(u.currentWork!.remainingTurns, 1);
  expect(u.originTileKey, WorkAppIds.tileKey);
  expect(u.assignedTileKey, WorkAppIds.tileKey);
  waaExpectFortLevel(next, 1);
}

void _counterSpyWorkOrderSetsCurrentWorkForSpyUnit() {
  final game = workAppOwnedGame(
    units: [workAppUnit(id: 'spy1', type: kUnitTypeSpy)],
    provinces: [workAppOwnedProvince(ownerId: 'p2')],
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
  );
  final next = waaApply(
    game,
    workAppSingleWorkOrder(unitId: 'spy1', target: kWorkTargetCounterSpy),
  );
  final spyAfter = waaSingleUnit(next);
  expect(spyAfter.currentWork, isNotNull);
  expect(spyAfter.currentWork!.workTarget, kWorkTargetCounterSpy);
  expect(spyAfter.currentWork!.totalTurns, 0);
  expect(spyAfter.currentWork!.remainingTurns, 1);
}

void _purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppPurchaseLandGame(
    units: [waaMerchantOnMinor()],
    players: [workAppPlayer(treasury: cost + 100)],
    overtureStates: const [
      OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
  final next = waaApply(game, waaPurchaseLandOrders());
  waaExpectPurchased(next, ownerId: 'p1');
  waaExpectTreasuryDelta(game, next, 'p1', -cost);
  waaExpectUnitIdleAfterWork(next, tileKey: WorkAppIds.tileKeyMinor);
}

void _purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppPurchaseLandGame(
    units: [waaMerchantOnMinor()],
    players: [workAppPlayer(treasury: cost + 100)],
  );
  final next = waaApply(game, waaPurchaseLandOrders());
  waaExpectPurchased(next, ownerId: null);
  waaExpectTreasuryUnchanged(game, next, 'p1');
}

void _purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppPurchaseLandGame(
    units: [waaMerchantOnMinor()],
    players: [workAppPlayer(treasury: cost + 100)],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'p1',
        factionId2: 'minor1',
        state: RelationState.atWar,
      ),
    ],
  );
  final next = waaApply(game, waaPurchaseLandOrders());
  waaExpectPurchased(next, ownerId: null);
  waaExpectTreasuryUnchanged(game, next, 'p1');
}

void _purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppPurchaseLandGame(
    units: [
      waaMerchantOnMinor(id: 'merchant1', ownerId: 'p1'),
      waaMerchantOnMinor(id: 'merchant2', ownerId: 'p2'),
    ],
    players: [
      workAppPlayer(
        id: 'p1',
        treasury: cost + 100,
        capitalProvinceId: WorkAppIds.provinceId,
      ),
      workAppPlayer(
        id: 'p2',
        displayName: 'P2',
        isHuman: false,
        treasury: cost + 100,
        capitalProvinceId: WorkAppIds.provinceId,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
      OvertureState(
        gpId: 'p2',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        const WorkOrder(
          unitId: 'merchant1',
          target: kWorkTargetPurchaseLand,
          targetTileKey: WorkAppIds.tileKeyMinor,
        ),
      ],
      'p2': [
        const WorkOrder(
          unitId: 'merchant2',
          target: kWorkTargetPurchaseLand,
          targetTileKey: WorkAppIds.tileKeyMinor,
        ),
      ],
    },
  );
  final next = waaApply(game, orders);
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
  final game = waaEngineerFortGame(
    fortLevel: 1,
    stockpile: const Stockpile(),
    techUnlocked: const {},
  );
  final next = waaApply(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  waaExpectFortLevel(next, 1);
  waaExpectUnitCurrentWorkNull(next);
}

void _buildFortLevel3SkippedWithoutModernForts() {
  final game = waaEngineerFortGame(
    fortLevel: 2,
    stockpile: const Stockpile(),
    techUnlocked: const {kTechIdMineEngineering: true},
  );
  final next = waaApply(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  waaExpectFortLevel(next, 2);
  waaExpectUnitCurrentWorkNull(next);
}

void _upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel() {
  final game = workAppOwnedGame(
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
  );
  final next = waaApply(game, workAppProcessWorkOrders());
  expect(
    next.worldState.oldWorld.provinces.single.townDevelopmentLevel,
    2,
  );
}

void _counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork() {
  final p1Spy = workAppWorkingUnit(
    id: 'spy1',
    type: kUnitTypeSpy,
    workTarget: kWorkTargetCounterSpy,
    totalTurns: 0,
    remainingTurns: 1,
  );
  final p2Spy = workAppUnit(id: 'spy2', type: kUnitTypeSpy, ownerId: 'p2');
  final game = workAppOwnedGame(
    turnNumber: 1,
    globalGameSeed: 12345,
    units: [p1Spy, p2Spy],
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
  final next = waaApply(
    game,
    workAppProcessWorkOrders(playerIds: const ['p1', 'p2']),
  );
  final units = next.worldState.oldWorld.units;
  expect(units.any((u) => u.id == 'spy1'), isTrue);
  expect(units.any((u) => u.id == 'spy2'), isTrue);
  expect(units.length, 2);
}
