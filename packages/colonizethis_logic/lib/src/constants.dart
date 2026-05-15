/// Shared constants and helpers for the colonizethis_logic package.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export 'package:colonizethis_models/colonizethis_models.dart'
    show
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        kUnitTypeExplorer,
        kUnitTypeMerchant,
        kUnitTypeRailBuilder,
        kUnitTypeSpy;

const String kRegionOldWorld = 'oldWorld';
const String kRegionNewWorld = 'newWorld';

/// Cardinal (4-neighbor) grid deltas on row-major tile maps (north/up-first).
/// Canonical ordering shared across connectivity scans, setup shortest-path BFS,
/// capital-choice routing, and naval coastal adjacency (Refs #2391).
const List<(int, int)> kGridNeighborsCardinal4 = [
  (0, -1),
  (1, 0),
  (0, 1),
  (-1, 0),
];

/// Default sea fraction for map generation (0.6 = 60% sea, 40% land).
const double kDefaultSeaFraction = 0.6;

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

/// Lazily built once per [Game] instance (issue #2268 AC-2); invalidated when a
/// new [Game] replaces the previous one via [Game.copyWith].
final Expando<Map<String, Player>> _gamePlayersById =
    Expando<Map<String, Player>>('gamePlayersById');

/// GP whose [Player.capitalProvinceId] maps to each full province id (first in
/// [Game.players] list order wins on duplicates). Refs #2394 steal_tech paths.
final Expando<Map<String, String>> _gameGpOwnerIdByCapitalProvinceId =
    Expando<Map<String, String>>('gameGpOwnerIdByCapitalProvinceId');

/// Safe player lookup by id. Returns null if not found.
extension GamePlayerLookup on Game {
  Player? playerById(String id) {
    var byId = _gamePlayersById[this];
    if (byId == null) {
      byId = <String, Player>{};
      for (final p in players) {
        byId.putIfAbsent(p.id, () => p);
      }
      _gamePlayersById[this] = byId;
    }
    return byId[id];
  }

  /// Great Power at [capitalProvinceId] (excluding [excludePlayerId]), or null.
  ///
  /// Uses a per-[Game] lazy map keyed by full capital province id so steal_tech
  /// validation and completion avoid repeated linear scans over [players].
  Player? otherGreatPowerAtCapitalProvince(
    String capitalProvinceId,
    String excludePlayerId,
  ) {
    var byCap = _gameGpOwnerIdByCapitalProvinceId[this];
    if (byCap == null) {
      byCap = <String, String>{};
      for (final p in players) {
        final cap = p.capitalProvinceId;
        if (cap != null) {
          byCap.putIfAbsent(cap, () => p.id);
        }
      }
      _gameGpOwnerIdByCapitalProvinceId[this] = byCap;
    }
    final ownerId = byCap[capitalProvinceId];
    if (ownerId == null || ownerId == excludePlayerId) {
      return null;
    }
    return playerById(ownerId);
  }
}
