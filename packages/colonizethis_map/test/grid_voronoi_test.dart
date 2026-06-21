import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/src/gen/grid_voronoi.dart';

void main() {
  group('deterministicNoise', () {
    test('returns value in [-1, 1]', () {
      for (var seed = 0; seed < 5; seed++) {
        for (var x = 0; x < 3; x++) {
          for (var y = 0; y < 3; y++) {
            final n = deterministicNoise(seed, x, y);
            expect(n, greaterThanOrEqualTo(-1));
            expect(n, lessThanOrEqualTo(1));
          }
        }
      }
    });

    test('is deterministic for same inputs', () {
      expect(deterministicNoise(42, 1, 2), equals(deterministicNoise(42, 1, 2)));
      expect(deterministicNoise(0, 0, 0), equals(deterministicNoise(0, 0, 0)));
    });
  });

  group('assignCellsToNearestSeed', () {
    test('empty seeds returns empty map', () {
      final result = assignCellsToNearestSeed(
        [(0, 0), (1, 1)],
        {},
      );
      expect(result, isEmpty);
    });

    test('each cell gets nearer seed id', () {
      final seeds = {
        'a': (0, 0),
        'b': (10, 10),
      };
      final cells = [(0, 0), (1, 0), (9, 10), (10, 10), (5, 5)];
      final result = assignCellsToNearestSeed(cells, seeds);
      expect(result[(0, 0)], 'a');
      expect(result[(1, 0)], 'a');
      expect(result[(9, 10)], 'b');
      expect(result[(10, 10)], 'b');
      // (5,5) is equidistant; tie-break by id so 'a' < 'b' -> 'a'
      expect(result[(5, 5)], 'a');
    });

    test('tie-break by seed id order', () {
      final seeds = {
        's2': (5, 5),
        's1': (5, 5),
      };
      final result = assignCellsToNearestSeed([(5, 5)], seeds);
      expect(result[(5, 5)], 's1');
    });

    test('with noiseScale 0 same as no noise', () {
      final seeds = {'p1': (0, 0), 'p2': (2, 0)};
      final cells = [(1, 0)];
      final r0 = assignCellsToNearestSeed(cells, seeds);
      final r1 = assignCellsToNearestSeed(cells, seeds, noiseScale: 0, noiseSeed: 99);
      expect(r1[(1, 0)], r0[(1, 0)]);
    });

    test('with noiseScale non-zero still returns one id per cell', () {
      final seeds = {'a': (0, 0), 'b': (10, 10)};
      final cells = [(5, 5), (3, 3), (7, 7)];
      final result = assignCellsToNearestSeed(
        cells,
        seeds,
        noiseScale: 1.0,
        noiseSeed: 123,
      );
      expect(result.length, 3);
      for (final c in cells) {
        expect(result[c], anyOf('a', 'b'));
      }
    });
  });
}

