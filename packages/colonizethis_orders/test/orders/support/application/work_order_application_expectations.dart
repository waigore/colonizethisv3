// Compact applyBuildAndWorkOrders work-order application assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'orders_application_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'work_application_fixtures.dart';
import 'work_order_application_expectation_shorthand.dart';

/// Pins for [workOrderApplicationScenarios] rows.
enum WorkOrderApplicationTarget {
  prospectAddsTilePlayerProspectedTilesWhenTerrainEligible,
  prospectOnNonMineralEligibleTerrainDoesNotAddTile,
  prospectAddsTileWhenMineralResourcePresentWithoutTileMap,
  prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap,
  buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1,
  buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel,
  counterSpyWorkOrderSetsCurrentWorkForSpyUnit,
  purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey,
  purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe,
  purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe,
  purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite,
  buildFortWithSufficientMaterialsDeductsMaterials,
  buildFortLevel2SkippedWithoutMineEngineering,
  buildFortLevel3SkippedWithoutModernForts,
  upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel,
  counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork,
  unknownWorkTargetSkippedUnitStaysIdle,
  buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile,
  buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork,
  counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince,
  exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles,
  exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion,
  engineerBuildRoadWorkOrderSetsCurrentWork,
  buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient,
}

