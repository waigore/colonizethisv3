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

/// Default max effective extraction level for a resource with no cap-raising tech unlocked.
/// This allows base level-1 extraction while requiring tech for upgrades.
const int defaultExtractionCap = 1;

/// Resource-specific extraction cap tech map.
/// resource id -> (tech id -> max extraction level for that resource).
const Map<String, Map<String, int>> _extractionCapByResourceByTechId = {
  'grain': {'land_enclosure': 2, 'seed_drill': 3, 'moldboard_plow': 4},
  'timber': {'saw_mill': 2, 'wind_saw_mill': 3, 'circular_saw': 4},
  'iron': {'iron_mining': 2, 'steam_in_mining': 3, 'industrial_iron_mining': 4},
  'copper': {
    'copper_and_tin_mining': 2,
    'large_copper_and_tin_mines': 3,
    'efficient_extraction_of_copper_and_tin': 4,
  },
  'tin': {
    'copper_and_tin_mining': 2,
    'large_copper_and_tin_mines': 3,
    'efficient_extraction_of_copper_and_tin': 4,
  },
  'coal': {
    'coal_mining': 1,
    'square_set_timbering': 2,
    'large_coal_mines': 3,
    'safety_lamp': 4,
  },
  'wool': {'sheep_ranching': 2, 'scientific_sheep_breeding': 3},
  'meat': {'animal_husbandry': 3, 'scientific_cattle_breeding': 4},
  'sugarCane': {
    'sugar_planting': 2,
    'large_sugar_plantations': 3,
    'sugar_industry': 4,
  },
  'tobacco': {
    'tobacco_planting': 2,
    'large_tobacco_plantations': 3,
    'tobacco_industry': 4,
  },
  'cotton': {
    'cotton_planting': 2,
    'large_cotton_plantations': 3,
    'cotton_gin': 4,
  },
  'furs': {
    'improved_trapping_techniques': 2,
    'riverboats': 3,
    'excessive_fur_harvesting': 4,
  },
  'spices': {
    'improved_sea_routes': 2,
    'large_spice_plantations': 3,
    'improved_food_preservation': 4,
  },
  'silver': {
    'precious_metals_mining': 2,
    'extraction_of_precious_metals': 3,
    'amalgamation_process': 4,
  },
  'gold': {
    'precious_metals_mining': 2,
    'extraction_of_precious_metals': 3,
    'amalgamation_process': 4,
  },
  'gems': {
    'precious_stone_mining': 2,
    'large_precious_stone_mines': 3,
    'geological_prospecting': 4,
  },
  'diamonds': {
    'precious_stone_mining': 2,
    'large_precious_stone_mines': 3,
    'geological_prospecting': 4,
  },
};

/// Resources intentionally capped below level 4 by design.
/// Keep in sync with SPEC/game/tech-and-extraction-cap.md.
const Map<String, int> extractionCapDesignExceptions = {'horses': 1, 'wool': 3};

/// All tech ids that raise an extraction cap for at least one resource.
/// Derived from [_extractionCapByResourceByTechId] so callers (e.g. the catalog
/// effect-or-prerequisite audit) do not duplicate the extraction-cap data.
/// SPEC/game/tech-and-extraction-cap.md.
Set<String> get extractionCapTechIds => {
  for (final byTech in _extractionCapByResourceByTechId.values) ...byTech.keys,
};

/// Tech catalog category used for Envy hidden-agenda mirror scoring when a player
/// completes an extraction [build_improvement] on a tile whose [resourceId] is in
/// the extraction-cap map. All such improvements map to **gathering** (tech tree).
/// Returns null when the tile has no extraction resource or an unlisted resource.
String? envyMirrorTechCategoryForExtractionResource(String? resourceId) {
  if (resourceId == null || resourceId.isEmpty) {
    return null;
  }
  if (!_extractionCapByResourceByTechId.containsKey(resourceId)) {
    return null;
  }
  return 'gathering';
}

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
      .map(
        (s) => s.isEmpty
            ? s
            : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}',
      )
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
    final allPrereqsMet = tech.prerequisiteIds.every(
      (p) => unlocked[p] == true,
    );
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

/// Resource-specific extraction cap from gathering/new-world tech progression.
/// Returns max cap unlocked for [resourceId], or [defaultExtractionCap] when no cap tech is unlocked.
int extractionCapForResourceForUnlocked(
  Map<String, bool>? techUnlocked,
  String resourceId,
) {
  final unlocked = techUnlocked ?? const <String, bool>{};
  final perTech = _extractionCapByResourceByTechId[resourceId];
  if (perTech == null || perTech.isEmpty) {
    return extractionCapDesignExceptions[resourceId] ?? defaultExtractionCap;
  }
  var cap = 0;
  for (final e in perTech.entries) {
    if (unlocked[e.key] == true && e.value > cap) {
      cap = e.value;
    }
  }
  return cap > 0 ? cap : defaultExtractionCap;
}

/// Legacy scalar extraction cap (max across all resources).
/// Maintained for backward compatibility in callsites/tests that still use a scalar.
int extractionCapForUnlocked(Map<String, bool>? techUnlocked) {
  var cap = defaultExtractionCap;
  for (final resourceId in _extractionCapByResourceByTechId.keys) {
    final resourceCap = extractionCapForResourceForUnlocked(
      techUnlocked,
      resourceId,
    );
    if (resourceCap > cap) {
      cap = resourceCap;
    }
  }
  for (final e in extractionCapDesignExceptions.entries) {
    if (e.value > cap) {
      cap = e.value;
    }
  }
  return cap;
}

void _validateExtractionCapProgression() {
  const upgradeableResources = <String>{
    'grain',
    'meat',
    'wool',
    'horses',
    'timber',
    'iron',
    'copper',
    'tin',
    'coal',
    'sugarCane',
    'tobacco',
    'cotton',
    'furs',
    'spices',
    'silver',
    'gold',
    'gems',
    'diamonds',
  };
  for (final resourceId in upgradeableResources) {
    final explicitCap = extractionCapDesignExceptions[resourceId];
    if (explicitCap != null) {
      if (explicitCap < 1 || explicitCap > 4) {
        throw StateError(
          'Invalid design exception cap for $resourceId: $explicitCap',
        );
      }
      continue;
    }
    final perTech = _extractionCapByResourceByTechId[resourceId] ?? const {};
    final maxCap = perTech.values.fold<int>(
      defaultExtractionCap,
      (acc, value) => value > acc ? value : acc,
    );
    if (maxCap < 4) {
      throw StateError(
        'Extraction cap progression for $resourceId does not reach level 4 '
        'and has no declared design exception.',
      );
    }
  }
}

final bool _extractionCapCatalogValidated = (() {
  _validateExtractionCapProgression();
  return true;
})();

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
