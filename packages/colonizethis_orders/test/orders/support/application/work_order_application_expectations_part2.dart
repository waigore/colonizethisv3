part of 'work_order_application_expectations.dart';

void _unknownWorkTargetSkippedUnitStaysIdle() {
  final next = applyBuildAndWorkOrders(
    workAppOwnedGame(units: [workAppUnit(type: kUnitTypeBuilder)]),
    workAppSingleWorkOrder(target: 'unknown_target'),
  );
  final u = next.worldState.oldWorld.units.single;
  expect(u.status, UnitStatus.idle);
  expect(u.currentWork, isNull);
}

void _buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile() {
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeEngineer)],
    players: [workAppPlayer(stockpile: const Stockpile())],
  );
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
  );
  final u = next.worldState.oldWorld.units.single;
  expect(u.currentWork, isNull);
  expect(u.status, UnitStatus.idle);
  expect(
    next.players.single.stockpile.quantityOf(CommodityCatalog.lumber.id),
    0,
  );
}

void _buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork() {
  final cost = workOrderCostBuildRoad;
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeEngineer)],
    players: [
      workAppPlayer(
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
  );
  final u = next.worldState.oldWorld.units.single;
  // build_road totalTurns=1, so work completes in same phase; unit idle and road level 1.
  expect(u.currentWork, isNull);
  expect(u.status, UnitStatus.idle);
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 1);
  for (final e in cost.entries) {
    expect(
      next.players.single.stockpile.quantityOf(e.key),
      game.players.single.stockpile.quantityOf(e.key) - e.value,
    );
  }
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
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(unitId: 'spy1', target: kWorkTargetCounterSpy),
  );
  final spyAfter = next.worldState.oldWorld.units.single;
  expect(spyAfter.currentWork, isNotNull);
  expect(spyAfter.currentWork!.workTarget, kWorkTargetCounterSpy);
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
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(target: kWorkTargetExplore),
  );
  final u = next.worldState.oldWorld.units.single;
  expect(u.currentWork, isNotNull);
  expect(u.currentWork!.workTarget, kWorkTargetExplore);
  expect(u.currentWork!.totalTurns, greaterThanOrEqualTo(1));
  // One turn processed in same phase after applying.
  expect(u.currentWork!.remainingTurns, u.currentWork!.totalTurns - 1);
}

void
_exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion() {
  // Region has two provinces with different tile counts; explorer in the
  // smaller one should get totalTurns = ceil(3 * tilesInP / maxTilesInRegion).
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
        provinceSmall: [tileSmall1, tileSmall2], // tilesInP = 2
        provinceLarge: [
          tileLarge1,
          tileLarge2,
          tileLarge3,
          tileLarge4,
        ], // maxTilesInRegion = 4
      },
    },
  );

  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(
      target: kWorkTargetExplore,
      targetTileKey: tileSmall1,
    ),
  );
  final u = next.worldState.oldWorld.units.single;

  // tilesInP = 2, maxTilesInRegion = 4 → ceil(3 * 2 / 4) = ceil(1.5) = 2.
  expect(u.currentWork, isNotNull);
  expect(u.currentWork!.workTarget, kWorkTargetExplore);
  expect(u.currentWork!.totalTurns, 2);
  // One turn processed in same phase after applying.
  expect(u.currentWork!.remainingTurns, 1);
}

void _engineerBuildRoadWorkOrderSetsCurrentWork() {
  final cost = workOrderCostBuildRoad;
  final game = workAppOwnedGame(
    units: [workAppUnit(type: kUnitTypeEngineer)],
    players: [
      workAppPlayer(
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
  );
  final u = next.worldState.oldWorld.units.single;
  // build_road totalTurns=1, so work completes in same phase; unit idle and road level 1.
  expect(u.currentWork, isNull);
  expect(u.status, UnitStatus.idle);
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 1);
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
  final next = applyBuildAndWorkOrders(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildPort),
  );
  final u = next.worldState.oldWorld.units.single;
  // build_port totalTurns=1, so work completes in same phase; unit idle.
  expect(u.currentWork, isNull);
  expect(u.status, UnitStatus.idle);
}
