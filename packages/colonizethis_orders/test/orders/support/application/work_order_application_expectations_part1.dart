part of 'work_order_application_expectations.dart';

Game _prospectGame({Map<String, String>? resourceByTileKey}) {
  return workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeExplorer)],
    resourceByTileKey: resourceByTileKey,
  );
}

Orders _prospectOrders() => workAppSingleWorkOrder(target: kWorkTargetProspect);

void _prospectAddsTilePlayerProspectedTilesWhenTerrainEligible() {
  final next = applyBuildAndWorkOrders(
    _prospectGame(),
    _prospectOrders(),
    tileMapByRegion: {
      WorkAppIds.ow: OrdersApplicationTestSupport.tileMapWithTerrain(
        TerrainType.hills,
      ),
    },
  );
  expect(
    next.worldState.playerProspectedTiles['p1'],
    contains(WorkAppIds.tileKey),
  );
  final explorerAfter = next.worldState.oldWorld.units.single;
  expect(explorerAfter.tileKey, WorkAppIds.tileKey);
  expect(explorerAfter.status, UnitStatus.idle);
  expect(explorerAfter.currentWork, isNull);
  expect(explorerAfter.originTileKey, isNull);
  expect(explorerAfter.assignedTileKey, isNull);
}

void _prospectOnNonMineralEligibleTerrainDoesNotAddTile() {
  final next = applyBuildAndWorkOrders(
    _prospectGame(),
    _prospectOrders(),
    tileMapByRegion: {
      WorkAppIds.ow: OrdersApplicationTestSupport.tileMapWithTerrain(
        TerrainType.plains,
      ),
    },
  );
  final prospected =
      next.worldState.playerProspectedTiles['p1'] ?? const <String>{};
  expect(prospected, isNot(contains(WorkAppIds.tileKey)));
}

void _prospectAddsTileWhenMineralResourcePresentWithoutTileMap() {
  final next = applyBuildAndWorkOrders(
    _prospectGame(resourceByTileKey: {WorkAppIds.tileKey: 'iron'}),
    _prospectOrders(),
  );
  expect(
    next.worldState.playerProspectedTiles['p1'],
    contains(WorkAppIds.tileKey),
  );
}

void _prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap() {
  final next = applyBuildAndWorkOrders(
    _prospectGame(resourceByTileKey: {WorkAppIds.tileKey: 'grain'}),
    _prospectOrders(),
  );
  final prospected =
      next.worldState.playerProspectedTiles['p1'] ?? const <String>{};
  expect(prospected, isNot(contains(WorkAppIds.tileKey)));
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
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildImprovement),
  );
  final u = next.worldState.oldWorld.units.single;
  // totalTurns=1 for build_improvement at level 0, so work completes in same phase; unit is idle and tile improved.
  expect(u.currentWork, isNull);
  expect(u.status, UnitStatus.idle);
  expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 1);
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
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  final u = next.worldState.oldWorld.units.single;
  expect(
    u.currentWork!.totalTurns,
    totalTurnsForWork(kWorkTargetBuildFort, fortLevel: 1),
  );
  expect(u.currentWork!.remainingTurns, 1);
  expect(u.originTileKey, WorkAppIds.tileKey);
  expect(u.assignedTileKey, WorkAppIds.tileKey);
  expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
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
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(unitId: 'spy1', target: kWorkTargetCounterSpy),
  );
  final spyAfter = next.worldState.oldWorld.units.single;
  expect(spyAfter.currentWork, isNotNull);
  expect(spyAfter.currentWork!.workTarget, kWorkTargetCounterSpy);
  expect(spyAfter.currentWork!.totalTurns, 0);
  expect(spyAfter.currentWork!.remainingTurns, 1);
}

Unit _merchantOnMinor({String id = 'merchant1', String ownerId = 'p1'}) =>
    workAppUnit(
      id: id,
      type: kUnitTypeMerchant,
      ownerId: ownerId,
      locationProvinceId: WorkAppIds.minorProvinceId,
      tileKey: WorkAppIds.tileKeyMinor,
    );

Orders _purchaseLandOrders({
  String unitId = 'merchant1',
  String playerId = 'p1',
}) => workAppSingleWorkOrder(
  unitId: unitId,
  playerId: playerId,
  target: kWorkTargetPurchaseLand,
  targetTileKey: WorkAppIds.tileKeyMinor,
);

