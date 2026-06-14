import 'package:test/test.dart';

import '../tool/check_combat_no_raw_copies_in_resolution.dart';

void main() {
  group('findCombatRawCopyViolations', () {
    test('flags a bare List.from(...) ship-list clone', () {
      const src = r'''
final side = NavalBattleSide(ownerId: a, ships: List.from(owners[a]!));
''';
      final violations = findCombatRawCopyViolations(
        relativePath:
            'packages/colonizethis_combat/lib/src/combat/naval_combat_resolver.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('copyNavalShips'));
    });

    test('flags a typed List<ShipInstance>.from(...) clone', () {
      const src = r'''
final list1 = List<ShipInstance>.from(battle.side1.ships);
''';
      final violations = findCombatRawCopyViolations(
        relativePath:
            'packages/colonizethis_combat/lib/src/combat/naval_combat_resolver.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('accepts the canonical copyNavalShips(...) delegation', () {
      const src = r'''
final list1 = copyNavalShips(battle.side1.ships);
''';
      final violations = findCombatRawCopyViolations(
        relativePath:
            'packages/colonizethis_combat/lib/src/combat/naval_combat_resolver.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a List<Fleet>.from(...) clone (non-ship collection)', () {
      const src = r'''
var fleets = List<Fleet>.from(game.worldState.fleets);
''';
      final violations = findCombatRawCopyViolations(
        relativePath:
            'packages/colonizethis_combat/lib/src/combat/naval_combat_resolver.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a comment mentioning List.from(...)', () {
      const src = r'''
/// Centralizes the defensive copy that previously used raw List.from(...).
List<ShipInstance> copyNavalShips(List<ShipInstance> ships) =>
    <ShipInstance>[...ships];
''';
      final violations = findCombatRawCopyViolations(
        relativePath:
            'packages/colonizethis_combat/lib/src/combat/naval_combat_resolver.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
