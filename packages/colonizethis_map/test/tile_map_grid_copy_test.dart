import 'package:colonizethis_map/src/tile_map_grid_copy.dart';
import 'package:test/test.dart';

void main() {
  group('copyTileMapGrid', () {
    test('returns independent deep copy', () {
      final grid = [
        ['a', 'b'],
        ['c', 'd'],
      ];
      final copy = copyTileMapGrid(grid);
      expect(copy, grid);
      copy[0][0] = 'z';
      expect(grid[0][0], 'a');
    });
  });
}
