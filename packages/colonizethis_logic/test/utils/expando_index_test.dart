import 'package:colonizethis_logic/src/utils/expando_index.dart';
import 'package:colonizethis_test/test.dart';

/// Object wrapper used as the Expando key in tests. Plain `Object` works too,
/// but using a typed key keeps generic inference explicit.
class _Key {
  _Key(this.label);
  final String label;
}

void main() {
  group('ExpandoIndex.get', () {
    test('builds on first access and reuses cached value', () {
      var builds = 0;
      final cache = ExpandoIndex<_Key, List<int>>('test.builds-once', (key) {
        builds++;
        return [key.label.length];
      });
      final key = _Key('alpha');

      final first = cache.get(key);
      final second = cache.get(key);

      expect(builds, 1);
      expect(first, [5]);
      expect(identical(first, second), isTrue);
    });

    test('builds separately for distinct key instances', () {
      var builds = 0;
      final cache = ExpandoIndex<_Key, Map<String, int>>('test.per-key', (key) {
        builds++;
        return {key.label: key.label.length};
      });

      final a = _Key('aa');
      final b = _Key('bbb');
      final aMap = cache.get(a);
      final bMap = cache.get(b);
      cache.get(a);
      cache.get(b);

      expect(builds, 2);
      expect(aMap, {'aa': 2});
      expect(bMap, {'bbb': 3});
      expect(identical(aMap, bMap), isFalse);
    });

    test(
      'keys equal by `==` but not identical do not share the cache entry',
      () {
        var builds = 0;
        final cache = ExpandoIndex<List<int>, int>('test.identity-only', (key) {
          builds++;
          return key.length;
        });

        final keyA = [1, 2, 3];
        final keyB = [1, 2, 3];
        expect(keyA == keyB, isFalse, reason: 'List == is identity in Dart');

        cache.get(keyA);
        cache.get(keyB);

        expect(builds, 2);
      },
    );

    test(
      'non-nullable bool values cache correctly (false is not "missing")',
      () {
        var builds = 0;
        final cache = ExpandoIndex<_Key, bool>('test.bool-false', (key) {
          builds++;
          return key.label.isEmpty;
        });
        final emptyKey = _Key('');
        final nonEmptyKey = _Key('abc');

        expect(cache.get(emptyKey), isTrue);
        expect(cache.get(nonEmptyKey), isFalse);
        cache.get(emptyKey);
        cache.get(nonEmptyKey);

        expect(builds, 2);
      },
    );
  });

  group('ExpandoIndex.peek', () {
    test('returns null when no value has been built yet', () {
      final cache = ExpandoIndex<_Key, int>('test.peek-empty', (_) => 1);
      expect(cache.peek(_Key('x')), isNull);
    });

    test('returns the cached value once built', () {
      final cache = ExpandoIndex<_Key, int>('test.peek-after-get', (_) => 42);
      final key = _Key('x');
      cache.get(key);
      expect(cache.peek(key), 42);
    });

    test('does not build a value', () {
      var builds = 0;
      final cache = ExpandoIndex<_Key, int>('test.peek-no-build', (_) {
        builds++;
        return 1;
      });
      cache.peek(_Key('x'));
      expect(builds, 0);
    });
  });

  group('ExpandoIndex.put', () {
    test(
      'stores a value that subsequent get calls return without rebuilding',
      () {
        var builds = 0;
        final cache = ExpandoIndex<_Key, int>('test.put-replaces-build', (_) {
          builds++;
          return -1;
        });
        final key = _Key('x');
        cache.put(key, 99);

        expect(cache.get(key), 99);
        expect(builds, 0);
      },
    );

    test('overwrites a previously built value', () {
      final cache = ExpandoIndex<_Key, int>('test.put-overwrites', (_) => 1);
      final key = _Key('x');
      expect(cache.get(key), 1);
      cache.put(key, 2);
      expect(cache.get(key), 2);
    });
  });
}
