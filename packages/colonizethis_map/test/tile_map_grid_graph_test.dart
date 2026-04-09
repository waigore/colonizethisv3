import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

void main() {
  group('TileMapGridGraph', () {
    test('connectedComponentsOfLand splits two 4-connected blobs', () {
      final params = TileMapParams(width: 4, height: 2);
      final g = TileMapGridGraph(params);
      final a = <(int, int)>{(0, 0), (1, 0)};
      final b = <(int, int)>{(3, 0), (3, 1)};
      final comps = g.connectedComponentsOfLand({...a, ...b});
      expect(comps.length, 2);
      expect(comps.any((c) => c.containsAll(a)), isTrue);
      expect(comps.any((c) => c.containsAll(b)), isTrue);
    });

    test('oceanCells includes boundary sea and floods inward', () {
      const sea = 's1';
      final params = TileMapParams(width: 3, height: 3);
      final g = TileMapGridGraph(params);
      final grid = List.generate(
        3,
        (_) => List.filled(3, sea),
      );
      final ocean = g.oceanCells(grid, sea);
      expect(ocean.length, 9);
    });

    test('countSeaCells matches sea id cells', () {
      const sea = 's1';
      final params = TileMapParams(width: 2, height: 2);
      final g = TileMapGridGraph(params);
      final grid = [
        [sea, 'p1'],
        ['p1', sea],
      ];
      expect(g.countSeaCells(grid, sea), 2);
    });
  });
}
