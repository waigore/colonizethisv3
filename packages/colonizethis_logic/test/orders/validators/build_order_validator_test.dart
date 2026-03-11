import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/orders/validators/build_order_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('BuildOrderValidator', () {
    test('validate returns rejected when previousRejected is true', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'P',
            isHuman: true,
            capitalProvinceId: 'oldWorld|p1',
          ),
        ],
      );
      final validator = BuildOrderValidator(game: game, player: game.players.first);
      final order = BuildUnitOrder(
        unitType: 'Builder',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = validator.validate(order, previousRejected: true);
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Previous invalid');
    });
  });
}
