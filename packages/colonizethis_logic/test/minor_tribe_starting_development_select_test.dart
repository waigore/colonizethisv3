// SPEC/game/factions.md § Starting developed resources (Minor Nations and Tribes).
// Tests for selectMinorTribeStartingDevelopmentTileKeys (per-province ranker).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('selectMinorTribeStartingDevelopmentTileKeys', () {
    test('orders by Manhattan distance then y asc then x asc', () {
      // 4x3 grid all in province p1; resource on every non-capital land tile.
      final tileMap = TileMapResult(
        width: 4,
        height: 3,
        grid: const [
          ['p1', 'p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1', 'p1'],
        ],
        terrainGrid: List.generate(
          3,
          (_) => List<TerrainType?>.filled(4, TerrainType.plains),
        ),
        resourceGrid: List.generate(
          3,
          (_) => List<Resource?>.filled(4, Resource.grain),
        ),
      );
      final capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 2,
        y: 1,
      );
      final capitalKey = CapitalTile.tileKey(
        capital.regionId,
        capital.provinceId,
        capital.x,
        capital.y,
      );
      final picks = selectMinorTribeStartingDevelopmentTileKeys(
        map: tileMap,
        capital: capital,
        tileState: TileMapState(),
        forbiddenTileKeys: {capitalKey},
        maxTiles: 4,
      );
      // Distance-1 tiles around (2,1) sorted by y asc then x asc:
      //   (2,0) d=1, (1,1) d=1, (3,1) d=1, (2,2) d=1.
      expect(picks, [
        'oldWorld|p1|2|0',
        'oldWorld|p1|1|1',
        'oldWorld|p1|3|1',
        'oldWorld|p1|2|2',
      ]);
    });

    test('excludes capital and town tiles, tiles without resource or terrain, '
        'and already-developed tiles', () {
      final tileMap = TileMapResult(
        width: 3,
        height: 2,
        grid: const [
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
        ],
        terrainGrid: const [
          [
            TerrainType.plains,
            null, // tile (1,0) has no terrain
            TerrainType.plains,
          ],
          [
            TerrainType.plains,
            TerrainType.plains,
            TerrainType.plains,
          ],
        ],
        resourceGrid: const [
          [
            Resource.grain, // capital — excluded by forbidden
            null, // no terrain anyway
            Resource.timber, // town — excluded by forbidden
          ],
          [
            Resource.grain, // already developed
            null, // no resource on this tile
            Resource.iron, // eligible
          ],
        ],
      );
      final capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      final capitalKey = CapitalTile.tileKey(
        capital.regionId,
        capital.provinceId,
        capital.x,
        capital.y,
      );
      final townKey = CapitalTile.tileKey(
        capital.regionId,
        capital.provinceId,
        2,
        0,
      );
      final tileState = TileMapState().setImprovement('oldWorld|p1|0|1', 1);
      final picks = selectMinorTribeStartingDevelopmentTileKeys(
        map: tileMap,
        capital: capital,
        tileState: tileState,
        forbiddenTileKeys: {capitalKey, townKey},
        maxTiles: 4,
      );
      expect(picks, ['oldWorld|p1|2|1']);
    });

    test('returns empty list when terrain or resource grid is missing', () {
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: const [
          ['p1', 'p1'],
          ['p1', 'p1'],
        ],
      );
      final capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      expect(
        selectMinorTribeStartingDevelopmentTileKeys(
          map: tileMap,
          capital: capital,
          tileState: TileMapState(),
          forbiddenTileKeys: const {},
          maxTiles: 2,
        ),
        isEmpty,
      );
    });

    test('skips tiles outside the capital province', () {
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: const [
          ['p1', 'p2'],
          ['p2', 'p1'],
        ],
        terrainGrid: List.generate(
          2,
          (_) => List<TerrainType?>.filled(2, TerrainType.plains),
        ),
        resourceGrid: List.generate(
          2,
          (_) => List<Resource?>.filled(2, Resource.timber),
        ),
      );
      final capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      final capitalKey = CapitalTile.tileKey(
        capital.regionId,
        capital.provinceId,
        0,
        0,
      );
      final picks = selectMinorTribeStartingDevelopmentTileKeys(
        map: tileMap,
        capital: capital,
        tileState: TileMapState(),
        forbiddenTileKeys: {capitalKey},
        maxTiles: 4,
      );
      // Only (1,1) belongs to p1 and is eligible — (1,0) and (0,1) belong to p2.
      expect(picks, ['oldWorld|p1|1|1']);
    });

    test('returns empty list when maxTiles is zero', () {
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['oldWorld|p1'],
        ],
        terrainGrid: const [
          [TerrainType.plains],
        ],
        resourceGrid: const [
          [Resource.grain],
        ],
      );
      final capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      expect(
        selectMinorTribeStartingDevelopmentTileKeys(
          map: tileMap,
          capital: capital,
          tileState: TileMapState(),
          forbiddenTileKeys: const {},
          maxTiles: 0,
        ),
        isEmpty,
      );
    });
  });
}
