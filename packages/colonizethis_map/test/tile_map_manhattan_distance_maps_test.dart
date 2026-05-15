import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/src/tile_map_manhattan_distance_maps.dart';

void main() {
  group('manhattanDistToOtherContinentsMaps', () {
    test('distance 0 on other-continent cells and 1 adjacent', () {
      const w = 3;
      const h = 3;
      final grid = List.generate(h, (_) => List.filled(w, -1));
      grid[1][1] = 0;
      final maps = manhattanDistToOtherContinentsMaps(
        continentGrid: grid,
        width: w,
        height: h,
        numContinents: 2,
      );
      expect(maps[1][1][1], 0);
      expect(maps[1][0][1], 1);
      expect(maps[1][2][1], 1);
      expect(maps[1][1][0], 1);
      expect(maps[1][1][2], 1);
    });

    test('unreachable when no other-continent cells exist', () {
      const w = 2;
      const h = 2;
      final grid = List.generate(h, (_) => List.filled(w, -1));
      final maps = manhattanDistToOtherContinentsMaps(
        continentGrid: grid,
        width: w,
        height: h,
        numContinents: 1,
      );
      expect(maps[0][0][0], w + h);
    });

    test('unassigned cell uses geometric Manhattan to assigned other continent', () {
      const w = 5;
      const h = 3;
      final grid = List.generate(h, (_) => List.filled(w, -1));
      grid[1][0] = 1;
      final maps = manhattanDistToOtherContinentsMaps(
        continentGrid: grid,
        width: w,
        height: h,
        numContinents: 2,
      );
      expect(maps[0][1][4], 4);
    });
  });
}
