import 'package:test/test.dart';

import '../tool/check_combat_test_duplicate_descriptions.dart';

void main() {
  group('findCombatTestDuplicateDescriptions', () {
    test('returns empty when descriptions are unique per file', () {
      final violations = findCombatTestDuplicateDescriptions(
        sourcesByPath: {
          'packages/colonizethis_combat/test/a_test.dart':
              "test('only in a', () {});",
          'packages/colonizethis_combat/test/b_test.dart':
              "test('only in b', () {});",
        },
      );
      expect(violations, isEmpty);
    });

    test('flags the same description in two files', () {
      final violations = findCombatTestDuplicateDescriptions(
        sourcesByPath: {
          'packages/colonizethis_combat/test/a_test.dart':
              "test('dup', () {});",
          'packages/colonizethis_combat/test/b_test.dart':
              "test('dup', () {});",
        },
      );
      expect(violations, hasLength(1));
      expect(violations.single.description, 'dup');
    });
  });

  group('runCheckCombatTestDuplicateDescriptions', () {
    test('passes on the current repo tree', () {
      expect(runCheckCombatTestDuplicateDescriptions('.'), 0);
    });
  });
}
