part of 'work_order_application_expectations.dart';

void woaLateCounterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork() {
  final next = waaApply(
    workAppOwnedGame(
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
    ),
    workAppProcessWorkOrders(playerIds: const ['p1', 'p2']),
  );
  final units = next.worldState.oldWorld.units;
  expect(units.length, 2);
  for (final id in const ['spy1', 'spy2']) {
    expect(units.any((u) => u.id == id), isTrue);
  }
}

void woaLateUnknownWorkTargetSkippedUnitStaysIdle() {
  final next = waaApply(
    workAppOwnedGame(units: [workAppUnit(type: kUnitTypeBuilder)]),
    workAppSingleWorkOrder(target: 'unknown_target'),
  );
  waaExpectUnitIdle(next);
}

void woaLateBuildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile() {
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

void woaLateBuildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork() {
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

void woaLateCounterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince() {
  final capitalSpyNext = waaApply(
    workAppOwnedGame(
      units: [workAppUnit(id: 'spy1', type: kUnitTypeSpy)],
      tileKeysByRegionAndProvince: const {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey],
        },
      },
      players: [workAppPlayer(capitalProvinceId: WorkAppIds.provinceId)],
    ),
    workAppSingleWorkOrder(
      unitId: 'spy1',
      target: kWorkTargetCounterSpy,
    ),
  );
  final counterSpyU = waaSingleUnit(capitalSpyNext);
  expect(counterSpyU.currentWork, isNotNull);
  expect(counterSpyU.currentWork!.workTarget, kWorkTargetCounterSpy);
}

void woaLateExploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles() {
  final next = waaApply(
    workAppOwnedGame(
      units: [workAppUnit(type: kUnitTypeExplorer)],
      tileKeysByRegionAndProvince: {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [
            WorkAppIds.tileKey,
            WorkAppIds.originTileKey,
          ],
        },
      },
    ),
    workAppSingleWorkOrder(target: kWorkTargetExplore),
  );
  final u = waaSingleUnit(next);
  expect(u.currentWork!.totalTurns, greaterThanOrEqualTo(1));
  waaExpectExploreWork(
    next,
    remainingTurns: u.currentWork!.totalTurns - 1,
  );
}

void woaLateExploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion() {
  const provinceSmall = '${WorkAppIds.ow}|P1';
  const provinceLarge = '${WorkAppIds.ow}|P2';
  const tileSmall1 = '${WorkAppIds.ow}|P1|0|0';
  const tileSmall2 = '${WorkAppIds.ow}|P1|1|0';
  const tileLarge1 = '${WorkAppIds.ow}|P2|0|0';
  const tileLarge2 = '${WorkAppIds.ow}|P2|1|0';
  const tileLarge3 = '${WorkAppIds.ow}|P2|2|0';
  const tileLarge4 = '${WorkAppIds.ow}|P2|3|0';
  final next = waaApply(
    workAppOwnedGame(
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
          provinceLarge: [
            tileLarge1,
            tileLarge2,
            tileLarge3,
            tileLarge4,
          ],
        },
      },
    ),
    workAppSingleWorkOrder(
      target: kWorkTargetExplore,
      targetTileKey: tileSmall1,
    ),
  );
  waaExpectExploreWork(next, totalTurns: 2, remainingTurns: 1);
}

void woaLateEngineerBuildRoadWorkOrderSetsCurrentWork() {
  final next = waaApply(
    waaEngineerRoadGame(),
    workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
  );
  waaExpectUnitIdle(next);
  waaExpectRoadLevel(next, 1);
}

void woaLateBuildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient() {
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
