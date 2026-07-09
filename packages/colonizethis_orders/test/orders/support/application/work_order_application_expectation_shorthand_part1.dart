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
