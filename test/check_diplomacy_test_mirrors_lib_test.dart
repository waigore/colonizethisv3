import 'package:test/test.dart';

import '../tool/check_diplomacy_test_mirrors_lib.dart';

void main() {
  group('diplomacyTestMirrorsLibPathInScope', () {
    test('positive: paths under the diplomacy test tree are in scope', () {
      expect(
        diplomacyTestMirrorsLibPathInScope(
          'packages/colonizethis_diplomacy/test/diplomacy/foo_test.dart',
        ),
        isTrue,
      );
      expect(
        diplomacyTestMirrorsLibPathInScope(
          'packages\\colonizethis_diplomacy\\test\\bar_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: lib sources and other packages are out of scope', () {
      expect(
        diplomacyTestMirrorsLibPathInScope(
          'packages/colonizethis_diplomacy/lib/src/diplomacy/foo.dart',
        ),
        isFalse,
      );
      expect(
        diplomacyTestMirrorsLibPathInScope(
          'packages/colonizethis_combat/test/foo_test.dart',
        ),
        isFalse,
      );
    });
  });

  group('diplomacyTestMirrorsLibViolationReason', () {
    test('positive: a flat-root test file is flagged', () {
      final reason = diplomacyTestMirrorsLibViolationReason(
        'packages/colonizethis_diplomacy/test/diplomacy_ftp_resolver_test.dart',
      );
      expect(reason, isNotNull);
      expect(reason, contains('test/diplomacy/'));
    });

    test('positive: a flat-root support helper is flagged', () {
      final reason = diplomacyTestMirrorsLibViolationReason(
        'packages/colonizethis_diplomacy/test/test_fixtures.dart',
      );
      expect(reason, isNotNull);
    });

    test('positive: backslash-separated flat-root path is flagged', () {
      final reason = diplomacyTestMirrorsLibViolationReason(
        'packages\\colonizethis_diplomacy\\test\\diplomacy_ftp_resolver_test.dart',
      );
      expect(reason, isNotNull);
    });

    test('negative: a nested test file under test/diplomacy/ is allowed', () {
      final reason = diplomacyTestMirrorsLibViolationReason(
        'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_ftp_resolver_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: a nested test file under test/dossier/ is allowed', () {
      final reason = diplomacyTestMirrorsLibViolationReason(
        'packages/colonizethis_diplomacy/test/dossier/event_dialogue_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: a deeply nested support file is allowed', () {
      final reason = diplomacyTestMirrorsLibViolationReason(
        'packages/colonizethis_diplomacy/test/support/call_to_arms_fixtures.dart',
      );
      expect(reason, isNull);
    });

    test('negative: files outside the diplomacy test tree are ignored', () {
      expect(
        diplomacyTestMirrorsLibViolationReason(
          'packages/colonizethis_orders/test/foo_test.dart',
        ),
        isNull,
      );
      expect(
        diplomacyTestMirrorsLibViolationReason(
          'packages/colonizethis_diplomacy/lib/src/diplomacy/ftp_resolver.dart',
        ),
        isNull,
      );
    });
  });

  group('runCheckDiplomacyTestMirrorsLib', () {
    test('passes on the current repo tree', () {
      expect(runCheckDiplomacyTestMirrorsLib('.'), 0);
    });
  });
}
