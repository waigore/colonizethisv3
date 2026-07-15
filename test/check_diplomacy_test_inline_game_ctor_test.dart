// Refs #3825 / #4028 — guards `repo.diplomacy_test_inline_game_ctor` enforcement.

import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_diplomacy_test_inline_game_ctor.dart';

void main() {
  group('repo.diplomacy_test_inline_game_ctor', () {
    test('passes on real repo workspace', () {
      final exitCode = runCheckDiplomacyTestInlineGameCtor(
        Directory.current.path,
        info: (_) {},
      );
      expect(exitCode, 0);
    });

    test('scopes all diplomacy package tests (exceptions-only allowlist)', () {
      expect(
        diplomacyTestInlineGameCtorPathInScope(
          'packages/colonizethis_diplomacy/test/diplomacy/gp_tribe_first_contact_test.dart',
        ),
        isTrue,
      );
      expect(
        diplomacyTestInlineGameCtorPathInScope(
          'packages/colonizethis_diplomacy/test/diplomacy/faction_absorption_engine_test.dart',
        ),
        isTrue,
      );
      expect(
        diplomacyTestInlineGameCtorPathInScope(
          'packages/colonizethis_diplomacy/test/diplomacy/brand_new_suite_test.dart',
        ),
        isTrue,
      );
      expect(
        diplomacyTestInlineGameCtorPathInScope(
          'packages/colonizethis_economy/test/economy/foo_test.dart',
        ),
        isFalse,
      );
      expect(
        diplomacyTestInlineGameCtorPathInScope(
          'packages/colonizethis_diplomacy/lib/src/diplomacy/war_resolver.dart',
        ),
        isFalse,
      );
    });

    test('fails when any in-scope test file constructs Game inline', () {
      expect(
        diplomacyTestInlineGameCtorViolationReason(
          'packages/colonizethis_diplomacy/test/diplomacy/gp_tribe_first_contact_test.dart',
          "Game _bad() => Game(id: 'g');",
        ),
        isNotNull,
      );
      expect(
        diplomacyTestInlineGameCtorViolationReason(
          'packages/colonizethis_diplomacy/test/diplomacy/faction_absorption_engine_test.dart',
          "final game = Game(id: 'g');",
        ),
        isNotNull,
      );
      expect(
        diplomacyTestInlineGameCtorViolationReason(
          'packages/colonizethis_diplomacy/test/diplomacy/brand_new_suite_test.dart',
          "final game = Game(id: 'g');",
        ),
        isNotNull,
      );
    });
  });
}
