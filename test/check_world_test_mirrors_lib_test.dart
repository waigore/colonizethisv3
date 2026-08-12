import 'package:test/test.dart';

import '../tool/check_world_test_mirrors_lib.dart';

void main() {
  group('worldTestMirrorsLibPathInScope', () {
    test('positive: paths under the world test tree are in scope', () {
      expect(
        worldTestMirrorsLibPathInScope(
          'packages/colonizethis_world/test/world/foo_test.dart',
        ),
        isTrue,
      );
      expect(
        worldTestMirrorsLibPathInScope(
          'packages\\colonizethis_world\\test\\bar_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: lib sources and other packages are out of scope', () {
      expect(
        worldTestMirrorsLibPathInScope(
          'packages/colonizethis_world/lib/src/world/foo.dart',
        ),
        isFalse,
      );
      expect(
        worldTestMirrorsLibPathInScope(
          'packages/colonizethis_economy/test/foo_test.dart',
        ),
        isFalse,
      );
    });
  });

  group('worldTestMirrorsLibViolationReason', () {
    test('positive: a flat-root test file is flagged', () {
      final reason = worldTestMirrorsLibViolationReason(
        'packages/colonizethis_world/test/topology_helpers_test.dart',
      );
      expect(reason, isNotNull);
      expect(reason, contains('test/world/'));
    });

    test('positive: backslash-separated flat-root path is flagged', () {
      final reason = worldTestMirrorsLibViolationReason(
        'packages\\colonizethis_world\\test\\naval_coastal_visibility_test.dart',
      );
      expect(reason, isNotNull);
    });

    test('negative: a nested test file under test/world/ is allowed', () {
      final reason = worldTestMirrorsLibViolationReason(
        'packages/colonizethis_world/test/world/topology_helpers_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: nested trace and support trees are allowed', () {
      expect(
        worldTestMirrorsLibViolationReason(
          'packages/colonizethis_world/test/trace/turn_trace_schema_validation_test.dart',
        ),
        isNull,
      );
      expect(
        worldTestMirrorsLibViolationReason(
          'packages/colonizethis_world/test/world_test_support/capital_builders.dart',
        ),
        isNull,
      );
    });

    test('negative: files outside the world test tree are ignored', () {
      expect(
        worldTestMirrorsLibViolationReason(
          'packages/colonizethis_orders/test/foo_test.dart',
        ),
        isNull,
      );
    });
  });
}
