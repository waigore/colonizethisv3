import 'package:test/test.dart';

import '../tool/check_combat_test_core_fixtures_shared.dart';

void main() {
  group('combatTestCoreFixturesSharedPathInScope', () {
    test('positive: combat test files are in scope', () {
      expect(
        combatTestCoreFixturesSharedPathInScope(
          'packages/colonizethis_combat/test/combat/foo_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: test_support and lib paths are out of scope', () {
      expect(
        combatTestCoreFixturesSharedPathInScope(
          'packages/colonizethis_combat_test_support/lib/src/foo.dart',
        ),
        isFalse,
      );
    });
  });

  group('combatTestCoreFixturesSharedViolationReason', () {
    test('positive: inline Game( is flagged', () {
      expect(
        combatTestCoreFixturesSharedViolationReason('final g = Game(id: "x");'),
        isNotNull,
      );
    });

    test('negative: files without Game( pass', () {
      expect(
        combatTestCoreFixturesSharedViolationReason(
          'final g = landResolverBattleGame(units: []);',
        ),
        isNull,
      );
    });
  });

  group('runCheckCombatTestCoreFixturesShared', () {
    test('passes on the current repo tree', () {
      expect(runCheckCombatTestCoreFixturesShared('.'), 0);
    });
  });
}
