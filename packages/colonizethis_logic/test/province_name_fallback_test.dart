import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('generateUniqueProvinceName', () {
    test('same seed and empty set yields same name', () {
      final a = generateUniqueProvinceName(42, <String>{});
      final b = generateUniqueProvinceName(42, <String>{});
      expect(a, b);
    });

    test('generated name is added to set', () {
      final used = <String>{};
      final name = generateUniqueProvinceName(123, used);
      expect(used, contains(name));
    });

    test('second call with same seed hits collision and returns different name', () {
      final used = <String>{};
      final first = generateUniqueProvinceName(99, used);
      final second = generateUniqueProvinceName(99, used);
      expect(second, isNot(first));
      expect(used, contains(first));
      expect(used, contains(second));
    });

    test('generated names are never empty', () {
      final used = <String>{};
      for (var seed = 0; seed < 20; seed++) {
        final name = generateUniqueProvinceName(seed, used);
        expect(name.isNotEmpty, isTrue, reason: 'seed $seed');
      }
    });

    test('many consecutive calls yield unique names', () {
      final used = <String>{};
      final names = <String>[];
      for (var i = 0; i < 50; i++) {
        names.add(generateUniqueProvinceName(1000 + i, used));
      }
      expect(used.length, 50);
      expect(names.toSet().length, 50);
    });

    test('exhausted retries use seed-based fallback', () {
      const seed = 0;
      final base = generateUniqueProvinceName(seed, <String>{});
      final used = <String>{base};
      for (var n = 2; n <= 100; n++) {
        used.add('$base $n');
      }
      final result = generateUniqueProvinceName(seed, used);
      expect(result, endsWith(' (${seed & 0xFFFF})'));
      expect(used, contains(result));
    });
  });
}