void _purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppPurchaseLandGame(
    units: [_merchantOnMinor()],
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
  final next = applyBuildAndWorkOrders(game, _purchaseLandOrders());
  expect(
    next.worldState.purchasedTilesByTileKey[WorkAppIds.tileKeyMinor],
    'p1',
  );
  expect(next.players.single.treasury, game.players.single.treasury - cost);
  final merchantAfter = next.worldState.oldWorld.units.single;
  expect(merchantAfter.tileKey, WorkAppIds.tileKeyMinor);
  expect(merchantAfter.status, UnitStatus.idle);
  expect(merchantAfter.currentWork, isNull);
  expect(merchantAfter.originTileKey, isNull);
  expect(merchantAfter.assignedTileKey, isNull);
}

void _purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppPurchaseLandGame(
    units: [_merchantOnMinor()],
    players: [workAppPlayer(treasury: cost + 100)],
    // No overtureStates → no Embassy with province owner.
  );
  final next = applyBuildAndWorkOrders(game, _purchaseLandOrders());
  expect(
    next.worldState.purchasedTilesByTileKey[WorkAppIds.tileKeyMinor],
    isNull,
  );
  expect(next.players.single.treasury, game.players.single.treasury);
}

void _purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppPurchaseLandGame(
    units: [_merchantOnMinor()],
    players: [workAppPlayer(treasury: cost + 100)],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'p1',
        factionId2: 'minor1',
        state: RelationState.atWar,
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(game, _purchaseLandOrders());
  expect(
    next.worldState.purchasedTilesByTileKey[WorkAppIds.tileKeyMinor],
    isNull,
  );
  expect(next.players.single.treasury, game.players.single.treasury);
}

void _purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppPurchaseLandGame(
    units: [
      _merchantOnMinor(id: 'merchant1', ownerId: 'p1'),
      _merchantOnMinor(id: 'merchant2', ownerId: 'p2'),
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
  final next = applyBuildAndWorkOrders(game, orders);
  expect(
    next.worldState.purchasedTilesByTileKey[WorkAppIds.tileKeyMinor],
    'p1',
  );
  final p1After = next.playerById('p1')!;
  final p2After = next.playerById('p2')!;
  expect(p1After.treasury, game.playerById('p1')!.treasury - cost);
  expect(p2After.treasury, game.playerById('p2')!.treasury);
}

void _buildFortWithSufficientMaterialsDeductsMaterials() {
  final cost = workOrderCostBuildFort(0);
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeEngineer)],
    provinces: [workAppOwnedProvince(fortLevel: 0)],
    players: [
      workAppPlayer(
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  for (final e in cost.entries) {
    expect(
      next.players.single.stockpile.quantityOf(e.key),
      game.players.single.stockpile.quantityOf(e.key) - e.value,
    );
  }
}

void _buildFortLevel2SkippedWithoutMineEngineering() {
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeEngineer)],
    provinces: [workAppOwnedProvince(fortLevel: 1)],
    players: [workAppPlayer(techUnlocked: const {})],
  );
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
  expect(next.worldState.oldWorld.units.single.currentWork, isNull);
}

void _buildFortLevel3SkippedWithoutModernForts() {
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeEngineer)],
    provinces: [workAppOwnedProvince(fortLevel: 2)],
    players: [
      workAppPlayer(techUnlocked: const {kTechIdMineEngineering: true}),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  expect(next.worldState.oldWorld.provinces.single.fortLevel, 2);
  expect(next.worldState.oldWorld.units.single.currentWork, isNull);
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
  final next = applyBuildAndWorkOrders(game, workAppProcessWorkOrders());
  expect(next.worldState.oldWorld.provinces.single.townDevelopmentLevel, 2);
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
  final next = applyBuildAndWorkOrders(
    game,
    workAppProcessWorkOrders(playerIds: const ['p1', 'p2']),
  );
  final units = next.worldState.oldWorld.units;
  expect(units.any((u) => u.id == 'spy1'), isTrue);
  expect(units.any((u) => u.id == 'spy2'), isTrue);
  expect(units.length, 2);
}
