import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:test/test.dart';

void main() {
  group('resolveEffectiveSetupSeed', () {
    test('returns config seed when positive', () {
      expect(resolveEffectiveSetupSeed(9001), 9001);
      expect(resolveEffectiveSetupSeed(1), 1);
    });

    test('throws when config seed is negative', () {
      expect(() => resolveEffectiveSetupSeed(-1), throwsArgumentError);
    });

    test('zero yields a large positive epoch-based value', () {
      final a = resolveEffectiveSetupSeed(0);
      expect(a, greaterThan(1_000_000_000));
    });
  });
}
