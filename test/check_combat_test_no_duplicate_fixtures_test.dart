import 'package:test/test.dart';

import '../tool/check_combat_test_no_duplicate_fixtures.dart';

void main() {
  group('combatTestNoDuplicateFixturesPathInScope', () {
    test('positive: paths under the combat test tree are in scope', () {
      expect(
        combatTestNoDuplicateFixturesPathInScope(
          'packages/colonizethis_combat/test/combat/foo_test.dart',
        ),
        isTrue,
      );
      expect(
        combatTestNoDuplicateFixturesPathInScope(
          'packages\\colonizethis_combat\\test\\bar_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: lib sources and other packages are out of scope', () {
      expect(
        combatTestNoDuplicateFixturesPathInScope(
          'packages/colonizethis_combat/lib/src/combat/foo.dart',
        ),
        isFalse,
      );
      expect(
        combatTestNoDuplicateFixturesPathInScope(
          'packages/colonizethis_diplomacy/test/test_fixtures.dart',
        ),
        isFalse,
      );
    });
  });

  group('combatTestDuplicateFixturesViolationReason', () {
    test('positive: a re-added test_fixtures.dart file is flagged', () {
      final reason = combatTestDuplicateFixturesViolationReason(
        'test_fixtures.dart',
        'abstract final class TestFixtures { TestFixtures._(); }',
      );
      expect(reason, isNotNull);
      expect(reason, contains(combatTestSharedFixturesImport));
    });

    test('positive: a redefined TestFixtures class is flagged', () {
      const content = '''
import 'package:colonizethis_models/colonizethis_models.dart';

abstract final class TestFixtures {
  TestFixtures._();
}
''';
      final reason = combatTestDuplicateFixturesViolationReason(
        'some_local_helpers.dart',
        content,
      );
      expect(reason, isNotNull);
      expect(reason, contains('redefines a local `TestFixtures`'));
    });

    test('negative: importing the shared fixtures is allowed', () {
      const content = '''
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  final game = TestFixtures.minimalGame();
}
''';
      final reason = combatTestDuplicateFixturesViolationReason(
        'military_attack_economy_test.dart',
        content,
      );
      expect(reason, isNull);
    });

    test('negative: a class whose name merely contains TestFixtures is allowed',
        () {
      const content = '''
class MyTestFixturesBuilder {
  const MyTestFixturesBuilder();
}
''';
      final reason = combatTestDuplicateFixturesViolationReason(
        'builder_test.dart',
        content,
      );
      expect(reason, isNull);
    });
  });

  group('runCheckCombatTestNoDuplicateFixtures', () {
    test('passes on the current repo tree', () {
      expect(runCheckCombatTestNoDuplicateFixtures('.'), 0);
    });
  });
}
