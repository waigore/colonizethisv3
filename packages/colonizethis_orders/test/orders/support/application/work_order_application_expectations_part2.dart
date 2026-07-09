part of 'work_order_application_expectations.dart';

void _unknownWorkTargetSkippedUnitStaysIdle() {
  final next = waaApply(
    workAppOwnedGame(units: [workAppUnit(type: kUnitTypeBuilder)]),
    workAppSingleWorkOrder(target: 'unknown_target'),
  );
  waaExpectUnitIdle(next);
}

void _buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile() {
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeEngineer)],
    players: [workAppPlayer(stockpile: const Stockpile())],
  );
  final next = waaApply(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
  );
  waaExpectUnitIdle(next);
  expect(
    next.players.single.stockpile.quantityOf(CommodityCatalog.lumber.id),
    0,
  );
}

void _buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork() {
  final cost = workOrderCostBuildRoad;
  final game = waaEngineerRoadGame();
  final next = waaApply(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
  );
  waaExpectUnitIdle(next);
  waaExpectRoadLevel(next, 1);
  waaExpectStockpileDeducted(game, next, cost);
}

void _counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince() {
  final game = workAppOwnedGame(
    units: [workAppUnit(id: 'spy1', type: kUnitTypeSpy)],
    tileKeysByRegionAndProvince: const {
      WorkAppIds.ow: {
        WorkAppIds.provinceId: [WorkAppIds.tileKey],
      },
    },
    players: [workAppPlayer(capitalProvinceId: WorkAppIds.provinceId)],
  );
  final next = waaApply(
    game,
    workAppSingleWorkOrder(unitId: 'spy1', target: kWorkTargetCounterSpy),
  );
  waaExpectCounterSpyWork(next);
}

void _exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles() {
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeExplorer)],
    tileKeysByRegionAndProvince: {
      WorkAppIds.ow: {
        WorkAppIds.provinceId: [WorkAppIds.tileKey, WorkAppIds.originTileKey],
      },
    },
  );
  final next = waaApply(
    game,
    workAppSingleWorkOrder(target: kWorkTargetExplore),
  );
  final u = waaSingleUnit(next);
  expect(u.currentWork!.totalTurns, greaterThanOrEqualTo(1));
  waaExpectExploreWork(
    next,
    remainingTurns: u.currentWork!.totalTurns - 1,
  );
}

void
_exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion() {
  const provinceSmall = '${WorkAppIds.ow}|P1';
  const provinceLarge = '${WorkAppIds.ow}|P2';
  const tileSmall1 = '${WorkAppIds.ow}|P1|0|0';
  const tileSmall2 = '${WorkAppIds.ow}|P1|1|0';
  const tileLarge1 = '${WorkAppIds.ow}|P2|0|0';
  const tileLarge2 = '${WorkAppIds.ow}|P2|1|0';
  const tileLarge3 = '${WorkAppIds.ow}|P2|2|0';
  const tileLarge4 = '${WorkAppIds.ow}|P2|3|0';

  final game = workAppOwnedGame(
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

  final next = waaApply(
    game,
    workAppSingleWorkOrder(
      target: kWorkTargetExplore,
      targetTileKey: tileSmall1,
    ),
  );
  waaExpectExploreWork(next, totalTurns: 2, remainingTurns: 1);
}

void _engineerBuildRoadWorkOrderSetsCurrentWork() {
  final next = waaApply(
    waaEngineerRoadGame(),
    workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
  );
  waaExpectUnitIdle(next);
  waaExpectRoadLevel(next, 1);
}

void _buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient() {
  final cost = workOrderMaterialCost(kWorkTargetBuildPort);
  expect(cost, isNotNull);
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeEngineer)],
    players: [
      workAppPlayer(
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost!),
      ),
    ],
  );
  final next = waaApply(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildPort),
  );
  waaExpectUnitIdle(next);
}
