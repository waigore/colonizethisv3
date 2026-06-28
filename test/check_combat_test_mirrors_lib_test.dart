import 'package:test/test.dart';

import '../tool/check_combat_test_mirrors_lib.dart';

void main() {
  group('combatTestMirrorsLibPathInScope', () {
    test('positive: paths under the combat test tree are in scope', () {
      expect(
        combatTestMirrorsLibPathInScope(
          'packages/colonizethis_combat/test/combat/foo_test.dart',
        ),
        isTrue,
      );
      expect(
        combatTestMirrorsLibPathInScope(
          'packages\\colonizethis_combat\\test\\bar_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: lib sources and other packages are out of scope', () {
      expect(
        combatTestMirrorsLibPathInScope(
          'packages/colonizethis_combat/lib/src/combat/foo.dart',
        ),
        isFalse,
      );
      expect(
        combatTestMirrorsLibPathInScope(
          'packages/colonizethis_diplomacy/test/foo_test.dart',
        ),
        isFalse,
      );
    });
  });

  group('combatTestMirrorsLibViolationReason', () {
    test('positive: a flat-root test file is flagged', () {
      final reason = combatTestMirrorsLibViolationReason(
        'packages/colonizethis_combat/test/combat_rng_test.dart',
      );
      expect(reason, isNotNull);
      expect(reason, contains('test/combat/'));
    });

    test('positive: a flat-root support helper is flagged', () {
      final reason = combatTestMirrorsLibViolationReason(
        'packages/colonizethis_combat/test/military_strength_test_support.dart',
      );
      expect(reason, isNotNull);
    });

    test('positive: backslash-separated flat-root path is flagged', () {
      final reason = combatTestMirrorsLibViolationReason(
        'packages\\colonizethis_combat\\test\\combat_rng_test.dart',
      );
      expect(reason, isNotNull);
    });

    test('negative: a nested test file under test/combat/ is allowed', () {
      final reason = combatTestMirrorsLibViolationReason(
        'packages/colonizethis_combat/test/combat/combat_rng_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: a deeply nested test file is allowed', () {
      final reason = combatTestMirrorsLibViolationReason(
        'packages/colonizethis_combat/test/combat/quick_battle/foo_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: files outside the combat test tree are ignored', () {
      expect(
        combatTestMirrorsLibViolationReason(
          'packages/colonizethis_orders/test/foo_test.dart',
        ),
        isNull,
      );
      expect(
        combatTestMirrorsLibViolationReason(
          'packages/colonizethis_combat/lib/src/combat/combat_rng.dart',
        ),
        isNull,
      );
    });
  });

  group('runCheckCombatTestMirrorsLib', () {
    test('passes on the current repo tree', () {
      expect(runCheckCombatTestMirrorsLib('.'), 0);
    });
  });
}
