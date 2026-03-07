/// Tech ids and extraction cap. SPEC/game/tech-and-extraction-cap.md.
///
/// Phase 2 used only a constant cap; Phase 5 derives the cap from techUnlocked
/// when possible, with a constant fallback.

import 'combat_config.dart';

/// All tech ids (same for every player). Used for tech table keys.
const List<String> techIds = [
  'road_construction',
  'early_steam_engine',
  'gathering_1',
  'gathering_2',
  'gathering_3',
  'mine_engineering',
  'organised_regiments',
  'improved_iron_weapons',
  'improved_infantry_tactics',
  'weapon_craftsmanship',
  'recruit_steppe_horsemen',
  'horse_artillery',
  'siege_engineering',
  'university',
];

/// Default max effective extraction level when player has no tech or no extraction-cap tech.
/// Imperialism II: production level 0-4; tech caps effective level.
const int defaultExtractionCap = 4;

/// Simple tech definition used by the MVP tech catalog.
/// Effects: regimentUnlockIds / shipUnlockIds = unit types this tech unlocks (buildability).
class TechDefinition {
  const TechDefinition({
    required this.id,
    required this.era,
    required this.category,
    required this.cost,
    this.prerequisiteIds = const [],
    this.regimentUnlockIds = const [],
    this.shipUnlockIds = const [],
  });

  final String id;
  final int era;
  final String category;
  final int cost;
  final List<String> prerequisiteIds;
  /// Regiment ids this tech unlocks. SPEC/game/tech-tree-military.md.
  final List<String> regimentUnlockIds;
  /// Ship type ids this tech unlocks. SPEC/game/tech-tree-naval.md.
  final List<String> shipUnlockIds;
}

/// Minimal tech catalog backing extraction and research for Phase 5.
///
/// The full catalog is defined in SPEC/game/tech-tree.md and category sub-docs
/// (e.g. SPEC/game/tech-tree-gathering.md); this structure is a program-level
/// representation.
const Map<String, TechDefinition> techCatalog = {
  'road_construction': TechDefinition(
    id: 'road_construction',
    era: 1,
    category: 'transport',
    cost: 100,
  ),
  'early_steam_engine': TechDefinition(
    id: 'early_steam_engine',
    era: 4,
    category: 'transport',
    cost: 200,
    prerequisiteIds: ['road_construction'],
  ),
  'gathering_1': TechDefinition(
    id: 'gathering_1',
    era: 1,
    category: 'gathering',
    cost: 80,
  ),
  'gathering_2': TechDefinition(
    id: 'gathering_2',
    era: 2,
    category: 'gathering',
    cost: 120,
    prerequisiteIds: ['gathering_1'],
  ),
  'gathering_3': TechDefinition(
    id: 'gathering_3',
    era: 3,
    category: 'gathering',
    cost: 160,
    prerequisiteIds: ['gathering_2'],
  ),
  // SPEC/game/tech-tree-gathering.md. Fort level 2 prerequisite per siege-mechanics.md.
  'mine_engineering': TechDefinition(
    id: 'mine_engineering',
    era: 1,
    category: 'gathering',
    cost: 80,
  ),
  // Military (SPEC/game/tech-tree-military.md). Prereqs simplified for MVP.
  'organised_regiments': TechDefinition(
    id: 'organised_regiments',
    era: 1,
    category: 'military',
    cost: 100,
    regimentUnlockIds: ['lancers'],
  ),
  'improved_iron_weapons': TechDefinition(
    id: 'improved_iron_weapons',
    era: 1,
    category: 'military',
    cost: 100,
    prerequisiteIds: ['organised_regiments'],
    regimentUnlockIds: ['halberdiers'],
  ),
  'improved_infantry_tactics': TechDefinition(
    id: 'improved_infantry_tactics',
    era: 2,
    category: 'military',
    cost: 120,
    prerequisiteIds: ['organised_regiments'],
    regimentUnlockIds: ['calivermen'],
  ),
  'weapon_craftsmanship': TechDefinition(
    id: 'weapon_craftsmanship',
    era: 2,
    category: 'military',
    cost: 120,
    prerequisiteIds: ['organised_regiments'],
    regimentUnlockIds: ['musketeers'],
  ),
  'recruit_steppe_horsemen': TechDefinition(
    id: 'recruit_steppe_horsemen',
    era: 1,
    category: 'military',
    cost: 100,
    regimentUnlockIds: ['cossacks'],
  ),
  'horse_artillery': TechDefinition(
    id: 'horse_artillery',
    era: 1,
    category: 'military',
    cost: 100,
    regimentUnlockIds: ['horse_artillery'],
  ),
  'siege_engineering': TechDefinition(
    id: 'siege_engineering',
    era: 2,
    category: 'military',
    cost: 120,
    regimentUnlockIds: ['royal_artillery'],
  ),
  'modern_forts': TechDefinition(
    id: 'modern_forts',
    era: 3,
    category: 'military',
    cost: 160,
    prerequisiteIds: ['siege_engineering', 'university'],
  ),
  // Labour/economy (SPEC/game/tech-tree-labour-economy.md). University grants 4th research slot.
  'university': TechDefinition(
    id: 'university',
    era: 3,
    category: 'labour',
    cost: 200,
    prerequisiteIds: const [],
  ),
  // Naval (SPEC/game/tech-tree-naval.md). Fluytes require Superior Hull Design; carrack is baseline (no tech).
  'superior_hull_design': TechDefinition(
    id: 'superior_hull_design',
    era: 1,
    category: 'naval',
    cost: 100,
    shipUnlockIds: ['fluyte'],
  ),
};

