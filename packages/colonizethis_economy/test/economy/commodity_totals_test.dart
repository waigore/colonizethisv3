import 'package:colonizethis_economy/src/economy/commodity_totals.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('addUnits', () {
    test('creates a new entry starting from zero', () {
      final m = <String, int>{};
      addUnits(m, 'a', 3);
      expect(m, {'a': 3});
    });

    test('accumulates onto an existing entry', () {
      final m = <String, int>{'a': 3};
      addUnits(m, 'a', 4);
      expect(m['a'], 7);
    });

    test('preserves first-seen insertion order across keys', () {
      final m = <String, int>{};
      addUnits(m, 'b', 1);
      addUnits(m, 'a', 1);
      addUnits(m, 'b', 1);
      expect(m.keys.toList(), ['b', 'a']);
      expect(m, {'b': 2, 'a': 1});
    });

    test('does not filter zero or negative deltas (caller guards)', () {
      final m = <String, int>{'a': 5};
      addUnits(m, 'a', 0);
      addUnits(m, 'a', -2);
      addUnits(m, 'z', -1);
      expect(m, {'a': 3, 'z': -1});
    });
  });

  group('sumValues', () {
    test('returns 0 for an empty iterable', () {
      expect(sumValues(const <int>[]), 0);
    });

    test('sums positive and negative values', () {
      expect(sumValues(const [1, 2, 3]), 6);
      expect(sumValues(const [5, -2, -1]), 2);
    });

    test('matches the inline fold idiom it replaces', () {
      const values = [4, 8, 15, 16, 23, 42];
      expect(sumValues(values), values.fold<int>(0, (a, b) => a + b));
    });
  });

  group('sumNestedValues', () {
    test('returns 0 for no maps and for empty maps', () {
      expect(sumNestedValues(const <Map<String, int>>[]), 0);
      expect(sumNestedValues(const [<String, int>{}, <String, int>{}]), 0);
    });

    test('sums every value across nested maps', () {
      final maps = [
        {'a': 1, 'b': 2},
        {'a': 3},
        <String, int>{},
        {'c': 4},
      ];
      expect(sumNestedValues(maps), 10);
    });
  });
}
