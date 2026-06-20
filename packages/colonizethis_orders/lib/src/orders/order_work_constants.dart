/// Order/work-domain constants for the orders domain (Refs #3290).
///
/// These work-target ids, mineral-resource ids, and prospectability helpers are
/// owned by the `orders` domain (the future `colonizethis_orders` package).
/// `lib/src/constants.dart` re-exports them so existing
/// `package:colonizethis_logic` consumers keep their import paths unchanged
/// during the package split.
library;

import 'package:colonizethis_data/colonizethis_data.dart';

/// Work target string constants for work orders. Used across order suggestion,
/// validation, and application to avoid hardcoded string literals.
const String kWorkTargetStealTech = 'steal_tech';
const String kWorkTargetCounterSpy = 'counter_spy';
const String kWorkTargetPurchaseLand = 'purchase_land';
const String kWorkTargetExplore = 'explore';
const String kWorkTargetProspect = 'prospect';
const String kWorkTargetBuildImprovement = 'build_improvement';
const String kWorkTargetBuildRoad = 'build_road';
const String kWorkTargetBuildPort = 'build_port';
const String kWorkTargetBuildFort = 'build_fort';
const String kWorkTargetBuildRail = 'build_rail';
const String kWorkTargetUpgradeTown = 'upgrade_town';

/// Work targets that skip material-cost and tech validation (treasury-only or
/// no-cost targets). Used by validators and cost calculators.
const Set<String> kWorkTargetsWithoutMaterialCost = {
  kWorkTargetStealTech,
  kWorkTargetCounterSpy,
  kWorkTargetPurchaseLand,
};

/// Work targets that skip projected material-cost deduction during validation.
/// [kWorkTargetPurchaseLand] treasury is charged on work completion instead.
const Set<String> kWorkTargetsWithoutProjectedMaterialCost = {
  kWorkTargetStealTech,
  kWorkTargetCounterSpy,
};

/// Resource ids that count as minerals for work/purchase rules.
/// Shared across extraction, work orders, and order application helpers.
const Set<String> kMineralResourceIds = {
  'iron',
  'copper',
  'tin',
  'coal',
  'silver',
  'gold',
  'gems',
  'diamonds',
};

/// Per-terrain prospectability, derived from resource terrain rules:
/// any terrain that can host at least one mineral resource is prospectable.
final Map<TerrainType, bool> kProspectableByTerrainType = {
  for (final terrain in TerrainType.values)
    terrain: _buildProspectableTerrainsFromRules().contains(terrain),
};

Set<TerrainType> _buildProspectableTerrainsFromRules() {
  final rules = ResourceRules.defaultRules;
  final terrains = <TerrainType>{};
  for (final resource in Resource.values) {
    if (!kMineralResourceIds.contains(resource.name)) {
      continue;
    }
    terrains.addAll(rules.allowedTerrains[resource] ?? const <TerrainType>[]);
  }
  return terrains;
}

bool isProspectableTerrain(TerrainType terrain) =>
    kProspectableByTerrainType[terrain] ?? false;

bool isProspectableTerrainId(String? terrainTypeId) {
  if (terrainTypeId == null || terrainTypeId.isEmpty) {
    return false;
  }
  for (final terrain in TerrainType.values) {
    if (terrain.name == terrainTypeId) {
      return isProspectableTerrain(terrain);
    }
  }
  return false;
}
