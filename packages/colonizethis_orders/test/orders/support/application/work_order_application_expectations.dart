// Compact applyBuildAndWorkOrders work-order application assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'orders_application_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'work_application_fixtures.dart';
import 'work_order_application_expectation_shorthand.dart';

part 'work_order_application_expectations_late.dart';

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
      final cost = workOrderCostBuildImprovement(0);
        final next = waaApply(
          workAppOwnedGame(
            units: [workAppUnit(type: kUnitTypeBuilder)],
            resourceByTileKey: {WorkAppIds.tileKey: 'grain'},
            players: [
              workAppPlayer(
                stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
              ),
            ],
          ),
          workAppSingleWorkOrder(target: kWorkTargetBuildImprovement),
        );
        expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 1);
        final u = waaSingleUnit(next);
        expect(u.status, UnitStatus.idle);
        expect(u.currentWork, isNull);
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
        final game = workAppPurchaseLandGame(
          units: [
            workAppUnit(
              id: 'merchant1',
              type: kUnitTypeMerchant,
              ownerId: 'p1',
              locationProvinceId: WorkAppIds.minorProvinceId,
              tileKey: WorkAppIds.tileKeyMinor,
            ),
          ],
          players: [workAppPlayer(treasury: cost + 100)],
          overtureStates: const [
            OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final next = waaApply(game, waaPurchaseLandOrders());
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
      {
        const cost = WorkAppIds.purchaseLandGrainCost;
        final game = workAppPurchaseLandGame(
          units: [
            workAppUnit(
              id: 'merchant1',
              type: kUnitTypeMerchant,
              ownerId: 'p1',
              locationProvinceId: WorkAppIds.minorProvinceId,
              tileKey: WorkAppIds.tileKeyMinor,
            ),
          ],
          players: [workAppPlayer(treasury: cost + 100)],
        );
        final next = waaApply(game, waaPurchaseLandOrders());
        waaExpectPurchased(next, ownerId: null);
        expect(
          next.playerById('p1')!.treasury,
          game.playerById('p1')!.treasury,
        );
      }
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe:
      {
        const cost = WorkAppIds.purchaseLandGrainCost;
        final game = workAppPurchaseLandGame(
          units: [
            workAppUnit(
              id: 'merchant1',
              type: kUnitTypeMerchant,
              ownerId: 'p1',
              locationProvinceId: WorkAppIds.minorProvinceId,
              tileKey: WorkAppIds.tileKeyMinor,
            ),
          ],
          players: [workAppPlayer(treasury: cost + 100)],
          overtureStates: [
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
        final next = waaApply(game, waaPurchaseLandOrders());
        waaExpectPurchased(next, ownerId: null);
        expect(
          next.playerById('p1')!.treasury,
          game.playerById('p1')!.treasury,
        );
      }
    case WorkOrderApplicationTarget
        .purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite:
      const cost = WorkAppIds.purchaseLandGrainCost;
        final game = workAppPurchaseLandGame(
          units: [
            workAppUnit(
              id: 'merchant1',
              type: kUnitTypeMerchant,
              ownerId: 'p1',
              locationProvinceId: WorkAppIds.minorProvinceId,
              tileKey: WorkAppIds.tileKeyMinor,
            ),
            workAppUnit(
              id: 'merchant2',
              type: kUnitTypeMerchant,
              ownerId: 'p2',
              locationProvinceId: WorkAppIds.minorProvinceId,
              tileKey: WorkAppIds.tileKeyMinor,
            ),
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
        final next = waaApply(
          game,
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
        waaExpectPurchased(next, ownerId: 'p1');
        expect(
          next.playerById('p1')!.treasury,
          game.playerById('p1')!.treasury - cost,
        );
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
      {
        final next = waaApply(
          waaEngineerFortGame(
            fortLevel: 1,
            stockpile: const Stockpile(),
            techUnlocked: const {},
          ),
          workAppSingleWorkOrder(target: kWorkTargetBuildFort),
        );
        expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
        expect(waaSingleUnit(next).currentWork, isNull);
      }
    case WorkOrderApplicationTarget.buildFortLevel3SkippedWithoutModernForts:
      {
        final next = waaApply(
          waaEngineerFortGame(
            fortLevel: 2,
            stockpile: const Stockpile(),
            techUnlocked: const {kTechIdMineEngineering: true},
          ),
          workAppSingleWorkOrder(target: kWorkTargetBuildFort),
        );
        expect(next.worldState.oldWorld.provinces.single.fortLevel, 2);
        expect(waaSingleUnit(next).currentWork, isNull);
      }
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
    case WorkOrderApplicationTarget.unknownWorkTargetSkippedUnitStaysIdle:
      final next = waaApply(
          workAppOwnedGame(units: [workAppUnit(type: kUnitTypeBuilder)]),
          workAppSingleWorkOrder(target: 'unknown_target'),
        );
        waaExpectUnitIdle(next);:
      woaLateUnknownWorkTargetSkippedUnitStaysIdle();
    case WorkOrderApplicationTarget
        .buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork:
      woaLateBuildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork();
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince:
      woaLateCounterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince();
    case WorkOrderApplicationTarget
        .exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles:
      woaLateExploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles();
    case WorkOrderApplicationTarget
        .exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion:
      woaLateExploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion();
    case WorkOrderApplicationTarget.engineerBuildRoadWorkOrderSetsCurrentWork:
      final next = waaApply(
        waaEngineerRoadGame(),
        workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
      );
        waaExpectUnitIdle(next);
        waaExpectRoadLevel(next, 1);:
      woaLateEngineerBuildRoadWorkOrderSetsCurrentWork();
}
}
