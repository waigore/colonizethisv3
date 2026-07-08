import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/application/orders_application_test_support.dart';

void main() {
  group('applyBuildAndWorkOrders work order application', () {
    const ow = OrdersApplicationTestSupport.ow;
    const provinceId = OrdersApplicationTestSupport.provinceId;
    const tileKey = OrdersApplicationTestSupport.tileKey;

    test('build_fort with sufficient materials deducts materials', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final cost = workOrderCostBuildFort(0);
      final game = OrdersApplicationTestSupport.workOrderApplicationGame(
        provinces: [
          Province(
            id: provinceId,
            regionId: ow,
            ownerId: 'p1',
            fortLevel: 0,
          ),
        ],
        units: [unit],
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
          ),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetBuildFort,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      for (final e in cost.entries) {
        expect(
          next.players.single.stockpile.quantityOf(e.key),
          game.players.single.stockpile.quantityOf(e.key) - e.value,
        );
      }
    });

    test('build_fort to level 2 is skipped without Mine Engineering', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = OrdersApplicationTestSupport.workOrderApplicationGame(
        provinces: [
          Province(
            id: provinceId,
            regionId: ow,
            ownerId: 'p1',
            fortLevel: 1,
          ),
        ],
        units: [unit],
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            techUnlocked: {},
          ),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetBuildFort,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
      expect(next.worldState.oldWorld.units.single.currentWork, isNull);
    });

    test('build_fort to level 3 is skipped without Modern Forts', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = OrdersApplicationTestSupport.workOrderApplicationGame(
        provinces: [
          Province(
            id: provinceId,
            regionId: ow,
            ownerId: 'p1',
            fortLevel: 2,
          ),
        ],
        units: [unit],
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            techUnlocked: {kTechIdMineEngineering: true},
          ),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetBuildFort,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.provinces.single.fortLevel, 2);
      expect(next.worldState.oldWorld.units.single.currentWork, isNull);
    });

    test('upgrade_town completion increases province townDevelopmentLevel', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetUpgradeTown,
          tileKey: tileKey,
          totalTurns: 1,
          remainingTurns: 1,
        ),
      );
      final game = OrdersApplicationTestSupport.workOrderApplicationGame(
        provinces: [
          Province(
            id: provinceId,
            regionId: ow,
            ownerId: 'p1',
            townDevelopmentLevel: 1,
          ),
        ],
        units: [unit],
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            techUnlocked: const {kTechIdNationalBureaucracy: true},
          ),
        ],
      );
      final next = applyBuildAndWorkOrders(
        game,
        Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]}),
      );
      expect(next.worldState.oldWorld.provinces.single.townDevelopmentLevel, 2);
    });

    test(
      'counter_spy processWork keeps ongoing assignment without killing in build/work',
      () {
        const provId = OrdersApplicationTestSupport.provinceId;
        const tileKeyP1 = OrdersApplicationTestSupport.tileKey;
        final p1Spy = Unit(
          id: 'spy1',
          type: kUnitTypeSpy,
          ownerId: 'p1',
          locationProvinceId: provId,
          tileKey: tileKeyP1,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetCounterSpy,
            tileKey: tileKeyP1,
            totalTurns: 0,
            remainingTurns: 1,
          ),
        );
        final p2Spy = Unit(
          id: 'spy2',
          type: kUnitTypeSpy,
          ownerId: 'p2',
          locationProvinceId: provId,
          tileKey: tileKeyP1,
        );
        final game = OrdersApplicationTestSupport.workOrderApplicationGame(
          turnNumber: 1,
          globalGameSeed: 12345,
          provinces: [Province(id: provId, regionId: ow, ownerId: 'p1')],
          units: [p1Spy, p2Spy],
          tileKeysByRegionAndProvince: {
            ow: {
              provId: [tileKeyP1],
            },
          },
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: true),
          ],
        );
        final next = applyBuildAndWorkOrders(
          game,
          Orders(
            buildUnitOrdersByPlayerId: {
              'p1': <BuildUnitOrder>[],
              'p2': <BuildUnitOrder>[],
            },
          ),
        );
        final units = next.worldState.oldWorld.units;
        expect(units.any((u) => u.id == 'spy1'), isTrue);
        expect(units.any((u) => u.id == 'spy2'), isTrue);
        expect(units.length, 2);
      },
    );
  });
}
