import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('restoreGpOwTerrainCountsAfterSettlementPlains', () {
    test('relocates destroyed hills onto non-settlement plains', () {
      // (0,0) settlement plains (was hills); (1,0) non-settlement plains donor.
      final map = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['p1', 'p1'],
        ],
        terrainGrid: [
          [TerrainType.plains, TerrainType.plains],
        ],
        resourceGrid: [
          [null, null],
        ],
      );
      final game = TestFixtures.minimalGame(
        id: 'g',
        turnNumber: 0,
        players: const [
          Player(id: 'gp1', displayName: 'G', isHuman: true),
        ],
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
              townTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        ),
      ).copyWith(
        players: [
          const Player(id: 'gp1', displayName: 'G', isHuman: true).copyWith(
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      final targets = <TerrainType, int>{
        for (final t in TerrainType.values) t: 0,
      };
      targets[TerrainType.hills] = 1;
      targets[TerrainType.plains] = 1;
      final out = restoreGpOwTerrainCountsAfterSettlementPlains(
        game: game,
        tileMapOldWorld: map,
        targetCounts: targets,
      );
      expect(out.terrainAt(0, 0), TerrainType.plains);
      expect(out.terrainAt(1, 0), TerrainType.hills);
      final counts = countGpOwTerrainByType(game: game, tileMapOldWorld: out);
      expect(counts[TerrainType.hills], 1);
      expect(counts[TerrainType.plains], 1);
    });

    test('negative: does not mutate settlement plains when no deficit', () {
      final map = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['p1', 'p1'],
        ],
        terrainGrid: [
          [TerrainType.plains, TerrainType.hills],
        ],
        resourceGrid: [
          [null, null],
        ],
      );
      final game = TestFixtures.minimalGame(
        id: 'g',
        turnNumber: 0,
        players: const [
          Player(id: 'gp1', displayName: 'G', isHuman: true),
        ],
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
              townTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        ),
      ).copyWith(
        players: [
          const Player(id: 'gp1', displayName: 'G', isHuman: true).copyWith(
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: const CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      final targets = countGpOwTerrainByType(game: game, tileMapOldWorld: map);
      final out = restoreGpOwTerrainCountsAfterSettlementPlains(
        game: game,
        tileMapOldWorld: map,
        targetCounts: targets,
      );
      expect(out.terrainAt(0, 0), TerrainType.plains);
      expect(out.terrainAt(1, 0), TerrainType.hills);
    });
  });
}
