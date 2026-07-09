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

Game waaApplyBuildImprovement({
  String unitType = kUnitTypeBuilder,
  Map<String, String>? resourceByTileKey,
}) {
  final cost = workOrderCostBuildImprovement(0);
  return waaApply(
    workAppOwnedGame(
      units: [workAppUnit(type: unitType)],
      resourceByTileKey:
          resourceByTileKey ?? {WorkAppIds.tileKey: 'grain'},
      players: [
        workAppPlayer(
          stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
        ),
      ],
    ),
    workAppSingleWorkOrder(target: kWorkTargetBuildImprovement),
  );
}

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

Game waaCounterSpyForeignProvinceGame({String spyId = 'spy1'}) =>
    workAppOwnedGame(
      units: [workAppUnit(id: spyId, type: kUnitTypeSpy)],
      provinces: [workAppOwnedProvince(ownerId: 'p2')],
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: true),
      ],
    );

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

Game waaDualGpPurchaseLandGame() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  return workAppPurchaseLandGame(
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
    overtureStates: [
      waaEmbassyOverture(),
      waaEmbassyOverture(gpId: 'p2'),
    ],
  );
}

Orders waaDualPurchaseLandOrders() => Orders(
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

void waaExpectTownDevelopmentLevel(Game next, int level) {
  expect(
    next.worldState.oldWorld.provinces.single.townDevelopmentLevel,
    level,
  );
}

void waaExpectUnitIdsPresent(Game next, List<String> ids) {
  final units = next.worldState.oldWorld.units;
  expect(units.length, ids.length);
  for (final id in ids) {
    expect(units.any((u) => u.id == id), isTrue);
  }
}

Game waaApplyBuildRoad(Game game) =>
    waaApply(game, workAppSingleWorkOrder(target: kWorkTargetBuildRoad));

void waaExpectBuildRoadInsufficientMaterials() {
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeEngineer)],
    players: [workAppPlayer(stockpile: const Stockpile())],
  );
  final next = waaApplyBuildRoad(game);
  waaExpectUnitIdle(next);
  expect(
    next.players.single.stockpile.quantityOf(CommodityCatalog.lumber.id),
    0,
  );
}

void waaExpectBuildRoadWithMaterialsDeductsStockpile() {
  final cost = workOrderCostBuildRoad;
  final game = waaEngineerRoadGame();
  final next = waaApplyBuildRoad(game);
  waaExpectUnitIdle(next);
  waaExpectRoadLevel(next, 1);
  waaExpectStockpileDeducted(game, next, cost);
}

Game waaCounterSpyCapitalGame({String spyId = 'spy1'}) => workAppOwnedGame(
      units: [workAppUnit(id: spyId, type: kUnitTypeSpy)],
      tileKeysByRegionAndProvince: const {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey],
        },
      },
      players: [workAppPlayer(capitalProvinceId: WorkAppIds.provinceId)],
    );

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
