import 'dart:math';

import 'package:colonizethis_map/src/tile_map_manhattan_distance_transform.dart';
import 'package:colonizethis_test/test.dart';

int _bruteManhattanMin(
  int width,
  int height,
  int x,
  int y,
  bool Function(int x, int y) isSource,
  int distanceWhenNoSources,
) {
  var best = distanceWhenNoSources;
  for (var ny = 0; ny < height; ny++) {
    for (var nx = 0; nx < width; nx++) {
      if (!isSource(nx, ny)) continue;
      final d = (x - nx).abs() + (y - ny).abs();
      if (d < best) best = d;
    }
  }
  return best;
}

void main() {
  group('manhattanDistToNearestSourceXY', () {
    test('matches brute force on a small grid with sparse sources', () {
      const w = 6;
      const h = 5;
      const emptySentinel = w + h;
      bool isSource(int x, int y) =>
          (x == 2 && y == 1) || (x == 5 && y == 4) || (x == 0 && y == 0);

      final dist = manhattanDistToNearestSourceXY(
        w,
        h,
        isSource,
        distanceWhenNoSources: emptySentinel,
      );

      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          expect(
            dist[y][x],
            _bruteManhattanMin(w, h, x, y, isSource, emptySentinel),
          );
        }
      }
    });

    test('uses distanceWhenNoSources when no source cells exist', () {
      const w = 4;
      const h = 4;
      const emptySentinel = 99;
      final dist = manhattanDistToNearestSourceXY(
        w,
        h,
        (_, __) => false,
        distanceWhenNoSources: emptySentinel,
      );
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          expect(dist[y][x], emptySentinel);
        }
      }
    });

    test('returns empty list for non-positive dimensions', () {
      expect(
        manhattanDistToNearestSourceXY(
          0,
          3,
          (_, __) => true,
          distanceWhenNoSources: 0,
        ),
        isEmpty,
      );
      expect(
        manhattanDistToNearestSourceXY(
          3,
          0,
          (_, __) => true,
          distanceWhenNoSources: 0,
        ),
        isEmpty,
      );
    });

    test('every cell is 0 when all cells are sources', () {
      const w = 3;
      const h = 3;
      final dist = manhattanDistToNearestSourceXY(
        w,
        h,
        (_, __) => true,
        distanceWhenNoSources: 10,
      );
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          expect(dist[y][x], 0);
        }
      }
    });

    test('matches brute force on pseudo-random 8x8 masks', () {
      final rnd = Random(42);
      const w = 8;
      const h = 8;
      const emptySentinel = w + h;
      for (var trial = 0; trial < 40; trial++) {
        final mask = List.generate(
          h,
          (_) => List<bool>.generate(w, (_) => rnd.nextBool()),
        );
        bool isSource(int x, int y) => mask[y][x];

        final dist = manhattanDistToNearestSourceXY(
          w,
          h,
          isSource,
          distanceWhenNoSources: emptySentinel,
        );
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            expect(
              dist[y][x],
              _bruteManhattanMin(w, h, x, y, isSource, emptySentinel),
              reason: 'trial=$trial cell=($x,$y)',
            );
          }
        }
      }
    });
  });
}
