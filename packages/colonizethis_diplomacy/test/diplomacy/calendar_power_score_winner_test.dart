import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_power_score.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('pickUniqueGreatPowerLeaderByPowerScore', () {
    Game _twoGpGame({
      required List<String> shipTypesGp1,
      required List<String> shipTypesGp2,
    }) {
      return Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              shipTypeIds: shipTypesGp1,
            ),
            Fleet(
              id: 'f2',
              ownerId: 'gp2',
              regionId: 'oldWorld',
              shipTypeIds: shipTypesGp2,
            ),
          ],
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: true),
          Player(id: 'gp2', displayName: 'B', isHuman: true),
        ],
      );
    }

    test('returns sole leader when scores differ', () {
      final game = _twoGpGame(
        shipTypesGp1: const ['carrack'],
        shipTypesGp2: const ['carrack', 'carrack', 'carrack'],
      );
      expect(pickUniqueGreatPowerLeaderByPowerScore(game), 'gp2');
    });

    test('returns null on tie', () {
      final game = _twoGpGame(
        shipTypesGp1: const ['carrack', 'carrack'],
        shipTypesGp2: const ['carrack', 'carrack'],
      );
      expect(pickUniqueGreatPowerLeaderByPowerScore(game), isNull);
    });
  });
}
