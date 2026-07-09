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

void waaExpectProspected(
  Game next, {
  required bool expected,
  String playerId = 'p1',
  String tileKey = WorkAppIds.tileKey,
}) {
  final prospected =
      next.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  if (expected) {
    expect(prospected, contains(tileKey));
  } else {
    expect(prospected, isNot(contains(tileKey)));
  }
}

void waaExpectPurchased(
  Game next, {
  required String? ownerId,
  String tileKey = WorkAppIds.tileKeyMinor,
}) {
  expect(next.worldState.purchasedTilesByTileKey[tileKey], ownerId);
}

void waaExpectTreasuryUnchanged(Game before, Game after, String playerId) {
  expect(
    after.playerById(playerId)!.treasury,
    before.playerById(playerId)!.treasury,
  );
}

void waaExpectTreasuryDelta(
  Game before,
  Game after,
  String playerId,
  int delta,
) {
  expect(
    after.playerById(playerId)!.treasury,
    before.playerById(playerId)!.treasury + delta,
  );
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

void waaExpectFortLevel(Game next, int level) {
  expect(next.worldState.oldWorld.provinces.single.fortLevel, level);
}

void waaExpectUnitCurrentWorkNull(Game next) {
  expect(waaSingleUnit(next).currentWork, isNull);
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

Game waaProspectGame({Map<String, String>? resourceByTileKey}) =>
    workAppOwnedGame(
      units: [workAppUnit(type: kUnitTypeExplorer)],
      resourceByTileKey: resourceByTileKey,
    );

Orders waaProspectOrders() =>
    workAppSingleWorkOrder(target: kWorkTargetProspect);

Unit waaMerchantOnMinor({String id = 'merchant1', String ownerId = 'p1'}) =>
    workAppUnit(
      id: id,
      type: kUnitTypeMerchant,
      ownerId: ownerId,
      locationProvinceId: WorkAppIds.minorProvinceId,
      tileKey: WorkAppIds.tileKeyMinor,
    );

Orders waaPurchaseLandOrders({
  String unitId = 'merchant1',
  String playerId = 'p1',
}) =>
    workAppSingleWorkOrder(
      unitId: unitId,
      playerId: playerId,
      target: kWorkTargetPurchaseLand,
      targetTileKey: WorkAppIds.tileKeyMinor,
    );

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

Game waaProspectApply({
  Map<String, String>? resourceByTileKey,
  TerrainType? terrain,
}) =>
    waaApply(
      waaProspectGame(resourceByTileKey: resourceByTileKey),
      waaProspectOrders(),
      tileMapByRegion: terrain == null
          ? null
          : {
              WorkAppIds.ow: OrdersApplicationTestSupport.tileMapWithTerrain(
                terrain,
              ),
            },
    );

Game waaApplyBuildFort({
  int fortLevel = 1,
  Stockpile? stockpile,
  Map<String, bool>? techUnlocked,
}) =>
    waaApply(
      waaEngineerFortGame(
        fortLevel: fortLevel,
        stockpile: stockpile,
        techUnlocked: techUnlocked,
      ),
      workAppSingleWorkOrder(target: kWorkTargetBuildFort),
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

OvertureState waaEmbassyOverture({
  String gpId = 'p1',
  String targetId = 'minor1',
}) =>
    OvertureState(
      gpId: gpId,
      targetId: targetId,
      stage: OvertureStage.embassy,
      sinceTurn: 0,
    );

Game waaApplyBuildRoad(Game game) =>
    waaApply(game, workAppSingleWorkOrder(target: kWorkTargetBuildRoad));

void waaExpectProspect({
  required bool expected,
  TerrainType? terrain,
  Map<String, String>? resourceByTileKey,
}) {
  final next = waaProspectApply(
    terrain: terrain,
    resourceByTileKey: resourceByTileKey,
  );
  waaExpectProspected(next, expected: expected);
  if (expected) {
    final u = waaSingleUnit(next);
    expect(u.tileKey, WorkAppIds.tileKey);
    expect(u.status, UnitStatus.idle);
    expect(u.currentWork, isNull);
    expect(u.originTileKey, isNull);
    expect(u.assignedTileKey, isNull);
  }
}
