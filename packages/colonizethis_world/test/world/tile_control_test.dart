import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/tile_control.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
void main() {
  group('isTileControlledByPlayer', () {
    const ownerId = 'p1';
    const tileKey = 'oldWorld|p1|0|0';

    test('true when the tile lies in a province owned by the player', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: ownerId, displayName: 'P', isHuman: true)],
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: ownerId),
          ],
        ),
      );
      expect(isTileControlledByPlayer(game, ownerId, tileKey), isTrue);
    });

    test('true when the tile was purchased by the player (Merchant)', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: ownerId, displayName: 'P', isHuman: true)],
        purchasedTilesByTileKey: const {tileKey: ownerId},
      );
      expect(isTileControlledByPlayer(game, ownerId, tileKey), isTrue);
    });

    test('false when a purchased tile belongs to another buyer', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: ownerId, displayName: 'P', isHuman: true)],
        purchasedTilesByTileKey: const {tileKey: 'p2'},
      );
      expect(isTileControlledByPlayer(game, ownerId, tileKey), isFalse);
    });

    test('false when the tile key has no parseable province id', () {
      final game = TestFixtures.minimalGame();
      expect(isTileControlledByPlayer(game, ownerId, 'bad-key'), isFalse);
    });

    test('false when the province does not exist', () {
      final game = TestFixtures.minimalGame();
      expect(isTileControlledByPlayer(game, ownerId, tileKey), isFalse);
    });

    test('false when the province is owned by a different player', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: ownerId, displayName: 'P', isHuman: true)],
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'p2'),
          ],
        ),
      );
      expect(isTileControlledByPlayer(game, ownerId, tileKey), isFalse);
    });
  });
}
