// Tail expectation dispatch cases (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'orders_application_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'work_application_fixtures.dart';
import 'work_order_application_expectation_shorthand.dart';
import 'work_order_application_expectations.dart' show WorkOrderApplicationTarget;

void runWorkOrderApplicationExpectationTail(WorkOrderApplicationTarget target) {
  switch (target) {
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
      waaExpectFortSkipAtLevel(1);
    case WorkOrderApplicationTarget.buildFortLevel3SkippedWithoutModernForts:
      waaExpectFortSkipAtLevel(2);
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
      const exploreProvinceSmall = '${WorkAppIds.ow}|P1';
      const exploreProvinceLarge = '${WorkAppIds.ow}|P2';
      const tileSmall1 = '${WorkAppIds.ow}|P1|0|0';
      const tileSmall2 = '${WorkAppIds.ow}|P1|1|0';
      const tileLarge1 = '${WorkAppIds.ow}|P2|0|0';
      const tileLarge2 = '${WorkAppIds.ow}|P2|1|0';
      const tileLarge3 = '${WorkAppIds.ow}|P2|2|0';
      const tileLarge4 = '${WorkAppIds.ow}|P2|3|0';
      final exploreFormulaNext = waaApply(
        workAppOwnedGame(
          units: [
            workAppUnit(
              type: kUnitTypeExplorer,
              locationProvinceId: exploreProvinceSmall,
              tileKey: tileSmall1,
            ),
          ],
          provinces: const [
            Province(
              id: exploreProvinceSmall,
              regionId: WorkAppIds.ow,
              ownerId: 'p1',
            ),
            Province(
              id: exploreProvinceLarge,
              regionId: WorkAppIds.ow,
              ownerId: 'p1',
            ),
          ],
          tileKeysByRegionAndProvince: const {
            WorkAppIds.ow: {
              exploreProvinceSmall: [tileSmall1, tileSmall2],
              exploreProvinceLarge: [
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
      waaExpectExploreWork(exploreFormulaNext, totalTurns: 2, remainingTurns: 1);
    case WorkOrderApplicationTarget.engineerBuildRoadWorkOrderSetsCurrentWork:
      final next = waaApply(
        waaEngineerRoadGame(),
        workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
      );
      waaExpectUnitIdle(next);
      waaExpectRoadLevel(next, 1);
    case WorkOrderApplicationTarget
        .buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient:
      final portCost = workOrderMaterialCost(kWorkTargetBuildPort);
      expect(portCost, isNotNull);
      final portNext = waaApply(
        workAppOwnedGame(
          units: [workAppUnit(type: kUnitTypeEngineer)],
          players: [
            workAppPlayer(
              stockpile: OrdersApplicationTestSupport.stockpileCovering(
                portCost!,
              ),
            ),
          ],
        ),
        workAppSingleWorkOrder(target: kWorkTargetBuildPort),
      );
      waaExpectUnitIdle(portNext);
    default:
      throw StateError('Unexpected WorkOrderApplicationTarget for tail dispatch: $target');
  }
}