TechDefinition? techById(String id) => techCatalog[id];

/// Simple extraction-cap mapping for the Phase 5 MVP. In the full model the
/// cap is per resource; here we keep a single scalar cap derived from
/// "gathering" techs:
/// - gathering_1 => cap 2
/// - gathering_2 => cap 3
/// - gathering_3 => cap 4
///
/// When no gathering tech is unlocked (null, empty, or only non-gathering techs),
/// [defaultExtractionCap] is used per SPEC/game/tech-and-extraction-cap.md.
int extractionCapForUnlocked(Map<String, bool>? techUnlocked) {
  if (techUnlocked == null || techUnlocked.isEmpty) {
    return defaultExtractionCap;
  }
  final hasGathering = techUnlocked['gathering_1'] == true ||
      techUnlocked['gathering_2'] == true ||
      techUnlocked['gathering_3'] == true;
  if (!hasGathering) {
    return defaultExtractionCap;
  }
  var cap = 1;
  if (techUnlocked['gathering_1'] == true) {
    cap = cap < 2 ? 2 : cap;
  }
  if (techUnlocked['gathering_2'] == true) {
    cap = cap < 3 ? 3 : cap;
  }
  if (techUnlocked['gathering_3'] == true) {
    cap = cap < 4 ? 4 : cap;
  }
  return cap;
}

/// Regiment id -> tech id that unlocks it. Derived from catalog. Absent = buildable without tech.
/// SPEC/game/tech-tree-military.md.
Map<String, String> get unlockingTechByRegimentId {
  final m = <String, String>{};
  for (final t in techCatalog.values) {
    for (final rid in t.regimentUnlockIds) {
      m[rid] = t.id;
    }
  }
  return m;
}

/// Ship type id -> tech id that unlocks it. Derived from catalog. Absent = buildable without tech (e.g. carrack).
/// SPEC/game/tech-tree-naval.md.
Map<String, String> get unlockingTechByShipId {
  final m = <String, String>{};
  for (final t in techCatalog.values) {
    for (final sid in t.shipUnlockIds) {
      m[sid] = t.id;
    }
  }
  return m;
}

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
