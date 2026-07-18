import 'package:colonizethis_models/src/model_collection_equality.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('modelListEquals', () {
    test('positive: identical and equal lists', () {
      const xs = <int>[1, 2, 3];
      expect(modelListEquals(xs, xs), isTrue);
      expect(modelListEquals(<int>[1, 2], <int>[1, 2]), isTrue);
    });

    test('negative: length or element mismatch', () {
      expect(modelListEquals(<int>[1], <int>[1, 2]), isFalse);
      expect(modelListEquals(<int>[1, 2], <int>[1, 3]), isFalse);
    });
  });

  group('modelMapEquals / modelNullableMapEquals', () {
    test('positive: matching maps', () {
      expect(modelMapEquals({'a': 1}, {'a': 1}), isTrue);
      expect(modelNullableMapEquals(null, null), isTrue);
      expect(modelNullableMapEquals({'a': 1}, {'a': 1}), isTrue);
    });

    test('negative: null asymmetry or value mismatch', () {
      expect(modelNullableMapEquals(null, {'a': 1}), isFalse);
      expect(modelMapEquals({'a': 1}, {'a': 2}), isFalse);
      expect(modelMapEquals({'a': 1}, {'b': 1}), isFalse);
    });
  });

  group('modelSetEquals', () {
    test('positive: same members regardless of iteration order', () {
      expect(modelSetEquals({'a', 'b'}, {'b', 'a'}), isTrue);
    });

    test('negative: missing member', () {
      expect(modelSetEquals({'a'}, {'a', 'b'}), isFalse);
    });
  });

  group('modelMapOfListEquals / modelNullableMapOfListEquals', () {
    test('positive: matching map-of-lists', () {
      expect(
        modelMapOfListEquals(
          {
            'p': [1, 2],
          },
          {
            'p': [1, 2],
          },
        ),
        isTrue,
      );
      expect(modelNullableMapOfListEquals(null, null), isTrue);
    });

    test('negative: list element or null asymmetry', () {
      expect(
        modelMapOfListEquals(
          {
            'p': [1],
          },
          {
            'p': [2],
          },
        ),
        isFalse,
      );
      expect(
        modelNullableMapOfListEquals({
          'p': [1],
        }, null),
        isFalse,
      );
    });
  });
}
