import 'package:colonizethis_ai/src/util/ai_random_utils.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('pickWeightedIndex', () {
    test('returns null for empty and zero total weights', () {
      expect(pickWeightedIndex(const [], 42), isNull);
      expect(pickWeightedIndex(const [0, 0, 0], 42), isNull);
    });

    test('is deterministic for same seed and weights', () {
      final first = pickWeightedIndex(const [1.0, 2.0, 3.0], 1001);
      final second = pickWeightedIndex(const [1.0, 2.0, 3.0], 1001);
      expect(first, equals(second));
    });

    test('supports deterministic tie handling with int roll mode', () {
      final first = pickWeightedIndex(const [1, 1, 1], 77, useIntRoll: true);
      final second = pickWeightedIndex(const [1, 1, 1], 77, useIntRoll: true);
      expect(first, equals(second));
      expect(first, inInclusiveRange(0, 2));
    });
  });
}
