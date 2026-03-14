/// Tech ids and extraction cap. SPEC/game/tech-and-extraction-cap.md.
///
/// Full catalog (113 techs) from SPEC/game/tech-tree.md and category sub-docs.

import 'combat_config.dart';
import 'tech_catalog.dart';
import 'tech_definition.dart';

/// Full tech catalog (113 techs). Built from [buildTechCatalog].
final Map<String, TechDefinition> techCatalog = buildTechCatalog();

/// All tech ids (same for every player). Order = catalog insertion order.
final List<String> techIds = techCatalog.keys.toList();

/// Default max effective extraction level when player has no tech or no extraction-cap tech.
/// Imperialism II: production level 0-4; tech caps effective level.
const int defaultExtractionCap = 4;

/// Gathering and new-world techs that grant an extraction cap level. MVP: single scalar = max of these.
/// SPEC/game/tech-tree-gathering.md, tech-tree-new-world.md.
const Map<String, int> _extractionCapByTechId = {
  'saw_mill': 2,
  'land_enclosure': 2,
  'iron_mining': 2,
  'copper_and_tin_mining': 2,
  'coal_mining': 1,
  'wind_saw_mill': 3,
  'seed_drill': 3,
  'sheep_ranching': 2,
  'animal_husbandry': 3,
  'square_set_timbering': 2,
  'steam_in_mining': 3,
  'large_coal_mines': 3,
  'large_copper_and_tin_mines': 3,
  'circular_saw': 4,
  'scientific_sheep_breeding': 3,
  'scientific_cattle_breeding': 4,
  'moldboard_plow': 4,
  'safety_lamp': 4,
  'large_precious_stone_mines': 3,
  'extraction_of_precious_metals': 3,
  'geological_prospecting': 4,
  'amalgamation_process': 4,
  'industrial_iron_mining': 4,
  'efficient_extraction_of_copper_and_tin': 4,
  'sugar_planting': 2,
  'large_sugar_plantations': 3,
  'sugar_industry': 4,
  'tobacco_planting': 2,
  'large_tobacco_plantations': 3,
  'tobacco_industry': 4,
  'cotton_planting': 2,
  'large_cotton_plantations': 3,
  'cotton_gin': 4,
  'improved_trapping_techniques': 2,
  'riverboats': 3,
  'excessive_fur_harvesting': 4,
  'large_spice_plantations': 3,
  'improved_food_preservation': 4,
  'precious_metals_mining': 2,
  'precious_stone_mining': 2,
};

TechDefinition? techById(String id) => techCatalog[id];

/// Humanized display name for a tech id. Uses catalog displayName when set; otherwise
/// title-case of id (e.g. road_construction → "Road Construction"). SPEC/ui/tech-tree-widget.md.
String techDisplayName(String id) {
  if (id.isEmpty) return id;
  final def = techCatalog[id];
  if (def?.displayName != null && def!.displayName!.isNotEmpty) {
    return def.displayName!;
  }
  return id
      .split('_')
      .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}')
      .join(' ');
}

/// Tech ids that the player can research next (all prerequisites in [techUnlocked], tech not yet unlocked).
/// When [hasDiscoveredResource] is null, discovery techs are treated as researchable (tests/contexts without game).
/// When provided, techs with [TechDefinition.discoveryResourceIds] are included only if
/// [hasDiscoveredResource](r) is true for at least one r in that list. SPEC/game/research-state.md.
Set<String> researchableTechIds(
  Map<String, bool>? techUnlocked, {
  bool Function(String resourceId)? hasDiscoveredResource,
}) {
  final unlocked = techUnlocked ?? const {};
  final result = <String>{};
  for (final tech in techCatalog.values) {
    if (unlocked[tech.id] == true) continue;
    final allPrereqsMet = tech.prerequisiteIds.every((p) => unlocked[p] == true);
    if (!allPrereqsMet) continue;
    final discoveryIds = tech.discoveryResourceIds;
    if (discoveryIds != null && discoveryIds.isNotEmpty) {
      if (hasDiscoveredResource == null) {
        result.add(tech.id);
        continue;
      }
      final anyDiscovered = discoveryIds.any((r) => hasDiscoveredResource(r));
      if (anyDiscovered) result.add(tech.id);
    } else {
      result.add(tech.id);
    }
  }
  return result;
}

/// Single scalar extraction cap from full gathering/new-world tech set.
/// Max level among [_extractionCapByTechId] for unlocked techs; [defaultExtractionCap] when none.
/// SPEC/game/tech-and-extraction-cap.md.
int extractionCapForUnlocked(Map<String, bool>? techUnlocked) {
  if (techUnlocked == null || techUnlocked.isEmpty) {
    return defaultExtractionCap;
  }
  var cap = 0;
  for (final e in _extractionCapByTechId.entries) {
    if (techUnlocked[e.key] == true && e.value > cap) {
      cap = e.value;
    }
  }
  return cap > 0 ? cap : defaultExtractionCap;
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
