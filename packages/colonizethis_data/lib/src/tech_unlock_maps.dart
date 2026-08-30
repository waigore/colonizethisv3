/// Catalog-derived regiment/ship unlock maps and military-level helper.
/// SPEC/game/tech-tree-military.md, SPEC/game/tech-tree-naval.md.

import 'combat_config.dart';
import 'tech_catalog_query.dart';

Map<String, String> _buildUnlockingTechByRegimentId() {
  final m = <String, String>{};
  for (final t in techCatalog.values) {
    for (final rid in t.regimentUnlockIds) {
      m[rid] = t.id;
    }
  }
  return m;
}

Map<String, String> _buildUnlockingTechByShipId() {
  final m = <String, String>{};
  for (final t in techCatalog.values) {
    for (final sid in t.shipUnlockIds) {
      m[sid] = t.id;
    }
  }
  return m;
}

/// Regiment id -> tech id that unlocks it. Derived from catalog. Absent = buildable without tech.
/// Built once from [techCatalog]. SPEC/game/tech-tree-military.md.
final Map<String, String> unlockingTechByRegimentId =
    _buildUnlockingTechByRegimentId();

/// Ship type id -> tech id that unlocks it. Derived from catalog. Absent = buildable without tech (e.g. carrack).
/// Built once from [techCatalog]. SPEC/game/tech-tree-naval.md.
final Map<String, String> unlockingTechByShipId = _buildUnlockingTechByShipId();

/// Military level (1–4): highest era among buildable regiment types for minor parity.
/// Buildable = no entry in [unlockingTechByRegimentId] or its unlocking tech is in [techUnlocked].
int militaryLevelForUnlocked(Map<String, bool>? techUnlocked) {
  final unlockMap = unlockingTechByRegimentId;
  var maxEra = 1;
  for (final r in regimentCatalog) {
    final unlockingTech = unlockMap[r.id];
    final buildable =
        unlockingTech == null || (techUnlocked?[unlockingTech] ?? false);
    if (buildable && r.era > maxEra) {
      maxEra = r.era;
    }
  }
  return maxEra.clamp(1, 4);
}
