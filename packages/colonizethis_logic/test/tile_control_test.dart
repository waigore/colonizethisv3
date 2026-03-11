import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('isTileControlledByPlayer', () {
    const ow = 'oldWorld';
    const ownedProvinceId = '$ow|P1';
    const foreignProvinceId = '$ow|P2';
    const ownedTile = '$ownedProvinceId|0|0';
    const foreignTile = '$foreignProvinceId|0|0';

    Game _game({
      String? ownerP1 = 'p1',
      String? ownerP2 = 'p2',
      Map<String, String>? purchased,
    }) {
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState:
              const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: ownedProvinceId, regionId: ow, ownerId: ownerP1),
              Province(id: foreignProvinceId, regionId: ow, ownerId: ownerP2),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              ownedProvinceId: [ownedTile],
              foreignProvinceId: [foreignTile],
            },
          },
          purchasedTilesByTileKey: purchased ?? const {},
        ),
        players: const [],
      );
    }

    test('returns true for tile in province owned by player', () {
      final game = _game();
      expect(isTileControlledByPlayer(game, 'p1', ownedTile), isTrue);
    });

    test('returns false for foreign, unpurchased tile', () {
      final game = _game();
      expect(isTileControlledByPlayer(game, 'p1', foreignTile), isFalse);
    });

    test('returns true for tile purchased in foreign province', () {
      final game = _game(
        purchased: {foreignTile: 'p1'},
      );
      expect(isTileControlledByPlayer(game, 'p1', foreignTile), isTrue);
    });

    test('returns false when tileKey does not map to a province', () {
      final game = _game();
      expect(
        isTileControlledByPlayer(game, 'p1', 'oldWorld|UNKNOWN|0|0'),
        isFalse,
      );
    });
  });
}

