import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/src/gen/tile_map_grid_graph.dart';

import 'support/tile_map_gen_fixtures.dart';

void main() {
  group('TileMapGridGraph', () {
    test('connectedComponentsOfLand splits two 4-connected blobs', () {
      final params = genParams(width: 4, height: 2);
      final g = TileMapGridGraph(params);
      final a = <(int, int)>{(0, 0), (1, 0)};
      final b = <(int, int)>{(3, 0), (3, 1)};
      final comps = g.connectedComponentsOfLand({...a, ...b});
      expect(comps.length, 2);
      expect(comps.any((c) => c.containsAll(a)), isTrue);
      expect(comps.any((c) => c.containsAll(b)), isTrue);
    });

    test(
      'oceanCells: all-sea grid is ocean only (no fillable single-continent S)',
      () {
        const sea = 's1';
        final params = genParams(width: 3, height: 3);
        final g = TileMapGridGraph(params);
        final grid = List.generate(3, (_) => List.filled(3, sea));
        final ocean = g.oceanCells(grid, sea, [], []);
        expect(ocean.length, 9);
      },
    );

    test('oceanCells: map-border bay sea is not ocean when |S| = 1', () {
      const sea = 's1';
      const land = 'p1';
      final params = genParams(width: 5, height: 3);
      final g = TileMapGridGraph(params);
      final grid = <List<String>>[
        [land, sea, sea, sea, land],
        [land, sea, sea, sea, land],
        [land, land, land, land, land],
      ];
      final landSeeds = <(int, int)>[(2, 2)];
      final continentBySeed = <int>[0];
      final ocean = g.oceanCells(grid, sea, landSeeds, continentBySeed);
      expect(ocean, isEmpty);
    });

    test('oceanCells: border strait sea remains ocean when |S| >= 2', () {
      const sea = 's1';
      final params = genParams(width: 4, height: 3);
      final g = TileMapGridGraph(params);
      final grid = <List<String>>[
        ['p1', sea, sea, 'p2'],
        ['p1', sea, sea, 'p2'],
        ['p1', 'p1', 'p2', 'p2'],
      ];
      final landSeeds = <(int, int)>[(0, 2), (3, 2)];
      final continentBySeed = <int>[0, 1];
      final ocean = g.oceanCells(grid, sea, landSeeds, continentBySeed);
      final seaCells = <(int, int)>{(1, 0), (2, 0), (1, 1), (2, 1)};
      expect(ocean.containsAll(seaCells), isTrue);
    });

    test('nearestLandSeedIndexForCell picks closest seed by squared distance', () {
      final params = genParams(width: 10, height: 10);
      final g = TileMapGridGraph(params);
      final seeds = <(int, int)>[(0, 0), (9, 9), (5, 5)];
      expect(g.nearestLandSeedIndexForCell(1, 1, seeds), 0);
      expect(g.nearestLandSeedIndexForCell(8, 8, seeds), 1);
      expect(g.nearestLandSeedIndexForCell(4, 4, seeds), 2);
    });

    test('nearestLandSeedIndexForCell returns 0 when seeds empty', () {
      final g = TileMapGridGraph(genParams(width: 3, height: 3));
      expect(g.nearestLandSeedIndexForCell(1, 1, []), 0);
    });

    test('continentForLandCell maps nearest seed to continent id', () {
      final g = TileMapGridGraph(genParams(width: 10, height: 10));
      final seeds = <(int, int)>[(0, 0), (9, 9)];
      final continentBySeed = <int>[2, 7];
      expect(g.continentForLandCell(1, 1, seeds, continentBySeed), 2);
      expect(g.continentForLandCell(8, 8, seeds, continentBySeed), 7);
      expect(g.continentForLandCell(1, 1, [], continentBySeed), 0);
    });

    test('countSeaCells matches sea id cells', () {
      const sea = 's1';
      final params = genParams(width: 2, height: 2);
      final g = TileMapGridGraph(params);
      final grid = [
        [sea, 'p1'],
        ['p1', sea],
      ];
      expect(g.countSeaCells(grid, sea), 2);
    });
  });
}
