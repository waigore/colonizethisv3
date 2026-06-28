import 'package:colonizethis_ai/src/util/orders_builder.dart';
import 'package:colonizethis_ai/src/util/orders_extensions.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  const move1 = MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p1|0|0');
  const move2 = MoveOrder(unitId: 'u2', destinationTileKey: 'oldWorld|p2|1|1');
  const build1 = BuildUnitOrder(
    unitType: 'peasant_levies',
    isMilitary: true,
    spawnProvinceId: 'oldWorld|p1',
  );
  const work1 = WorkOrder(
    unitId: 'u3',
    target: kWorkTargetBuildImprovement,
    targetTileKey: 'oldWorld|p1|2|2',
  );
  const recruit1 = RecruitWorkerOrder(targetTier: WorkerTier.peasant);

  group('OrdersBuilder (Refs #3288)', () {
    test('empty builder builds an Orders equal to the empty default', () {
      expect(OrdersBuilder.from(const Orders()).build(), const Orders());
    });

    test('single-family append equals the immutable extension append', () {
      final viaBuilder = OrdersBuilder.from(const Orders())
        ..appendMoveOrders('gp1', [move1]);
      final viaExtension = const Orders().appendMoveOrders('gp1', [move1]);
      expect(viaBuilder.build(), viaExtension);
    });

    test('multi-family append sequence equals chained extension appends', () {
      final builder = OrdersBuilder.from(const Orders())
        ..appendWorkOrders('gp1', [work1])
        ..appendRecruitWorkerOrders('gp1', [recruit1])
        ..appendBuildOrders('gp1', [build1]);

      final chained = const Orders()
          .appendWorkOrders('gp1', [work1])
          .appendRecruitWorkerOrders('gp1', [recruit1])
          .appendBuildOrders('gp1', [build1]);

      expect(builder.build(), chained);
    });

    test('repeated appends to the same family preserve order', () {
      final builder = OrdersBuilder.from(const Orders())
        ..appendMoveOrders('gp1', [move1])
        ..appendMoveOrders('gp1', [move2]);
      final chained = const Orders()
          .appendMoveOrders('gp1', [move1])
          .appendMoveOrders('gp1', [move2]);

      expect(builder.build(), chained);
      expect(builder.build().moveOrdersByPlayerId['gp1'], [move1, move2]);
    });

    test('empty append lists are ignored (no family key created)', () {
      final builder = OrdersBuilder.from(const Orders())
        ..appendMoveOrders('gp1', const [])
        ..appendBuildOrders('gp1', const []);
      expect(builder.build(), const Orders());
      expect(builder.build().moveOrdersByPlayerId, isEmpty);
    });

    test('build is cached until the next append then reflects new state', () {
      final builder = OrdersBuilder.from(const Orders())
        ..appendMoveOrders('gp1', [move1]);
      final first = builder.build();
      expect(identical(builder.build(), first), isTrue);

      builder.appendMoveOrders('gp1', [move2]);
      final second = builder.build();
      expect(identical(second, first), isFalse);
      expect(second.moveOrdersByPlayerId['gp1'], [move1, move2]);
      // A previously built snapshot is not mutated by later appends.
      expect(first.moveOrdersByPlayerId['gp1'], [move1]);
    });

    test('from does not mutate the source Orders on later appends', () {
      final source = const Orders().appendMoveOrders('gp1', [move1]);
      final builder = OrdersBuilder.from(source)
        ..appendMoveOrders('gp1', [move2]);
      expect(builder.build().moveOrdersByPlayerId['gp1'], [move1, move2]);
      // Source is untouched.
      expect(source.moveOrdersByPlayerId['gp1'], [move1]);
    });
  });
}
