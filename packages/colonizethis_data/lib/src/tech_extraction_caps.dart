/// Resource-specific extraction cap table and terrain clamps.
/// SPEC/game/tech-and-extraction-cap.md, SPEC/game/extraction-and-improvements.md.

import 'resource.dart';
import 'tech_extraction_caps_nw.dart';
import 'tech_extraction_caps_ow_food.dart';
import 'tech_extraction_caps_precious.dart';
import 'tech_extraction_caps_timber_minerals.dart';
import 'terrain_type.dart';

/// Default max effective extraction level for a resource with no cap-raising tech unlocked.
/// This allows base level-1 extraction while requiring tech for upgrades.
const int defaultExtractionCap = 1;

/// Resources intentionally capped below level 4 by design.
/// Keep in sync with SPEC/game/tech-and-extraction-cap.md.
final Map<String, int> extractionCapDesignExceptions = {
  Resource.horses.name: 1,
  Resource.wool.name: 3,
};

/// Resource-specific extraction cap tech map.
/// resource id -> (tech id -> max extraction level for that resource).
final Map<String, Map<String, int>> _extractionCapByResourceByTechId =
    _validatedExtractionCapTable({
      ...extractionCapTableOwFoodFibre,
      ...extractionCapTableTimberMinerals,
      ...extractionCapTableNwPlantationHarvest,
      ...extractionCapTablePrecious,
    });

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

/// Hard cap that [terrain] imposes on extraction of [resourceId], independent
/// of unlocked gathering tech. **Scrub forest** hard-caps `timber` at level 1
/// regardless of `saw_mill`/`wind_saw_mill`/`circular_saw` (R4, issue #3573;
/// SPEC/game/extraction-and-improvements.md § Scrub forest timber cap).
/// Returns `null` when the terrain imposes no special cap, in which case the
/// normal tech progression ([extractionCapForResourceForUnlocked]) applies.
int? terrainExtractionHardCap(String resourceId, TerrainType terrain) {
  if (terrain == TerrainType.scrubForest &&
      resourceId == Resource.timber.name) {
    return 1;
  }
  return null;
}

/// Clamps an already-computed [techCap] for [resourceId] down to any hard cap
/// that [terrain] imposes ([terrainExtractionHardCap]). Use this from extraction
/// paths that already resolved the tech cap (e.g. the per-tile extraction
/// pipeline) so the terrain cap composes without recomputing tech progression.
int clampExtractionCapForTerrain(
  int techCap,
  String resourceId,
  TerrainType terrain,
) {
  final hardCap = terrainExtractionHardCap(resourceId, terrain);
  if (hardCap == null || techCap <= hardCap) {
    return techCap;
  }
  return hardCap;
}

/// Extraction cap for [resourceId] on a tile of [terrain] given [techUnlocked].
/// Applies the normal tech-progression cap ([extractionCapForResourceForUnlocked]),
/// then clamps it to any terrain hard cap ([terrainExtractionHardCap]).
/// SPEC/game/extraction-and-improvements.md.
int extractionCapForResourceOnTerrain(
  Map<String, bool>? techUnlocked,
  String resourceId,
  TerrainType terrain,
) => clampExtractionCapForTerrain(
  extractionCapForResourceForUnlocked(techUnlocked, resourceId),
  resourceId,
  terrain,
);

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

Map<String, Map<String, int>> _validatedExtractionCapTable(
  Map<String, Map<String, int>> table,
) {
  for (final resource in Resource.values) {
    final resourceId = resource.name;
    final explicitCap = extractionCapDesignExceptions[resourceId];
    if (explicitCap != null) {
      if (explicitCap < 1 || explicitCap > 4) {
        throw StateError(
          'Invalid design exception cap for $resourceId: $explicitCap',
        );
      }
      continue;
    }
    final perTech = table[resourceId] ?? const {};
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
  return table;
}
