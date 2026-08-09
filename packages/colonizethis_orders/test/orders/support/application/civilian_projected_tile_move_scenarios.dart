import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_test/test.dart';

const _playerId = 'p1';

void cptmRunPrefersPendingMoveDestination() {
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeSpy,
    ownerId: _playerId,
    locationProvinceId: 'oldWorld|p1',
    tileKey: 'oldWorld|p1|0|0',
  );
  const orders = Orders(
    moveOrdersByPlayerId: {
      _playerId: [
        MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|3|4'),
      ],
    },
  );
  final projected = projectedCivilianTileKey(
    unit: unit,
    playerId: _playerId,
    orders: orders,
  );
  expect(projected, 'oldWorld|p2|3|4');
}
