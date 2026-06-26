import 'package:colonizethis_combat/src/combat/deterministic_rng.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('DeterministicRng', () {
    test('same seed produces identical sequence', () {
      final a = DeterministicRng(42);
      final b = DeterministicRng(42);

      for (var i = 0; i < 20; i++) {
        expect(a.nextInt(1000), equals(b.nextInt(1000)));
      }
    });

    test('different seeds diverge', () {
      final a = DeterministicRng(1);
      final b = DeterministicRng(2);

      expect(a.nextInt(1000), isNot(equals(b.nextInt(1000))));
    });

    test('nextInt returns 0 for non-positive max', () {
      final rng = DeterministicRng(7);

      expect(rng.nextInt(0), equals(0));
      expect(rng.nextInt(-1), equals(0));
    });
  });
}
