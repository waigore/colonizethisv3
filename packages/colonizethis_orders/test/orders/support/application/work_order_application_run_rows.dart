// Scenario run tear-offs for work order application family (Refs #3949 wave 3).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'orders_application_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'work_application_fixtures.dart';
import 'work_order_application_expectation_shorthand.dart';

export 'work_order_application_run_rows_tail.dart';

void waaRunProspectAddsTilePlayerProspectedTilesWhenTerrainEligible() {
  waaExpectProspect(expected: true, terrain: TerrainType.hills);
}

void waaRunProspectOnNonMineralEligibleTerrainDoesNotAddTile() {
  waaExpectProspect(expected: false, terrain: TerrainType.plains);
}

void waaRunProspectAddsTileWhenMineralResourcePresentWithoutTileMap() {
  waaExpectProspect(
    expected: true,
    resourceByTileKey: {WorkAppIds.tileKey: 'iron'},
  );
}

void waaRunProspectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap() {
  waaExpectProspect(
    expected: false,
    resourceByTileKey: {WorkAppIds.tileKey: 'grain'},
  );
}

void
waaRunBuildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1() {
  final buildImpCost = workOrderCostBuildImprovement(0);
  final buildImpNext = waaApply(
    workAppOwnedGame(
      units: [workAppUnit(type: kUnitTypeBuilder)],
      resourceByTileKey: {WorkAppIds.tileKey: 'grain'},
      players: [
        workAppPlayer(
          stockpile: OrdersApplicationTestSupport.stockpileCovering(
            buildImpCost,
          ),
        ),
      ],
    ),
    workAppSingleWorkOrder(target: kWorkTargetBuildImprovement),
  );
  expect(
    buildImpNext.worldState.tileState.improvementLevel(WorkAppIds.tileKey),
    1,
  );
  waaExpectUnitIdle(buildImpNext);
}

void
waaRunBuildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel() {
  final fortNext = waaApply(
    waaEngineerFortGame(
      fortLevel: 1,
      techUnlocked: const {kTechIdMineEngineering: true},
    ),
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  waaExpectCurrentWorkTiming(
    fortNext,
    workTarget: kWorkTargetBuildFort,
    totalTurns: totalTurnsForWork(kWorkTargetBuildFort, fortLevel: 1),
    remainingTurns: 1,
    originTileKey: WorkAppIds.tileKey,
    assignedTileKey: WorkAppIds.tileKey,
  );
  expect(fortNext.worldState.oldWorld.provinces.single.fortLevel, 1);
}

void waaRunCounterSpyWorkOrderSetsCurrentWorkForSpyUnit() {
  final counterSpyNext = waaApply(
    workAppOwnedGame(
      units: [workAppUnit(id: 'spy1', type: kUnitTypeSpy)],
      provinces: [workAppOwnedProvince(ownerId: 'p2')],
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: true),
      ],
    ),
    workAppSingleWorkOrder(unitId: 'spy1', target: kWorkTargetCounterSpy),
  );
  waaExpectCurrentWorkTiming(
    counterSpyNext,
    unitId: 'spy1',
    workTarget: kWorkTargetCounterSpy,
    totalTurns: 0,
    remainingTurns: 1,
  );
}

void
waaRunPurchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey() {
  const cost = WorkAppIds.purchaseLandGrainCost;
  final game = workAppSingleGpPurchaseLandGame(
    overtureStates: const [
      OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
  final next = waaApply(game, workAppPurchaseLandOrders());
  waaExpectPurchased(next, ownerId: 'p1');
  expect(
    next.playerById('p1')!.treasury,
    game.playerById('p1')!.treasury - cost,
  );
  final purchasedUnit = waaSingleUnit(next);
  expect(purchasedUnit.tileKey, WorkAppIds.tileKeyMinor);
  expect(purchasedUnit.status, UnitStatus.idle);
  expect(purchasedUnit.currentWork, isNull);
  expect(purchasedUnit.originTileKey, isNull);
  expect(purchasedUnit.assignedTileKey, isNull);
}

void waaRunPurchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe() {
  waaExpectPurchaseRejected();
}

void waaRunPurchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe() {
  waaExpectPurchaseRejected(
    overtureStates: const [
      OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'p1',
        factionId2: 'minor1',
        state: RelationState.atWar,
      ),
    ],
  );
}

void waaRunPurchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite() {
  const dualCost = WorkAppIds.purchaseLandGrainCost;
  final dualGame = workAppPurchaseLandGame(
    units: [
      workAppPurchaseLandMerchant(),
      workAppPurchaseLandMerchant(id: 'merchant2', ownerId: 'p2'),
    ],
    players: [
      workAppPlayer(
        treasury: dualCost + 100,
        capitalProvinceId: WorkAppIds.provinceId,
      ),
      workAppPlayer(
        id: 'p2',
        displayName: 'P2',
        isHuman: false,
        treasury: dualCost + 100,
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
  final dualNext = waaApply(
    dualGame,
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
  waaExpectPurchased(dualNext, ownerId: 'p1');
  expect(
    dualNext.playerById('p1')!.treasury,
    dualGame.playerById('p1')!.treasury - dualCost,
  );
  expect(
    dualNext.playerById('p2')!.treasury,
    dualGame.playerById('p2')!.treasury,
  );
}

void waaRunBuildFortWithSufficientMaterialsDeductsMaterials() {
  final cost = workOrderCostBuildFort(0);
  final game = waaEngineerFortGame();
  final next = waaApply(
    game,
    workAppSingleWorkOrder(target: kWorkTargetBuildFort),
  );
  waaExpectStockpileDeducted(game, next, cost);
}

void waaRunBuildFortLevel2SkippedWithoutMineEngineering() {
  waaExpectFortSkipAtLevel(1);
}

void waaRunBuildFortLevel3SkippedWithoutModernForts() {
  waaExpectFortSkipAtLevel(2);
}

void waaRunUpgradeTownCompletionIncreasesProvinceTownDevelopmentLevel() {
  final upgradeNext = waaApply(
    workAppOwnedGame(
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
    ),
    workAppProcessWorkOrders(),
  );
  expect(
    upgradeNext.worldState.oldWorld.provinces.single.townDevelopmentLevel,
    2,
  );
}

void
waaRunCounterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork() {
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

void waaRunUnknownWorkTargetSkippedUnitStaysIdle() {
  final next = waaApply(
    workAppOwnedGame(units: [workAppUnit(type: kUnitTypeBuilder)]),
    workAppSingleWorkOrder(target: 'unknown_target'),
  );
  waaExpectUnitIdle(next);
}

void
waaRunBuildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile() {
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

void waaRunBuildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork() {
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

void
waaRunCounterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince() {
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
    workAppSingleWorkOrder(unitId: 'spy1', target: kWorkTargetCounterSpy),
  );
  final counterSpyU = waaSingleUnit(capitalSpyNext);
  expect(counterSpyU.currentWork, isNotNull);
  expect(counterSpyU.currentWork!.workTarget, kWorkTargetCounterSpy);
}
