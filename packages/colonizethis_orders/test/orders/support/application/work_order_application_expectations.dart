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
        .counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork:
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
        final next = waaApply(
          game,
          workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
        );
        waaExpectUnitIdle(next);
        expect(
          next.players.single.stockpile.quantityOf(CommodityCatalog.lumber.id),
          0,
        );
    case WorkOrderApplicationTarget
        .buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork:
      final cost = workOrderCostBuildRoad;
        final game = waaEngineerRoadGame();
        final next = waaApply(
          game,
          workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
        );
        waaExpectUnitIdle(next);
        waaExpectRoadLevel(next, 1);
        waaExpectStockpileDeducted(game, next, cost);
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince:
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
    case WorkOrderApplicationTarget
        .exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles:
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
    case WorkOrderApplicationTarget
        .exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion:
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
    case WorkOrderApplicationTarget.engineerBuildRoadWorkOrderSetsCurrentWork:
      final next = waaApply(
        waaEngineerRoadGame(),
        workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
      );
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
