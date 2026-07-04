import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'orders_application_test_support.dart';

void main() {
  group('applyBuildAndWorkOrders work order application (part 4)', () {
    const ow = OrdersApplicationTestSupport.ow;
    const provinceId = OrdersApplicationTestSupport.provinceId;
    const tileKey = OrdersApplicationTestSupport.tileKey;

    test('unknown work target is skipped and unit stays idle', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = OrdersApplicationTestSupport.workOrderApplicationGame(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: 'unknown_target',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final u = next.worldState.oldWorld.units.single;
      expect(u.status, UnitStatus.idle);
      expect(u.currentWork, isNull);
    });

    test(
      'build_road with insufficient materials does not set currentWork or deduct stockpile',
      () {
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeEngineer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final game = OrdersApplicationTestSupport.workOrderApplicationGame(
          provinces: [
            Province(id: provinceId, regionId: ow, ownerId: 'p1'),
          ],
          units: [unit],
          players: const [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              stockpile: Stockpile(),
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetBuildRoad,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;
        expect(u.currentWork, isNull);
        expect(u.status, UnitStatus.idle);
        expect(
          next.players.single.stockpile.quantityOf(CommodityCatalog.lumber.id),
          0,
        );
      },
    );

    test(
      'build_road with sufficient materials deducts materials and sets currentWork',
      () {
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeEngineer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final cost = workOrderCostBuildRoad;
        final game = OrdersApplicationTestSupport.workOrderApplicationGame(
          provinces: [
            Province(id: provinceId, regionId: ow, ownerId: 'p1'),
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
                target: kWorkTargetBuildRoad,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;
        // build_road totalTurns=1, so work completes in same phase; unit idle and road level 1.
        expect(u.currentWork, isNull);
        expect(u.status, UnitStatus.idle);
        expect(next.worldState.tileState.roadLevel(tileKey), 1);
        for (final e in cost.entries) {
          expect(
            next.players.single.stockpile.quantityOf(e.key),
            game.players.single.stockpile.quantityOf(e.key) - e.value,
          );
        }
      },
    );
  });
}
