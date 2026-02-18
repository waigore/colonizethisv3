/// Tech ids and extraction cap. SPEC/game/tech-and-extraction-cap.md.
///
/// Phase 2 used only a constant cap; Phase 5 derives the cap from techUnlocked
/// when possible, with a constant fallback.

/// All tech ids (same for every player). Used for tech table keys.
const List<String> techIds = [
  'road_construction',   // improved roads (transport level 2)
  'early_steam_engine',  // railroad (transport level 4)
  'gathering_1',        // extraction cap 2
  'gathering_2',        // extraction cap 3
  'gathering_3',        // extraction cap 4
];

/// Default max effective extraction level when player has no tech or no extraction-cap tech.
/// Imperialism II: production level 0-4; tech caps effective level.
const int defaultExtractionCap = 4;

/// Simple tech definition used by the MVP tech catalog.
class TechDefinition {
  const TechDefinition({
    required this.id,
    required this.era,
    required this.category,
    required this.cost,
    this.prerequisiteIds = const [],
  });

  final String id;
  final int era;
  final String category;
  final int cost;
  final List<String> prerequisiteIds;
}

/// Minimal tech catalog backing extraction and research for Phase 5.
///
/// The full catalog is described in SPEC/game/tech-tree-catalog.md; this
/// structure is a program-level representation.
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
};

TechDefinition? techById(String id) => techCatalog[id];

/// Simple extraction-cap mapping for the Phase 5 MVP. In the full model the
/// cap is per resource; here we keep a single scalar cap derived from
/// "gathering" techs:
/// - gathering_1 => cap 2
/// - gathering_2 => cap 3
/// - gathering_3 => cap 4
///
/// When no gathering tech is unlocked, [defaultExtractionCap] is used.
int extractionCapForUnlocked(Map<String, bool>? techUnlocked) {
  if (techUnlocked == null || techUnlocked.isEmpty) {
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
  if (cap <= 0) {
    return defaultExtractionCap;
  }
  return cap;
}
