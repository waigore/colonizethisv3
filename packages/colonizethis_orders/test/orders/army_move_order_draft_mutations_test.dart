// Ported from colonizethis_logic army_integration_test (Refs #4090 Slice D).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  group('applyArmyMoveOrderForPlayer', () {
    test('last order per armyId wins', () {
      const pid = 'gp1';
      const armyId = 'army_field';
      var orders = const Orders();
      orders = applyArmyMoveOrderForPlayer(
        orders,
        pid,
        const ArmyMoveOrder(
          armyId: armyId,
          destinationProvinceId: 'oldWorld|p1',
        ),
      );
      orders = applyArmyMoveOrderForPlayer(
        orders,
        pid,
        const ArmyMoveOrder(
          armyId: armyId,
          destinationProvinceId: 'oldWorld|p2',
        ),
      );
      final list = orders.armyMoveOrdersByPlayerId[pid]!;
      expect(list.length, 1);
      expect(list.single.destinationProvinceId, 'oldWorld|p2');
    });
  });
}
