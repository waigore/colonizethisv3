import 'package:test/test.dart';

import '../tool/check_colonizethis_setup_test_mirrors_lib.dart';

void main() {
  group('setupTestMirrorsLibPathInScope', () {
    test('positive: paths under the setup test tree are in scope', () {
      expect(
        setupTestMirrorsLibPathInScope(
          'packages/colonizethis_setup/test/setup/foo_test.dart',
        ),
        isTrue,
      );
      expect(
        setupTestMirrorsLibPathInScope(
          'packages\\colonizethis_setup\\test\\bar_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: lib sources and other packages are out of scope', () {
      expect(
        setupTestMirrorsLibPathInScope(
          'packages/colonizethis_setup/lib/src/setup/foo.dart',
        ),
        isFalse,
      );
      expect(
        setupTestMirrorsLibPathInScope(
          'packages/colonizethis_orders/test/foo_test.dart',
        ),
        isFalse,
      );
    });
  });

  group('setupTestMirrorsLibViolationReason', () {
    test('positive: a flat-root test file is flagged', () {
      final reason = setupTestMirrorsLibViolationReason(
        'packages/colonizethis_setup/test/validation_exceptions_test.dart',
      );
      expect(reason, isNotNull);
      expect(reason, contains('test/setup/'));
    });

    test('positive: a flat-root support helper is flagged', () {
      final reason = setupTestMirrorsLibViolationReason(
        'packages/colonizethis_setup/test/game_setup_town_tile_ranking_test.dart',
      );
      expect(reason, isNotNull);
    });

    test('positive: backslash-separated flat-root path is flagged', () {
      final reason = setupTestMirrorsLibViolationReason(
        'packages\\colonizethis_setup\\test\\validation_exceptions_test.dart',
      );
      expect(reason, isNotNull);
    });

    test('negative: a nested test file under test/setup/ is allowed', () {
      final reason = setupTestMirrorsLibViolationReason(
        'packages/colonizethis_setup/test/setup/validation_exceptions_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: a deeply nested test file is allowed', () {
      final reason = setupTestMirrorsLibViolationReason(
        'packages/colonizethis_setup/test/setup/plains/game_setup_plains_conversion_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: files outside the setup test tree are ignored', () {
      expect(
        setupTestMirrorsLibViolationReason(
          'packages/colonizethis_orders/test/foo_test.dart',
        ),
        isNull,
      );
      expect(
        setupTestMirrorsLibViolationReason(
          'packages/colonizethis_setup/lib/src/setup/game_setup_create.dart',
        ),
        isNull,
      );
    });
  });

  group('runCheckColonizethisSetupTestMirrorsLib', () {
    test('passes on the current repo tree', () {
      expect(runCheckColonizethisSetupTestMirrorsLib('.'), 0);
    });
  });
}
