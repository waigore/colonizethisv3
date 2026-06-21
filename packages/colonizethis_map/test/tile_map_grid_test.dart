import 'package:colonizethis_map/src/tile_map_grid.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TileMapGrid.copy', () {
    test('returns independent deep copy', () {
      final grid = [
        ['a', 'b'],
        ['c', 'd'],
      ];
      final copy = TileMapGrid.copy(grid);
      expect(copy, grid);
      copy[0][0] = 'z';
      expect(grid[0][0], 'a');
    });

    test('copies each row into a fresh list', () {
      final grid = [
        [1, 2, 3],
        [4, 5, 6],
      ];
      final copy = TileMapGrid.copy(grid);
      expect(identical(copy, grid), isFalse);
      expect(identical(copy[0], grid[0]), isFalse);
      copy[1][2] = 99;
      expect(grid[1][2], 6);
    });

    test('preserves empty rows and empty grid', () {
      expect(TileMapGrid.copy(<List<int>>[]), isEmpty);
      final withEmptyRow = [<int>[]];
      final copy = TileMapGrid.copy(withEmptyRow);
      expect(copy, [<int>[]]);
      expect(identical(copy.first, withEmptyRow.first), isFalse);
    });
  });

  group('TileMapGrid.filled', () {
    test('creates uniform grid of requested dimensions', () {
      final grid = TileMapGrid.filled(3, 4, 'sea');
      expect(grid.length, 3);
      expect(grid.every((row) => row.length == 4), isTrue);
      expect(grid.every((row) => row.every((cell) => cell == 'sea')), isTrue);
    });

    test('each row is an independent list', () {
      final grid = TileMapGrid.filled(2, 2, 0);
      grid[0][0] = 99;
      expect(grid[1][0], 0);
    });

    test('returns empty grid for non-positive dimensions', () {
      expect(TileMapGrid.filled(0, 5, 1), isEmpty);
      expect(TileMapGrid.filled(3, 0, 1), [
        <int>[],
        <int>[],
        <int>[],
      ]);
    });
  });

  group('TileMapGrid.generate', () {
    test('invokes cellAt for each coordinate', () {
      final grid = TileMapGrid.generate(2, 3, (y, x) => y * 10 + x);
      expect(grid, [
        [0, 1, 2],
        [10, 11, 12],
      ]);
    });

    test('each row is an independent list', () {
      final grid = TileMapGrid.generate(2, 2, (_, __) => 0);
      grid[0][0] = 99;
      expect(grid[1][0], 0);
    });
  });

  group('TileMapGrid.forEachIndex', () {
    test('visits every (y, x) in row-major order (y outer, x inner)', () {
      final visited = <(int, int)>[];
      TileMapGrid.forEachIndex(2, 3, (y, x) => visited.add((y, x)));
      expect(visited, [
        (0, 0),
        (0, 1),
        (0, 2),
        (1, 0),
        (1, 1),
        (1, 2),
      ]);
    });

    test('matches a hand-rolled nested y/x loop exactly (determinism)', () {
      final fromHelper = <(int, int)>[];
      TileMapGrid.forEachIndex(4, 5, (y, x) => fromHelper.add((y, x)));
      final fromLoop = <(int, int)>[];
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 5; x++) {
          fromLoop.add((y, x));
        }
      }
      expect(fromHelper, fromLoop);
    });

    test('does not invoke visit for non-positive dimensions', () {
      var calls = 0;
      TileMapGrid.forEachIndex(0, 5, (_, __) => calls++);
      TileMapGrid.forEachIndex(5, 0, (_, __) => calls++);
      expect(calls, 0);
    });

    test('early return inside visit acts as a per-cell continue', () {
      final landCells = <(int, int)>[];
      final grid = [
        ['land', 'sea'],
        ['sea', 'land'],
      ];
      TileMapGrid.forEachIndex(2, 2, (y, x) {
        if (grid[y][x] != 'land') return;
        landCells.add((x, y));
      });
      expect(landCells, [(0, 0), (1, 1)]);
    });
  });

  group('TileMapGrid.forEachCell', () {
    test('visits each cell with coordinates and value in row-major order', () {
      final visited = <(int, int, String)>[];
      final grid = [
        ['a', 'b', 'c'],
        ['d', 'e', 'f'],
      ];
      TileMapGrid.forEachCell(grid, (y, x, v) => visited.add((y, x, v)));
      expect(visited, [
        (0, 0, 'a'),
        (0, 1, 'b'),
        (0, 2, 'c'),
        (1, 0, 'd'),
        (1, 1, 'e'),
        (1, 2, 'f'),
      ]);
    });

    test('derives dimensions from the grid and supports ragged rows', () {
      final visited = <(int, int, int)>[];
      final ragged = [
        [1, 2],
        [3],
        [4, 5, 6],
      ];
      TileMapGrid.forEachCell(ragged, (y, x, v) => visited.add((y, x, v)));
      expect(visited, [
        (0, 0, 1),
        (0, 1, 2),
        (1, 0, 3),
        (2, 0, 4),
        (2, 1, 5),
        (2, 2, 6),
      ]);
    });

    test('does not invoke visit for an empty grid', () {
      var calls = 0;
      TileMapGrid.forEachCell(<List<int>>[], (_, __, ___) => calls++);
      expect(calls, 0);
    });
  });
}
