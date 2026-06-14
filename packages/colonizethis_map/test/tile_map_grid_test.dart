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
}
