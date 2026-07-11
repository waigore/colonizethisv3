// Compact work-order application expectation shorthands (Refs #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../common/expectation_asserts.dart';
import 'orders_application_test_support.dart';
import 'work_application_fixtures.dart';

Game waaApply(Game game, Orders orders, {Map<String, TileMapResult>? tileMapByRegion}) =>
    applyBuildAndWorkOrders(game, orders, tileMapByRegion: tileMapByRegion);

Unit waaSingleUnit(Game game) => game.worldState.oldWorld.units.single;

void waaExpectPurchased(Game next, {required String? ownerId, String tileKey = WorkAppIds.tileKeyMinor}) =>
    expect(next.worldState.purchasedTilesByTileKey[tileKey], ownerId);

void waaExpectStockpileDeducted(Game before, Game after, Map<String, int> cost, {String playerId = 'p1'}) =>
    expectStockpileDeducted(before, after, cost, playerId: playerId);

void waaExpectUnitIdle(Game next) {
  final u = waaSingleUnit(next);
  expect(u.status, UnitStatus.idle);
  expect(u.currentWork, isNull);
}

void waaExpectRoadLevel(Game next, int level) => expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), level);

void waaExpectExploreWork(Game next, {int? totalTurns, int? remainingTurns}) =>
    expectCurrentWorkFields(waaSingleUnit(next), workTarget: kWorkTargetExplore, totalTurns: totalTurns, remainingTurns: remainingTurns);

// dart format off
Game waaEngineerRoadGame({Stockpile? stockpile}) => workAppOwnedGame(units: [workAppUnit(type: kUnitTypeEngineer)], players: [workAppPlayer(stockpile: stockpile ?? OrdersApplicationTestSupport.stockpileCovering(workOrderCostBuildRoad))]);

Game waaEngineerFortGame({int fortLevel = 0, Stockpile? stockpile, Map<String, bool>? techUnlocked}) => workAppOwnedGame(units: [workAppUnit(type: kUnitTypeEngineer)], provinces: [workAppOwnedProvince(fortLevel: fortLevel)], players: [workAppPlayer(stockpile: stockpile ?? OrdersApplicationTestSupport.stockpileCovering(workOrderCostBuildFort(fortLevel)), techUnlocked: techUnlocked)]);

void waaExpectCurrentWorkTiming(Game next, {required String workTarget, int? totalTurns, int? remainingTurns, String? originTileKey, String? assignedTileKey, String unitId = 'u1'}) {
  final u = next.worldState.oldWorld.units.firstWhere((u) => u.id == unitId);
  expectCurrentWorkFields(u, workTarget: workTarget, totalTurns: totalTurns, remainingTurns: remainingTurns);
  if (originTileKey != null) expect(u.originTileKey, originTileKey);
  if (assignedTileKey != null) expect(u.assignedTileKey, assignedTileKey);
}

void waaExpectProspect({required bool expected, TerrainType? terrain, Map<String, String>? resourceByTileKey}) {
  final next = waaApply(
    workAppOwnedGame(units: [workAppUnit(type: kUnitTypeExplorer)], resourceByTileKey: resourceByTileKey),
    workAppSingleWorkOrder(target: kWorkTargetProspect),
    tileMapByRegion: terrain == null ? null : {WorkAppIds.ow: OrdersApplicationTestSupport.tileMapWithTerrain(terrain)},
  );
  final prospected = next.worldState.playerProspectedTiles['p1'] ?? const <String>{};
  expect(prospected.contains(WorkAppIds.tileKey), expected);
  if (expected) expectUnitIdleCleared(waaSingleUnit(next), tileKey: WorkAppIds.tileKey);
}

void waaExpectPurchaseRejected({List<OvertureState> overtureStates = const [], List<DiplomacyRelation> diplomacyRelations = const []}) {
  final game = workAppSingleGpPurchaseLandGame(overtureStates: overtureStates, diplomacyRelations: diplomacyRelations);
  final next = waaApply(game, workAppPurchaseLandOrders());
  waaExpectPurchased(next, ownerId: null);
  expect(next.playerById('p1')!.treasury, game.playerById('p1')!.treasury);
}

void waaExpectFortSkipAtLevel(int fortLevel) {
  final next = waaApply(
    waaEngineerFortGame(fortLevel: fortLevel, stockpile: const Stockpile(), techUnlocked: fortLevel == 1 ? const {} : const {kTechIdMineEngineering: true}),
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  expect(next.worldState.oldWorld.provinces.single.fortLevel, fortLevel);
  expect(waaSingleUnit(next).currentWork, isNull);
}

void waaExpectPurchaseSuccess() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppSingleGpPurchaseLandGame(overtureStates: const [OvertureState(gpId: 'p1', targetId: 'minor1', stage: OvertureStage.embassy, sinceTurn: 0)]);
  final next = waaApply(game, workAppPurchaseLandOrders());
  waaExpectPurchased(next, ownerId: 'p1');
  expect(next.playerById('p1')!.treasury, game.playerById('p1')!.treasury - cost);
  expectUnitIdleCleared(waaSingleUnit(next), tileKey: WorkAppIds.tileKeyMinor);
}

