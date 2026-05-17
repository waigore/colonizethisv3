import 'package:colonizethis_ai/src/util/orders_extensions.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('appendMoveOrders appends without mutating other players', () {
    const base = Orders(
      moveOrdersByPlayerId: {
        'p1': [MoveOrder(unitId: 'u1', destinationTileKey: 'r1|a')],
        'p2': [MoveOrder(unitId: 'u2', destinationTileKey: 'r1|b')],
      },
    );

    final updated = base.appendMoveOrders('p1', const [
      MoveOrder(unitId: 'u3', destinationTileKey: 'r1|c'),
    ]);

    expect(updated.moveOrdersByPlayerId['p1']?.length, 2);
    expect(updated.moveOrdersByPlayerId['p2'], base.moveOrdersByPlayerId['p2']);
    expect(base.moveOrdersByPlayerId['p1']?.length, 1);
  });
}
