import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/turn_event_sink.dart';
import 'package:colonizethis_turn/src/turn/turn_order_acceptance.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  group('filterOrderList', () {
    test('emits OrderRejectedEvent with orderKind when validation rejects', () {
      final events = <GameEvent>[];
      final sink = TurnEventSink(onGameEvent: events.add);
      final results = [OrderValidationResult.rejected('unit_not_found')];
      final idx = <int>[0];
      const orders = [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildRoad,
          targetTileKey: 'oldWorld|p1|0|0',
        ),
      ];

      filterOrderList<WorkOrder>(
        'gp1',
        orders,
        results,
        idx,
        (_, _) {},
        (w) => 'Work order: ${w.target}',
        OrderKind.work,
        sink,
      );

      final rejected = events.whereType<OrderRejectedEvent>().toList();
      expect(rejected, hasLength(1));
      expect(rejected.single.orderKind, OrderKind.work);
      expect(rejected.single.reasonCode, 'unit_not_found');
      expect(rejected.single.orderSummary, 'Work order: $kWorkTargetBuildRoad');
    });
  });
}
