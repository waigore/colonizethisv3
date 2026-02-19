import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('mergeOrderLists', () {
    test('prefers human move orders over AI for same unit', () {
      final human = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationProvinceId: 'HUMAN_DEST'),
          ],
        },
      );
      final ai = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationProvinceId: 'AI_DEST'),
          ],
        },
      );

      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final moves = merged.moveOrdersByPlayerId['p1']!;
      expect(moves.length, 1);
      expect(moves.single.destinationProvinceId, 'HUMAN_DEST');
    });

    test('keeps AI move orders when human has none for unit', () {
      final human = const Orders(
        moveOrdersByPlayerId: {
          'p1': [],
        },
      );
      final ai = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(unitId: 'u2', destinationProvinceId: 'AI_DEST'),
          ],
        },
      );

      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final moves = merged.moveOrdersByPlayerId['p1']!;
      expect(moves.length, 1);
      expect(moves.single.unitId, 'u2');
    });

    test('merges diplomatic orders with human precedence per (type,target)', () {
      final human = Orders(
        diplomaticOrdersByPlayerId: {
          'p1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'p2',
            ),
          ],
        },
      );
      final ai = Orders(
        diplomaticOrdersByPlayerId: {
          'p1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'p2',
            ),
            DiplomaticOrder(
              type: DiplomaticOrderType.grantAid,
              targetFactionId: 'minor1',
              amount: 100,
            ),
          ],
        },
      );

      final merged = mergeOrderLists(humanOrders: human, aiOrders: ai);
      final orders = merged.diplomaticOrdersByPlayerId['p1']!;
      expect(
        orders.where((o) =>
            o.type == DiplomaticOrderType.declareWar && o.targetFactionId == 'p2'),
        hasLength(1),
      );
      expect(
        orders.where((o) =>
            o.type == DiplomaticOrderType.grantAid && o.targetFactionId == 'minor1'),
        hasLength(1),
      );
    });
  });
}

