import 'package:colonizethis_map/src/tile_map_directions.dart';
import 'package:test/test.dart';

void main() {
  group('kTileMapDirections4', () {
    test('has four orthogonal neighbors in N,E,S,W order', () {
      expect(kTileMapDirections4, [
        (0, -1),
        (1, 0),
        (0, 1),
        (-1, 0),
      ]);
    });

    test('kTileMapDirections8 starts with four orthogonal deltas', () {
      expect(kTileMapDirections8.take(4), kTileMapDirections4);
      expect(kTileMapDirections8, hasLength(8));
    });
  });
}
