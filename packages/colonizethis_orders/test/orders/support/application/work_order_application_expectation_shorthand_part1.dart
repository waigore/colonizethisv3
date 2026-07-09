part of 'work_order_application_expectation_shorthand.dart';


Game waaApply(
  Game game,
  Orders orders, {
  Map<String, TileMapResult>? tileMapByRegion,
}) =>
    applyBuildAndWorkOrders(
      game,
      orders,
      tileMapByRegion: tileMapByRegion,
    );

Unit waaSingleUnit(Game game) => game.worldState.oldWorld.units.single;

void waaExpectPurchased(
  Game next, {
  required String? ownerId,
  String tileKey = WorkAppIds.tileKeyMinor,
}) {
  expect(next.worldState.purchasedTilesByTileKey[tileKey], ownerId);
}

void waaExpectStockpileDeducted(
  Game before,
  Game after,
  Map<String, int> cost, {
  String playerId = 'p1',
}) {
  for (final e in cost.entries) {
    expect(
      after.playerById(playerId)!.stockpile.quantityOf(e.key),
      before.playerById(playerId)!.stockpile.quantityOf(e.key) - e.value,
    );
  }
}

void waaExpectUnitIdle(Game next) {
  final u = waaSingleUnit(next);
  expect(u.status, UnitStatus.idle);
  expect(u.currentWork, isNull);
}

void waaExpectRoadLevel(Game next, int level) {
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), level);
}

void waaExpectExploreWork(
  Game next, {
  int? totalTurns,
  int? remainingTurns,
}) {
  final u = waaSingleUnit(next);
  expect(u.currentWork, isNotNull);
  expect(u.currentWork!.workTarget, kWorkTargetExplore);
  if (totalTurns != null) {
    expect(u.currentWork!.totalTurns, totalTurns);
  }
  if (remainingTurns != null) {
    expect(u.currentWork!.remainingTurns, remainingTurns);
  }
}

Game waaEngineerRoadGame({Stockpile? stockpile}) => workAppOwnedGame(
      units: [workAppUnit(type: kUnitTypeEngineer)],
      players: [
        workAppPlayer(
          stockpile: stockpile ??
              OrdersApplicationTestSupport.stockpileCovering(
                workOrderCostBuildRoad,
              ),
        ),
      ],
    );

Game waaEngineerFortGame({
  int fortLevel = 0,
  Stockpile? stockpile,
  Map<String, bool>? techUnlocked,
}) =>
    workAppOwnedGame(
      units: [workAppUnit(type: kUnitTypeEngineer)],
      provinces: [workAppOwnedProvince(fortLevel: fortLevel)],
      players: [
        workAppPlayer(
          stockpile: stockpile ??
              OrdersApplicationTestSupport.stockpileCovering(
                workOrderCostBuildFort(fortLevel),
              ),
          techUnlocked: techUnlocked,
        ),
      ],
    );

void waaExpectCurrentWorkTiming(
  Game next, {
  required String workTarget,
  int? totalTurns,
  int? remainingTurns,
  String? originTileKey,
  String? assignedTileKey,
  String unitId = 'u1',
}) {
  final u = next.worldState.oldWorld.units.firstWhere((u) => u.id == unitId);
  expect(u.currentWork, isNotNull);
  expect(u.currentWork!.workTarget, workTarget);
  if (totalTurns != null) {
    expect(u.currentWork!.totalTurns, totalTurns);
  }
  if (remainingTurns != null) {
    expect(u.currentWork!.remainingTurns, remainingTurns);
  }
  if (originTileKey != null) {
    expect(u.originTileKey, originTileKey);
  }
  if (assignedTileKey != null) {
    expect(u.assignedTileKey, assignedTileKey);
  }
}

void waaExpectProspect({
  required bool expected,
  TerrainType? terrain,
  Map<String, String>? resourceByTileKey,
}) {
  final next = waaApply(
    workAppOwnedGame(
      units: [workAppUnit(type: kUnitTypeExplorer)],
      resourceByTileKey: resourceByTileKey,
    ),
    workAppSingleWorkOrder(target: kWorkTargetProspect),
    tileMapByRegion: terrain == null
        ? null
        : {
            WorkAppIds.ow: OrdersApplicationTestSupport.tileMapWithTerrain(
              terrain,
            ),
          },
  );
  final prospected =
      next.worldState.playerProspectedTiles['p1'] ?? const <String>{};
  if (expected) {
    expect(prospected, contains(WorkAppIds.tileKey));
  } else {
    expect(prospected, isNot(contains(WorkAppIds.tileKey)));
  }
  if (expected) {
    final u = waaSingleUnit(next);
    expect(u.tileKey, WorkAppIds.tileKey);
    expect(u.status, UnitStatus.idle);
    expect(u.currentWork, isNull);
    expect(u.originTileKey, isNull);
    expect(u.assignedTileKey, isNull);
  }
}

Game waaSpyCounterProcessGame() => workAppOwnedGame(
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

Game waaSpyOnCapitalGame() => workAppOwnedGame(
      units: [workAppUnit(id: 'spy1', type: kUnitTypeSpy)],
      tileKeysByRegionAndProvince: const {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey],
        },
      },
      players: [workAppPlayer(capitalProvinceId: WorkAppIds.provinceId)],
    );

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

Game waaEngineerPortGame() {
  final cost = workOrderMaterialCost(kWorkTargetBuildPort);
  expect(cost, isNotNull);
  return workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeEngineer)],
    players: [
      workAppPlayer(
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost!),
      ),
    ],
  );
}

void waaExpectBuildImprovementCompletes() {
  final cost = workOrderCostBuildImprovement(0);
  final next = waaApply(
    workAppOwnedGame(
      units: [workAppUnit(type: kUnitTypeBuilder)],
      resourceByTileKey: {WorkAppIds.tileKey: 'grain'},
      players: [
        workAppPlayer(
          stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
        ),
      ],
    ),
    workAppSingleWorkOrder(target: kWorkTargetBuildImprovement),
  );
  expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 1);
  waaExpectUnitIdle(next);
}

void waaExpectPurchaseRejected({
  List<OvertureState> overtureStates = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
}) {
  final game = workAppSingleGpPurchaseLandGame(
    overtureStates: overtureStates,
    diplomacyRelations: diplomacyRelations,
  );
  final next = waaApply(game, workAppPurchaseLandOrders());
  waaExpectPurchased(next, ownerId: null);
  expect(next.playerById('p1')!.treasury, game.playerById('p1')!.treasury);
}

void waaExpectDualGpPurchaseFirstWins() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppPurchaseLandGame(
    units: [
      workAppPurchaseLandMerchant(),
      workAppPurchaseLandMerchant(id: 'merchant2', ownerId: 'p2'),
    ],
    players: [
      workAppPlayer(
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
  final next = waaApply(
    game,
    Orders(
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
    ),
  );
  waaExpectPurchased(next, ownerId: 'p1');
  expect(
    next.playerById('p1')!.treasury,
    game.playerById('p1')!.treasury - cost,
  );
  expect(next.playerById('p2')!.treasury, game.playerById('p2')!.treasury);
}

void waaExpectFortSkipAtLevel(int fortLevel) {
  final next = waaApply(
    waaEngineerFortGame(
      fortLevel: fortLevel,
      stockpile: const Stockpile(),
      techUnlocked: fortLevel == 1 ? const {} : const {kTechIdMineEngineering: true},
    ),
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  expect(next.worldState.oldWorld.provinces.single.fortLevel, fortLevel);
  expect(waaSingleUnit(next).currentWork, isNull);
}