void waaExpectDualPurchaseFirstWins() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppPurchaseLandGame(
    units: [workAppPurchaseLandMerchant(), workAppPurchaseLandMerchant(id: 'merchant2', ownerId: 'p2')],
    players: [
      workAppPlayer(treasury: cost + 100, capitalProvinceId: WorkAppIds.provinceId),
      workAppPlayer(id: 'p2', displayName: 'P2', isHuman: false, treasury: cost + 100, capitalProvinceId: WorkAppIds.provinceId),
    ],
    overtureStates: const [
      OvertureState(gpId: 'p1', targetId: 'minor1', stage: OvertureStage.embassy, sinceTurn: 0),
      OvertureState(gpId: 'p2', targetId: 'minor1', stage: OvertureStage.embassy, sinceTurn: 0),
    ],
  );
  final next = waaApply(game, Orders(workOrdersByPlayerId: {
    'p1': [const WorkOrder(unitId: 'merchant1', target: kWorkTargetPurchaseLand, targetTileKey: WorkAppIds.tileKeyMinor)],
    'p2': [const WorkOrder(unitId: 'merchant2', target: kWorkTargetPurchaseLand, targetTileKey: WorkAppIds.tileKeyMinor)],
  }));
  waaExpectPurchased(next, ownerId: 'p1');
  expect(next.playerById('p1')!.treasury, game.playerById('p1')!.treasury - cost);
  expect(next.playerById('p2')!.treasury, game.playerById('p2')!.treasury);
}

void waaExpectBuildImprovementCompletes() {
  final next = waaApply(
    workAppOwnedGame(units: [workAppUnit(type: kUnitTypeBuilder)], resourceByTileKey: {WorkAppIds.tileKey: 'grain'}, players: [workAppPlayer(stockpile: OrdersApplicationTestSupport.stockpileCovering(workOrderCostBuildImprovement(0)))]),
    workAppSingleWorkOrder(target: kWorkTargetBuildImprovement),
  );
  expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 1);
  waaExpectUnitIdle(next);
}

void waaExpectCounterSpyTiming({required Game game, String unitId = 'spy1'}) {
  final next = waaApply(game, workAppSingleWorkOrder(unitId: unitId, target: kWorkTargetCounterSpy));
  waaExpectCurrentWorkTiming(next, unitId: unitId, workTarget: kWorkTargetCounterSpy, totalTurns: 0, remainingTurns: 1);
}

void waaExpectExploreFormulaTotalTurns2() {
  const small = '${WorkAppIds.ow}|P1'; const large = '${WorkAppIds.ow}|P2';
  const s1 = '${WorkAppIds.ow}|P1|0|0'; const s2 = '${WorkAppIds.ow}|P1|1|0';
  const l1 = '${WorkAppIds.ow}|P2|0|0'; const l2 = '${WorkAppIds.ow}|P2|1|0';
  const l3 = '${WorkAppIds.ow}|P2|2|0'; const l4 = '${WorkAppIds.ow}|P2|3|0';
  waaExpectExploreWork(
    waaApply(
      workAppOwnedGame(
        units: [workAppUnit(type: kUnitTypeExplorer, locationProvinceId: small, tileKey: s1)],
        provinces: const [Province(id: small, regionId: WorkAppIds.ow, ownerId: 'p1'), Province(id: large, regionId: WorkAppIds.ow, ownerId: 'p1')],
        tileKeysByRegionAndProvince: const {WorkAppIds.ow: {small: [s1, s2], large: [l1, l2, l3, l4]}},
      ),
      workAppSingleWorkOrder(target: kWorkTargetExplore, targetTileKey: s1),
    ),
    totalTurns: 2,
    remainingTurns: 1,
  );
}

void waaExpectPortCompletesWhenAffordable() {
  final cost = workOrderMaterialCost(kWorkTargetBuildPort);
  expect(cost, isNotNull);
  waaExpectUnitIdle(waaApply(
    workAppOwnedGame(units: [workAppUnit(type: kUnitTypeEngineer)], players: [workAppPlayer(stockpile: OrdersApplicationTestSupport.stockpileCovering(cost!))]),
    workAppSingleWorkOrder(target: kWorkTargetBuildPort),
  ));
}
// dart format on
