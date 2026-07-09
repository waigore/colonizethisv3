// Compact work-order application expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'orders_application_test_support.dart';
import 'work_application_fixtures.dart';

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

void waaExpectUnitIdleAfterWork(
  Game next, {
  String tileKey = WorkAppIds.tileKey,
}) {
  final u = waaSingleUnit(next);
  expect(u.tileKey, tileKey);
  expect(u.status, UnitStatus.idle);
  expect(u.currentWork, isNull);
  expect(u.originTileKey, isNull);
  expect(u.assignedTileKey, isNull);
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

void waaExpectImprovementLevel(Game next, int level) {
  expect(
    next.worldState.tileState.improvementLevel(WorkAppIds.tileKey),
    level,
  );
}

void waaExpectCounterSpyWork(Game next) {
  final u = waaSingleUnit(next);
  expect(u.currentWork, isNotNull);
  expect(u.currentWork!.workTarget, kWorkTargetCounterSpy);
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
