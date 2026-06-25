// SPEC/game/capital-and-connectivity.md § Init town roads / Capital Setup.
// Direct unit tests for the shared 4-neighbor grid BFS (grid_bfs.dart) that now
// backs both road-geometry sites (Refs #3712).

import 'package:colonizethis_setup/src/setup/grid_bfs.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('gridCoordKey', () {
    test('formats x|y', () {
      expect(gridCoordKey(3, 7), '3|7');
    });
  });

  group('bfsGridParents', () {
    test('start maps to itself', () {
      final parents = bfsGridParents(
        startX: 1,
        startY: 1,
        width: 3,
        height: 3,
        passable: (_, __) => true,
      );
      expect(parents[gridCoordKey(1, 1)], (1, 1));
    });

    test('expands neighbors in kGridNeighborsCardinal4 order (up,right,down,left)', () {
      // 2x2 fully-passable grid from (0,0). (1,1) must be reached via (1,0)
      // because the right neighbor is processed before the down neighbor.
      final parents = bfsGridParents(
        startX: 0,
        startY: 0,
        width: 2,
        height: 2,
        passable: (_, __) => true,
      );
      expect(parents[gridCoordKey(1, 0)], (0, 0));
      expect(parents[gridCoordKey(0, 1)], (0, 0));
      expect(parents[gridCoordKey(1, 1)], (1, 0));
    });

    test('does not enter impassable cells', () {
      // Column x==1 is a wall; (2,0) is unreachable from (0,0).
      final parents = bfsGridParents(
        startX: 0,
        startY: 0,
        width: 3,
        height: 1,
        passable: (x, _) => x != 1,
      );
      expect(parents.containsKey(gridCoordKey(0, 0)), isTrue);
      expect(parents.containsKey(gridCoordKey(1, 0)), isFalse);
      expect(parents.containsKey(gridCoordKey(2, 0)), isFalse);
    });

    test('start passability is never tested', () {
      final parents = bfsGridParents(
        startX: 0,
        startY: 0,
        width: 1,
        height: 1,
        passable: (_, __) => false,
      );
      expect(parents[gridCoordKey(0, 0)], (0, 0));
    });
  });

  group('reconstructGridPath', () {
    test('returns shortest deterministic path start..end inclusive', () {
      final parents = bfsGridParents(
        startX: 0,
        startY: 0,
        width: 2,
        height: 2,
        passable: (_, __) => true,
      );
      expect(
        reconstructGridPath(parents: parents, toX: 1, toY: 1),
        [(0, 0), (1, 0), (1, 1)],
      );
    });

    test('returns single-element path when end equals start', () {
      final parents = bfsGridParents(
        startX: 2,
        startY: 2,
        width: 4,
        height: 4,
        passable: (_, __) => true,
      );
      expect(reconstructGridPath(parents: parents, toX: 2, toY: 2), [(2, 2)]);
    });

    test('returns null when the target was unreachable', () {
      final parents = bfsGridParents(
        startX: 0,
        startY: 0,
        width: 3,
        height: 1,
        passable: (x, _) => x != 1,
      );
      expect(reconstructGridPath(parents: parents, toX: 2, toY: 0), isNull);
    });
  });
}
