// Refs #3825 — guards `repo.diplomacy_test_inline_game_ctor` enforcement.

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

    test('fails when a mandated test file constructs Game inline', () {
      expect(
        diplomacyTestInlineGameCtorViolationReason(
          'packages/colonizethis_diplomacy/test/diplomacy/gp_tribe_first_contact_test.dart',
          "Game _bad() => Game(id: 'g');",
        ),
        isNotNull,
      );
      expect(
        diplomacyTestInlineGameCtorViolationReason(
          'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_ftp_resolver_test.dart',
          "final game = Game(id: 'g');",
        ),
        isNotNull,
      );
      expect(
        diplomacyTestInlineGameCtorViolationReason(
          'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_resolver_history_test.dart',
          "final game = Game(id: 'g');",
        ),
        isNotNull,
      );
      expect(
        diplomacyTestInlineGameCtorViolationReason(
          'packages/colonizethis_diplomacy/test/diplomacy/alliance_break_cooldown_test.dart',
          "final game = Game(id: 'g');",
        ),
        isNotNull,
      );
      expect(
        diplomacyTestInlineGameCtorViolationReason(
          'packages/colonizethis_diplomacy/test/diplomacy/boycott_resolver_test.dart',
          "final game = Game(id: 'g');",
        ),
        isNotNull,
      );
    });
  });
}
