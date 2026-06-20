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
}
