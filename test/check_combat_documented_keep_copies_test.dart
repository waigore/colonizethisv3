import 'package:test/test.dart';

import '../tool/check_combat_documented_keep_copies.dart';

void main() {
  group('findCombatUndocumentedKeepCopies', () {
    const economyPath =
        'packages/colonizethis_combat/lib/src/combat/military_attack_economy.dart';

    test('flags a keep-copy site missing the copy-disposition marker', () {
      const src = r'''
players = List<Player>.from(players);
players[idx] = players[idx].copyWith(treasury: nextTreasury);
''';
      final violations = findCombatUndocumentedKeepCopies(
        relativePath: economyPath,
        expressionLabel: 'List<Player>.from(...)',
        expressionPattern: r'\bList<\s*Player\s*>\.from\(',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('copy-disposition'));
    });

    test('accepts a keep-copy site documented with the marker', () {
      const src = r'''
// Keep (copy-disposition, Refs #3448 AC5): copy-on-write before update.
players = List<Player>.from(players);
''';
      final violations = findCombatUndocumentedKeepCopies(
        relativePath: economyPath,
        expressionLabel: 'List<Player>.from(...)',
        expressionPattern: r'\bList<\s*Player\s*>\.from\(',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a file without the keep-copy expression', () {
      const src = r'''
final players = game.players;
return game.withPlayers(players);
''';
      final violations = findCombatUndocumentedKeepCopies(
        relativePath: economyPath,
        expressionLabel: 'List<Player>.from(...)',
        expressionPattern: r'\bList<\s*Player\s*>\.from\(',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('ignores the expression when it only appears in a comment', () {
      const src = r'''
// Historically this used List<Player>.from(players) without rationale.
final players = game.players;
''';
      final violations = findCombatUndocumentedKeepCopies(
        relativePath: economyPath,
        expressionLabel: 'List<Player>.from(...)',
        expressionPattern: r'\bList<\s*Player\s*>\.from\(',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });

  group('runCheckCombatDocumentedKeepCopies', () {
    test('passes on the live repository tree', () {
      final logs = <String>[];
      final code = runCheckCombatDocumentedKeepCopies(
        '.',
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
