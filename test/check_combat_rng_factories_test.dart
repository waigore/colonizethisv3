import 'package:test/test.dart';

import '../tool/check_combat_rng_factories.dart';

void main() {
  group('findCombatRngFactoryViolations', () {
    test('flags a direct Random(...) construction outside the seam', () {
      const src = r'''
import 'dart:math';

Random rngFor(int seed) {
  return Random(seed);
}
''';
      final violations = findCombatRngFactoryViolations(
        relativePath:
            'packages/colonizethis_combat/lib/src/combat/quick_battle_resolver.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('combat_rng.dart factory'));
    });

    test('flags a direct DeterministicRng(...) construction', () {
      const src = r'''
final rng = DeterministicRng(seed);
''';
      final violations = findCombatRngFactoryViolations(
        relativePath:
            'packages/colonizethis_combat/lib/src/combat/naval_combat_resolver.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('does not flag a Random type annotation without construction', () {
      const src = r'''
Random pickRng(Random injected) => injected;
''';
      final violations = findCombatRngFactoryViolations(
        relativePath:
            'packages/colonizethis_combat/lib/src/combat/combat_resolver.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('exempts combat_rng.dart (the factory module itself)', () {
      const src = r'''
Random quickBattleRng(int seed) => Random(seed);
DeterministicRng navalCombatRng(int seed) => DeterministicRng(seed);
''';
      final violations = findCombatRngFactoryViolations(
        relativePath:
            'packages/colonizethis_combat/lib/src/combat/combat_rng.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('exempts deterministic_rng.dart (the LCG implementation)', () {
      const src = r'''
class DeterministicRng {
  DeterministicRng(this._seed);
  int _seed;
}
''';
      final violations = findCombatRngFactoryViolations(
        relativePath:
            'packages/colonizethis_combat/lib/src/combat/deterministic_rng.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a comment mentioning Random(...)', () {
      const src = r'''
/// Was previously Random(seed) inline; now via quickBattleRng(seed).
final rng = quickBattleRng(seed);
''';
      final violations = findCombatRngFactoryViolations(
        relativePath:
            'packages/colonizethis_combat/lib/src/combat/quick_battle_resolver.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
