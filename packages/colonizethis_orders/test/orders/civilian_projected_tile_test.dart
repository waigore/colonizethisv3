import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('projectedCivilianTileKey', () {
    const playerId = 'p1';

    test('prefers pending work-order target tile key', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
        assignedTileKey: 'oldWorld|p1|1|0',
      );
      const orders = Orders(
        workOrdersByPlayerId: {
          playerId: [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'oldWorld|p2|2|3',
            ),
          ],
        },
      );

      final projected = projectedCivilianTileKey(
        unit: unit,
        playerId: playerId,
        orders: orders,
      );
      expect(projected, 'oldWorld|p2|2|3');
    });

    test('keeps exact pending tile key for explore projection', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      const orders = Orders(
        workOrdersByPlayerId: {
          playerId: [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetExplore,
              targetTileKey: 'oldWorld|p9|7|8',
            ),
          ],
        },
      );

      final projected = projectedCivilianTileKey(
        unit: unit,
        playerId: playerId,
        orders: orders,
      );
      expect(projected, 'oldWorld|p9|7|8');
    });
  });
}
