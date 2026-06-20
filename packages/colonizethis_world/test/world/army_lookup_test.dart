import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/army_lookup.dart';
import 'package:colonizethis_test/test.dart';

/// Unit coverage for the consolidated single-lookup army-by-id helper
/// (`lib/src/world/army_lookup.dart`, Refs #3544 C6). Replaces the per-file
/// `findArmy` closure and `_armyById` scan that previously lived in
/// `army_migration.dart` / `army_migration_relocation.dart`.
Army _army(String id) => Army(
  id: id,
  ownerId: 'p1',
  regionId: 'oldWorld',
  stationedProvinceId: 'oldWorld|p1',
  regimentUnitIds: const [],
);

void main() {
  group('firstArmyById', () {
    test('returns the matching army when present', () {
      final a = _army('army_a');
      final b = _army('army_b');
      expect(firstArmyById([a, b], 'army_b'), same(b));
    });

    test('returns null when no army matches (negative)', () {
      expect(firstArmyById([_army('army_a')], 'army_missing'), isNull);
    });

    test('returns null for an empty list (negative)', () {
      expect(firstArmyById(const <Army>[], 'army_a'), isNull);
    });

    test('returns the first match on duplicate ids (indexWhere semantics)', () {
      final first = _army('dup');
      final second = _army('dup');
      expect(firstArmyById([first, second], 'dup'), same(first));
    });
  });
}
