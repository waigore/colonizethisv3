import 'package:test/test.dart';

import '../tool/check_combat_test_no_local_support.dart';

void main() {
  group('combatTestNoLocalSupportPathInScope', () {
    test('positive: paths under the combat test tree are in scope', () {
      expect(
        combatTestNoLocalSupportPathInScope(
          'packages/colonizethis_combat/test/combat/foo_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: lib sources and other packages are out of scope', () {
      expect(
        combatTestNoLocalSupportPathInScope(
          'packages/colonizethis_combat/lib/src/combat/foo.dart',
        ),
        isFalse,
      );
      expect(
        combatTestNoLocalSupportPathInScope(
          'packages/colonizethis_combat_test_support/lib/src/foo.dart',
        ),
        isFalse,
      );
    });
  });

  group('combatTestLocalSupportViolationReason', () {
    test('positive: a *_test_support.dart file is flagged', () {
      final reason = combatTestLocalSupportViolationReason(
        'military_strength_test_support.dart',
      );
      expect(reason, isNotNull);
      expect(reason, contains('colonizethis_combat_test_support'));
    });

    test('negative: regular test files are allowed', () {
      expect(
        combatTestLocalSupportViolationReason('military_strength_test.dart'),
        isNull,
      );
    });
  });

  group('runCheckCombatTestNoLocalSupport', () {
    test('passes on the current repo tree', () {
      expect(runCheckCombatTestNoLocalSupport('.'), 0);
    });
  });
}
