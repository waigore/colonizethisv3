import 'package:test/test.dart';

import '../tool/check_diplomacy_test_no_duplicate_fixtures.dart';

void main() {
  group('diplomacyTestNoDuplicateFixturesPathInScope', () {
    test('positive: paths under the diplomacy test tree are in scope', () {
      expect(
        diplomacyTestNoDuplicateFixturesPathInScope(
          'packages/colonizethis_diplomacy/test/diplomacy/foo_test.dart',
        ),
        isTrue,
      );
      expect(
        diplomacyTestNoDuplicateFixturesPathInScope(
          'packages\\colonizethis_diplomacy\\test\\bar_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: lib sources and other packages are out of scope', () {
      expect(
        diplomacyTestNoDuplicateFixturesPathInScope(
          'packages/colonizethis_diplomacy/lib/src/diplomacy/foo.dart',
        ),
        isFalse,
      );
      expect(
        diplomacyTestNoDuplicateFixturesPathInScope(
          'packages/colonizethis_orders/test/test_fixtures.dart',
        ),
        isFalse,
      );
    });
  });

  group('diplomacyTestDuplicateFixturesViolationReason', () {
    test('positive: a re-added test_fixtures.dart file is flagged', () {
      final reason = diplomacyTestDuplicateFixturesViolationReason(
        'test_fixtures.dart',
        'abstract final class TestFixtures { TestFixtures._(); }',
      );
      expect(reason, isNotNull);
      expect(reason, contains(diplomacyTestSharedFixturesImport));
    });

    test('positive: a redefined TestFixtures class is flagged', () {
      const content = '''
import 'package:colonizethis_models/colonizethis_models.dart';

abstract final class TestFixtures {
  TestFixtures._();
}
''';
      final reason = diplomacyTestDuplicateFixturesViolationReason(
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
      final reason = diplomacyTestDuplicateFixturesViolationReason(
        'overture_resolver_test.dart',
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
      final reason = diplomacyTestDuplicateFixturesViolationReason(
        'builder_test.dart',
        content,
      );
      expect(reason, isNull);
    });
  });

  group('runCheckDiplomacyTestNoDuplicateFixtures', () {
    test('passes on the current repo tree', () {
      expect(runCheckDiplomacyTestNoDuplicateFixtures('.'), 0);
    });
  });
}
