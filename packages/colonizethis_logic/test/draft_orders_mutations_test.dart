import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('removePendingWorkOrderAt', () {
    test('removes order at index', () {
      const w0 = WorkOrder(
        unitId: 'u0',
        target: kWorkTargetExplore,
        targetTileKey: 'oldWorld|p1|0|0',
      );
      const w1 = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetExplore,
        targetTileKey: 'oldWorld|p2|0|0',
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'gp1': [w0, w1],
        },
      );
      final out = removePendingWorkOrderAt(orders, 'gp1', 0);
      expect(out.workOrdersByPlayerId['gp1'], [w1]);
    });

    test('returns orders unchanged when index invalid', () {
      const orders = Orders();
      expect(
        removePendingWorkOrderAt(orders, 'gp1', 0),
        same(orders),
      );
    });
  });
}
