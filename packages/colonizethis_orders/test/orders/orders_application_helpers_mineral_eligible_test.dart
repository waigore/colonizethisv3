import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/orders_application_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _gameWithResourceByTile(Map<String, String> resourceByTileKey) {
  return Game(
    id: 'g-test',
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
    ],
    minorNations: const [],
    tribes: const [],
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey,
    ),
  );
}

void main() {
  group('isMineralEligibleTile with tile map terrain data', () {
    test('returns true for prospectable terrain even when no resource is present', () {
      final game = _gameWithResourceByTile(const {});
      const tileKey = 'oldWorld|p1|0|0';
      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 1,
          grid: const [
            ['p1'],
          ],
          terrainGrid: const [
            [TerrainType.mountain],
          ],
          resourceGrid: const [
            [null],
          ],
        ),
      };

      final result = isMineralEligibleTile(game, tileMapByRegion, tileKey);
      expect(result, isTrue);
    });

    test('returns false for non-prospectable terrain even when mineral resource exists', () {
      final game = _gameWithResourceByTile(const {'oldWorld|p1|0|0': 'gold'});
      const tileKey = 'oldWorld|p1|0|0';
      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 1,
          grid: const [
            ['p1'],
          ],
          terrainGrid: const [
            [TerrainType.plains],
          ],
          resourceGrid: const [
            [Resource.gold],
          ],
        ),
      };

      final result = isMineralEligibleTile(game, tileMapByRegion, tileKey);
      expect(result, isFalse);
    });

    test('returns false for wool on hills when tile map shows prospectable terrain', () {
      final game = _gameWithResourceByTile(const {'oldWorld|p1|0|0': 'wool'});
      const tileKey = 'oldWorld|p1|0|0';
      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 1,
          grid: const [
            ['p1'],
          ],
          terrainGrid: const [
            [TerrainType.hills],
          ],
          resourceGrid: const [
            [Resource.wool],
          ],
        ),
      };

      final result = isMineralEligibleTile(game, tileMapByRegion, tileKey);
      expect(result, isFalse);
    });

    test('returns true for iron on hills with tile map when not prospected', () {
      final game = _gameWithResourceByTile(const {'oldWorld|p1|0|0': 'iron'});
      const tileKey = 'oldWorld|p1|0|0';
      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 1,
          grid: const [
            ['p1'],
          ],
          terrainGrid: const [
            [TerrainType.hills],
          ],
          resourceGrid: const [
            [Resource.iron],
          ],
        ),
      };

      final result = isMineralEligibleTile(game, tileMapByRegion, tileKey);
      expect(result, isTrue);
    });
  });

  group('isMineralEligibleTile fallback with resource presence/absence', () {
    test('returns false when resource is absent', () {
      final game = _gameWithResourceByTile(const {});
      const tileKey = 'oldWorld|p1|0|0';

      final result = isMineralEligibleTile(game, null, tileKey);
      expect(result, isFalse);
    });

    test('returns false for non-mineral resource', () {
      final game = _gameWithResourceByTile(const {'oldWorld|p1|0|0': 'grain'});
      const tileKey = 'oldWorld|p1|0|0';

      final result = isMineralEligibleTile(game, null, tileKey);
      expect(result, isFalse);
    });

    test('returns true for mineral resource', () {
      final game = _gameWithResourceByTile(const {'oldWorld|p1|0|0': 'coal'});
      const tileKey = 'oldWorld|p1|0|0';

      final result = isMineralEligibleTile(game, null, tileKey);
      expect(result, isTrue);
    });
  });
}
