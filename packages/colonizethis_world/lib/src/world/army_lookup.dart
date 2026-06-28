import 'package:colonizethis_models/colonizethis_models.dart' show Army;

/// First [Army] in [armies] whose id equals [armyId], or `null` when none match.
///
/// Single-pass linear scan returning the first match (mirroring [List.indexWhere]
/// / [Iterable.firstWhere] semantics on duplicate ids). Avoids the
/// `.where(...).toList()` / `firstWhereOrNull` allocation on the single-lookup
/// army-migration paths (Refs #2394; SPEC/program/turn-resolution.md).
///
/// This is the one canonical single-lookup army-by-id helper, replacing the
/// per-file scan closures that previously lived in `army_migration.dart` and
/// `army_migration_relocation.dart` (Refs #3544 C6). For repeated lookups over
/// a stable [WorldState] snapshot prefer the map-based `armiesByIdForWorld`
/// index in `army_movement.dart` (O(1) per lookup) instead.
Army? firstArmyById(List<Army> armies, String armyId) {
  for (final a in armies) {
    if (a.id == armyId) return a;
  }
  return null;
}