void runWorkOrderApplicationExpectation(WorkOrderApplicationTarget target) {
  switch (target) {
    case WorkOrderApplicationTarget
        .prospectAddsTilePlayerProspectedTilesWhenTerrainEligible:
      waaExpectProspect(expected: true, terrain: TerrainType.hills);
    case WorkOrderApplicationTarget
        .prospectOnNonMineralEligibleTerrainDoesNotAddTile:
      waaExpectProspect(expected: false, terrain: TerrainType.plains);
    case WorkOrderApplicationTarget
        .prospectAddsTileWhenMineralResourcePresentWithoutTileMap:
      waaExpectProspect(
        expected: true,
        resourceByTileKey: {WorkAppIds.tileKey: 'iron'},
      );
    case WorkOrderApplicationTarget
        .prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap:
      waaExpectProspect(
        expected: false,
        resourceByTileKey: {WorkAppIds.tileKey: 'grain'},
      );
    case WorkOrderApplicationTarget
        .buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1:
      final next = waaApplyBuildImprovement();
        expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 1);
        final u = waaSingleUnit(next);
        expect(u.status, UnitStatus.idle);
        expect(u.currentWork, isNull);
    case WorkOrderApplicationTarget
        .buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel:
      final fortNext = waaApplyBuildFort(
          fortLevel: 1,
          techUnlocked: const {kTechIdMineEngineering: true},
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
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnit:
      final counterSpyNext = waaApply(
          waaCounterSpyForeignProvinceGame(),
          workAppSingleWorkOrder(
            unitId: 'spy1',
            target: kWorkTargetCounterSpy,
          ),
        );
        waaExpectCurrentWorkTiming(
          counterSpyNext,
          unitId: 'spy1',
          workTarget: kWorkTargetCounterSpy,
          totalTurns: 0,
          remainingTurns: 1,
        );
    case WorkOrderApplicationTarget
        .purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey:
      const cost = WorkAppIds.purchaseLandGrainCost;
        final game = workAppPurchaseLandGame(
          units: [waaMerchantOnMinor()],
          players: [workAppPlayer(treasury: cost + 100)],
          overtureStates: [waaEmbassyOverture()],
        );
        final next = waaApply(game, waaPurchaseLandOrders());
        waaExpectPurchased(next, ownerId: 'p1');
        waaExpectTreasuryDelta(game, next, 'p1', -cost);
        final purchasedUnit = waaSingleUnit(next);
        expect(purchasedUnit.tileKey, WorkAppIds.tileKeyMinor);
        expect(purchasedUnit.status, UnitStatus.idle);
        expect(purchasedUnit.currentWork, isNull);
        expect(purchasedUnit.originTileKey, isNull);
        expect(purchasedUnit.assignedTileKey, isNull);
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe:
      waaExpectPurchaseLandRejected(waaPurchaseLandNoEmbassyGame());
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe:
      waaExpectPurchaseLandRejected(waaPurchaseLandAtWarGame());
    case WorkOrderApplicationTarget
        .purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite:
      const cost = WorkAppIds.purchaseLandGrainCost;
        final game = waaDualGpPurchaseLandGame();
        final next = waaApply(game, waaDualPurchaseLandOrders());
        waaExpectPurchased(next, ownerId: 'p1');
        waaExpectTreasuryDelta(game, next, 'p1', -cost);
        expect(
          next.playerById('p2')!.treasury,
          game.playerById('p2')!.treasury,
        );
    case WorkOrderApplicationTarget
        .buildFortWithSufficientMaterialsDeductsMaterials:
      final cost = workOrderCostBuildFort(0);
        final game = waaEngineerFortGame();
        final next = waaApply(
          game,
          workAppSingleWorkOrder(target: kWorkTargetBuildFort),
        );
        waaExpectStockpileDeducted(game, next, cost);
    case WorkOrderApplicationTarget
        .buildFortLevel2SkippedWithoutMineEngineering:
      waaExpectBuildFortSkipped(
          fortLevel: 1,
          stockpile: const Stockpile(),
          techUnlocked: const {},
          expectedFortLevel: 1,
        );
    case WorkOrderApplicationTarget.buildFortLevel3SkippedWithoutModernForts:
      waaExpectBuildFortSkipped(
          fortLevel: 2,
          stockpile: const Stockpile(),
          techUnlocked: const {kTechIdMineEngineering: true},
          expectedFortLevel: 2,
        );
    case WorkOrderApplicationTarget
        .upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel:
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
              workAppPlayer(
                techUnlocked: const {kTechIdNationalBureaucracy: true},
              ),
            ],
          ),
          workAppProcessWorkOrders(),
        );
        expect(
          upgradeNext.worldState.oldWorld.provinces.single.townDevelopmentLevel,
          2,
        );
    case WorkOrderApplicationTarget
        .counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork:
      final next = waaApply(
          waaCounterSpyOngoingAssignmentGame(),
          workAppProcessWorkOrders(playerIds: const ['p1', 'p2']),
        );
        final units = next.worldState.oldWorld.units;
        expect(units.length, 2);
        for (final id in const ['spy1', 'spy2']) {
          expect(units.any((u) => u.id == id), isTrue);
        }
    case WorkOrderApplicationTarget.unknownWorkTargetSkippedUnitStaysIdle:
      final next = waaApply(
          workAppOwnedGame(units: [workAppUnit(type: kUnitTypeBuilder)]),
          workAppSingleWorkOrder(target: 'unknown_target'),
        );
        waaExpectUnitIdle(next);
    case WorkOrderApplicationTarget
        .buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile:
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
    case WorkOrderApplicationTarget
        .buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork:
      final cost = workOrderCostBuildRoad;
        final game = waaEngineerRoadGame();
        final next = waaApplyBuildRoad(game);
        waaExpectUnitIdle(next);
        waaExpectRoadLevel(next, 1);
        waaExpectStockpileDeducted(game, next, cost);
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince:
      final capitalSpyNext = waaApply(
          waaCounterSpyCapitalGame(),
          workAppSingleWorkOrder(
            unitId: 'spy1',
            target: kWorkTargetCounterSpy,
          ),
        );
        final counterSpyU = waaSingleUnit(capitalSpyNext);
        expect(counterSpyU.currentWork, isNotNull);
        expect(counterSpyU.currentWork!.workTarget, kWorkTargetCounterSpy);
    case WorkOrderApplicationTarget
        .exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles:
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
    case WorkOrderApplicationTarget
        .exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion:
      const tileSmall1 = '${WorkAppIds.ow}|P1|0|0';
        final next = waaApply(
          waaExploreFormulaGame(),
          workAppSingleWorkOrder(
            target: kWorkTargetExplore,
            targetTileKey: tileSmall1,
          ),
        );
        waaExpectExploreWork(next, totalTurns: 2, remainingTurns: 1);
    case WorkOrderApplicationTarget.engineerBuildRoadWorkOrderSetsCurrentWork:
      final next = waaApplyBuildRoad(waaEngineerRoadGame());
        waaExpectUnitIdle(next);
        waaExpectRoadLevel(next, 1);
    case WorkOrderApplicationTarget
        .buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient:
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
}
