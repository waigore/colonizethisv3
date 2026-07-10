// Compact applyBuildAndWorkOrders work-order application assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'orders_application_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'work_application_fixtures.dart';
import 'work_order_application_expectation_shorthand.dart';
import 'work_order_application_expectations_tail.dart';


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
    case WorkOrderApplicationTarget
        .buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel:
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
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnit:
      final counterSpyNext = waaApply(
          workAppOwnedGame(
            units: [workAppUnit(id: 'spy1', type: kUnitTypeSpy)],
            provinces: [workAppOwnedProvince(ownerId: 'p2')],
            players: const [
              Player(id: 'p1', displayName: 'P1', isHuman: true),
              Player(id: 'p2', displayName: 'P2', isHuman: true),
            ],
          ),
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
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe:
      waaExpectPurchaseRejected();
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe:
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
    case WorkOrderApplicationTarget
        .purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite:
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
    default:
      runWorkOrderApplicationExpectationTail(target);
  }
}
