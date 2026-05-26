/// Shared constants and helpers for the colonizethis_logic package.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'utils/expando_index.dart';

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
/// new [Game] replaces the previous one via [Game.copyWith]. Routed through the
/// shared [ExpandoIndex] utility so all `colonizethis_logic` per-[Game] caches
/// share one invalidation contract (Refs #2836 AC 2).
final ExpandoIndex<Game, Map<String, Player>> _gamePlayersByIdIndex =
    ExpandoIndex<Game, Map<String, Player>>('gamePlayersById', (game) {
      final byId = <String, Player>{};
      for (final p in game.players) {
        byId.putIfAbsent(p.id, () => p);
      }
      return byId;
    });

/// GP whose [Player.capitalProvinceId] maps to each full province id (first in
/// [Game.players] list order wins on duplicates). Refs #2394 steal_tech paths.
/// Routed through the shared [ExpandoIndex] utility (Refs #2836 AC 2).
final ExpandoIndex<Game, Map<String, String>>
_gameGpOwnerIdByCapitalProvinceIdIndex =
    ExpandoIndex<Game, Map<String, String>>(
      'gameGpOwnerIdByCapitalProvinceId',
      (game) {
        final byCap = <String, String>{};
        for (final p in game.players) {
          final cap = p.capitalProvinceId;
          if (cap != null) {
            byCap.putIfAbsent(cap, () => p.id);
          }
        }
        return byCap;
      },
    );

/// Faction id → display name for any [Game.players], [Game.minorNations], or
/// [Game.tribes] row. Built once per [Game] instance for app-side label
/// rendering (Refs #2575 Phase 3). Falls back to faction id when display name
/// is null (mirrors prior linear-scan fallback). First-match-wins on id
/// collisions across the three faction lists. Routed through the shared
/// [ExpandoIndex] utility (Refs #2836 AC 2).
final ExpandoIndex<Game, Map<String, String>> _gameFactionDisplayNameByIdIndex =
    ExpandoIndex<Game, Map<String, String>>('gameFactionDisplayNameById', (
      game,
    ) {
      final byId = <String, String>{};
      for (final p in game.players) {
        byId.putIfAbsent(p.id, () => p.displayName);
      }
      for (final m in game.minorNations) {
        byId.putIfAbsent(m.id, () => m.displayName ?? m.id);
      }
      for (final t in game.tribes) {
        byId.putIfAbsent(t.id, () => t.displayName ?? t.id);
      }
      return byId;
    });

/// Fleet id → [Fleet] for any [WorldState.fleets] row. Built once per [Game]
/// instance for app-side and dialog/panel lookups (Refs #2575 Phase 4).
/// First-match-wins on id collisions; mirrors the inline `<String, Fleet>` map
/// previously constructed in `projectFleetMarkersForHumanDraft`. Routed through
/// the shared [ExpandoIndex] utility (Refs #2836 AC 2).
final ExpandoIndex<Game, Map<String, Fleet>> _gameFleetsByIdIndex =
    ExpandoIndex<Game, Map<String, Fleet>>('gameFleetsById', (game) {
      final byId = <String, Fleet>{};
      for (final f in game.worldState.fleets) {
        byId.putIfAbsent(f.id, () => f);
      }
      return byId;
    });

/// Safe player lookup by id. Returns null if not found.
extension GamePlayerLookup on Game {
  Player? playerById(String id) => _gamePlayersByIdIndex.get(this)[id];

  /// Great Power at [capitalProvinceId] (excluding [excludePlayerId]), or null.
  ///
  /// Uses a per-[Game] lazy map keyed by full capital province id so steal_tech
  /// validation and completion avoid repeated linear scans over [players].
  Player? otherGreatPowerAtCapitalProvince(
    String capitalProvinceId,
    String excludePlayerId,
  ) {
    final byCap = _gameGpOwnerIdByCapitalProvinceIdIndex.get(this);
    final ownerId = byCap[capitalProvinceId];
    if (ownerId == null || ownerId == excludePlayerId) {
      return null;
    }
    return playerById(ownerId);
  }

  /// Display name for a faction id (player, minor nation, or tribe), or null
  /// when no faction matches. Uses a per-[Game] Expando-cached index so
  /// repeated calls during a single resolved game state are O(1) (Refs #2575
  /// Phase 3). Minor nation / tribe rows fall back to id when display name is
  /// null, mirroring prior `_factionLabel` behavior.
  String? factionDisplayNameById(String factionId) =>
      _gameFactionDisplayNameByIdIndex.get(this)[factionId];

  /// Safe fleet lookup by id over [WorldState.fleets]. Returns null when no
  /// fleet matches. Uses a per-[Game] Expando-cached index so repeated calls
  /// during a single resolved game state are O(1) (Refs #2575 Phase 4). The
  /// cache invalidates implicitly on the next [Game.copyWith] because callers
  /// always replace [worldState] via `game.copyWith(worldState: ...)` when
  /// fleets change, yielding a new [Game] instance.
  Fleet? fleetById(String id) => _gameFleetsByIdIndex.get(this)[id];
}
