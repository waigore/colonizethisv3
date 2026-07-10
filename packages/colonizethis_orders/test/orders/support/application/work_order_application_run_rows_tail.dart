// Scenario run tear-offs for work order application family (Refs #3949 wave 3).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'orders_application_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'work_application_fixtures.dart';
import 'work_order_application_expectation_shorthand.dart';

void waaRunExploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles() {
  final next = waaApply(
    workAppOwnedGame(
      units: [workAppUnit(type: kUnitTypeExplorer)],
      tileKeysByRegionAndProvince: {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey, WorkAppIds.originTileKey],
        },
      },
    ),
    workAppSingleWorkOrder(target: kWorkTargetExplore),
  );
  final u = waaSingleUnit(next);
  expect(u.currentWork!.totalTurns, greaterThanOrEqualTo(1));
  waaExpectExploreWork(next, remainingTurns: u.currentWork!.totalTurns - 1);
}

void
waaRunExploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion() {
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
}

void waaRunEngineerBuildRoadWorkOrderSetsCurrentWork() {
  final next = waaApply(
    waaEngineerRoadGame(),
    workAppSingleWorkOrder(target: kWorkTargetBuildRoad),
  );
  waaExpectUnitIdle(next);
  waaExpectRoadLevel(next, 1);
}

void waaRunBuildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient() {
  final portCost = workOrderMaterialCost(kWorkTargetBuildPort);
  expect(portCost, isNotNull);
  final portNext = waaApply(
    workAppOwnedGame(
      units: [workAppUnit(type: kUnitTypeEngineer)],
      players: [
        workAppPlayer(
          stockpile: OrdersApplicationTestSupport.stockpileCovering(portCost!),
        ),
      ],
    ),
    workAppSingleWorkOrder(target: kWorkTargetBuildPort),
  );
  waaExpectUnitIdle(portNext);
}
