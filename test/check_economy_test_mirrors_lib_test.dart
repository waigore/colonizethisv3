import 'package:test/test.dart';

import '../tool/check_economy_test_mirrors_lib.dart';

void main() {
  group('economyTestMirrorsLibPathInScope', () {
    test('positive: paths under the economy test tree are in scope', () {
      expect(
        economyTestMirrorsLibPathInScope(
          'packages/colonizethis_economy/test/economy/foo_test.dart',
        ),
        isTrue,
      );
      expect(
        economyTestMirrorsLibPathInScope(
          'packages\\colonizethis_economy\\test\\bar_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: lib sources and other packages are out of scope', () {
      expect(
        economyTestMirrorsLibPathInScope(
          'packages/colonizethis_economy/lib/src/economy/foo.dart',
        ),
        isFalse,
      );
      expect(
        economyTestMirrorsLibPathInScope(
          'packages/colonizethis_diplomacy/test/foo_test.dart',
        ),
        isFalse,
      );
    });
  });

  group('economyTestMirrorsLibViolationReason', () {
    test('positive: a flat-root test file is flagged', () {
      final reason = economyTestMirrorsLibViolationReason(
        'packages/colonizethis_economy/test/trade_counsel_test.dart',
      );
      expect(reason, isNotNull);
      expect(reason, contains('test/economy/'));
    });

    test('negative: a nested test file under test/economy/ is allowed', () {
      final reason = economyTestMirrorsLibViolationReason(
        'packages/colonizethis_economy/test/economy/trade_counsel_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: a nested world_market test file is allowed', () {
      final reason = economyTestMirrorsLibViolationReason(
        'packages/colonizethis_economy/test/economy/world_market/foo_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: files outside the economy test tree are ignored', () {
      expect(
        economyTestMirrorsLibViolationReason(
          'packages/colonizethis_orders/test/foo_test.dart',
        ),
        isNull,
      );
    });
  });

  group('runCheckEconomyTestMirrorsLib', () {
    test('passes on the current repo tree', () {
      expect(runCheckEconomyTestMirrorsLib('.'), 0);
    });
  });
}
