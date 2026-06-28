// SPEC/program/game-setup-pipeline.md;
// SPEC/program/fog-and-exploration-resolution.md.
// Direct unit tests for the shared full-grid tile-cell scan (tile_cell_scan.dart)
// that now backs the three near-identical scans in initial_visibility.dart
// (Refs #3740).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/src/setup/tile_cell_scan.dart';
import 'package:colonizethis_test/test.dart';

TileMapResult _map(List<List<String>> grid) => TileMapResult(
  width: grid.isEmpty ? 0 : grid.first.length,
  height: grid.length,
  grid: grid,
);

void main() {
  group('forEachTileCell', () {
    test('visits every cell in row-major order (y outer, x inner)', () {
      final map = _map([
        ['a', 'b', 'c'],
        ['d', 'e', 'f'],
      ]);
      final visited = <(int, int, String, String)>[];
      forEachTileCell(map, 'ow', (x, y, localId, tileKey) {
        visited.add((x, y, localId, tileKey));
      });

      expect(visited, hasLength(6));
      expect(visited.map((v) => (v.$1, v.$2)).toList(), [
        (0, 0),
        (1, 0),
        (2, 0),
        (0, 1),
        (1, 1),
        (2, 1),
      ]);
    });

    test('passes local id and canonical CapitalTile.tileKey for each cell', () {
      final map = _map([
        ['p1', 'sea'],
      ]);
      final byCoord = <(int, int), (String, String)>{};
      forEachTileCell(map, 'ow', (x, y, localId, tileKey) {
        byCoord[(x, y)] = (localId, tileKey);
      });

      expect(byCoord[(0, 0)], ('p1', CapitalTile.tileKey('ow', 'p1', 0, 0)));
      expect(byCoord[(1, 0)], ('sea', CapitalTile.tileKey('ow', 'sea', 1, 0)));
      // tileKey contract is regionId|localId|x|y.
      expect(byCoord[(0, 0)]!.$2, 'ow|p1|0|0');
    });

    test('uses the supplied region id when building tile keys', () {
      final map = _map([
        ['n1'],
      ]);
      late String captured;
      forEachTileCell(map, 'nw', (x, y, localId, tileKey) {
        captured = tileKey;
      });
      expect(captured, 'nw|n1|0|0');
    });

    test('does not invoke the visitor for an empty (0x0) grid', () {
      final map = _map(const <List<String>>[]);
      var calls = 0;
      forEachTileCell(map, 'ow', (_, __, ___, ____) => calls++);
      expect(calls, 0);
    });

    test('does not invoke the visitor for a zero-width grid', () {
      final map = TileMapResult(width: 0, height: 2, grid: const [[], []]);
      var calls = 0;
      forEachTileCell(map, 'ow', (_, __, ___, ____) => calls++);
      expect(calls, 0);
    });
  });
}
