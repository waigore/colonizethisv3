import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../logic_validation_exception.dart';
import 'province_lookup.dart';
import 'unit_lookup.dart';

/// Visibility level for a tile from a single player's perspective.
/// Mirrors SPEC/game/fog-and-exploration.md.
enum VisibilityLevel { unknown, fogged, fullyVisible }

const _visibilityLevelByName = <String, VisibilityLevel>{
  'unknown': VisibilityLevel.unknown,
  'fogged': VisibilityLevel.fogged,
  'fullyVisible': VisibilityLevel.fullyVisible,
};

/// Read-only projection of [Game] for a single player under fog-of-war.
///
/// See SPEC/program/player-view.md. This type is used by AI and order
/// suggestion logic to reason about the world without omniscience.
class PlayerView {
  const PlayerView({
    required this.playerId,
    required this.player,
    required this.ownUnitsById,
    required this.provincesById,
    required this.visibilityByTile,
    required this.prospectedTiles,
    required this.diplomacyByOtherId,
  });

  final String playerId;
  final Player player;

  /// Units owned by [playerId], keyed by unit id.
  final Map<String, Unit> ownUnitsById;

  /// All provinces known to this view, keyed by full province id (regionId|localId).
  final Map<String, Province> provincesById;

  /// Tile visibility per tile key. When a key is absent, visibility is
  /// treated as [VisibilityLevel.unknown].
  final Map<String, VisibilityLevel> visibilityByTile;

  /// Set of prospected tile keys for this player.
  final Set<String> prospectedTiles;

  /// Diplomacy relations between [playerId] and other factions, keyed by
  /// the other faction's id.
  final Map<String, DiplomacyRelation> diplomacyByOtherId;

  Iterable<Unit> get ownUnits => ownUnitsById.values;

  /// Lookup province by region and id. [provinceId] may be full (regionId|localId) or local; [regionId] is used when [provinceId] is local.
  Province? provinceByRegionAndId(String regionId, String provinceId) =>
      provincesById[toFullProvinceId(regionId, provinceId)];

  Iterable<Unit> unitsInProvince(String regionId, String provinceId) {
    final fullId = toFullProvinceId(regionId, provinceId);
    return ownUnits.where((u) => u.locationProvinceId == fullId);
  }

  VisibilityLevel visibilityForTile(String tileKey) =>
      visibilityByTile[tileKey] ?? VisibilityLevel.unknown;

  bool tileIsProspected(String tileKey) => prospectedTiles.contains(tileKey);

  DiplomacyRelation? relationWith(String otherFactionId) =>
      diplomacyByOtherId[otherFactionId];
}

/// Builds a [PlayerView] for [playerId] from [game] and [topology].
///
/// This is a pure function; it must be deterministic for the same inputs.
PlayerView buildPlayerView(Game game, MapTopology _, String playerId) {
  final player = game.playerById(playerId);
  if (player == null) {
    throw LogicValidationException.value(
      playerId,
      'playerId',
      'Player not found in game',
    );
  }

  // Provinces: key by full id (p.id is regionId|localId).
  final provincesById = <String, Province>{};
  for (final p in allProvinces(game.worldState)) {
    provincesById[toFullProvinceId(p.regionId, p.id)] = p;
  }

  // Units owned by this player across both regions.
  final ownUnitsById = <String, Unit>{};
  for (final u in allUnitsFromWorld(game.worldState)) {
    if (u.ownerId == playerId) {
      ownUnitsById[u.id] = u;
    }
  }

  // Diplomacy: index relations involving this player by the other faction id.
  final diplomacyByOtherId = <String, DiplomacyRelation>{};
  for (final rel in game.diplomacyRelations) {
    if (rel.factionId1 == playerId) {
      diplomacyByOtherId[rel.factionId2] = rel;
    } else if (rel.factionId2 == playerId) {
      diplomacyByOtherId[rel.factionId1] = rel;
    }
  }

  // Visibility and prospection per SPEC/program/fog-and-exploration-resolution.md:
  // derive from WorldState's per-player maps.
  final rawVisibility =
      game.worldState.playerVisibilityByTile[playerId] ?? const {};
  final visibilityByTile = <String, VisibilityLevel>{};
  rawVisibility.forEach((tileKey, levelName) {
    visibilityByTile[tileKey] =
        _visibilityLevelByName[levelName] ?? VisibilityLevel.unknown;
  });

  // Spy presence reveal: while a Spy is in a non-owner province, that province is fully visible. SPEC/program/fog-and-exploration-resolution.md.
  for (final u in ownUnitsById.values) {
    if (!isSpyUnit(u.type)) continue;
    final provId = u.locationProvinceId;
    final regionId = ProvinceId.regionIdFrom(provId);
    final tileKeys =
        game.worldState.tileKeysByRegionAndProvince[regionId]?[provId] ?? [];
    if (tileKeys.isEmpty) continue;
    final province = provincesById[provId];
    if (province == null ||
        province.ownerId == null ||
        province.ownerId == playerId) {
      continue;
    }
    for (final tk in tileKeys) {
      visibilityByTile[tk] = VisibilityLevel.fullyVisible;
    }
  }

  // At-war Old World provinces are at least fogged so army invasion orders can
  // target neighboring enemy territory (trade/colonial GPs may not have explored
  // every border minor). SPEC/ai/ai-architecture.md victory-aware military.
  for (final entry in provincesById.entries) {
    final fullId = entry.key;
    if (ProvinceId.regionIdFrom(fullId) != kOldWorldRegionId) {
      continue;
    }
    final ownerId = entry.value.ownerId;
    if (ownerId == null || ownerId.isEmpty || ownerId == playerId) {
      continue;
    }
    final rel = diplomacyByOtherId[ownerId];
    if (rel == null || rel.atPeace) {
      continue;
    }
    final localId = ProvinceId.localIdFrom(fullId);
    final tileKeys =
        game.worldState.tileKeysByRegionAndProvince[kOldWorldRegionId]?[localId] ??
        const [];
    for (final tk in tileKeys) {
      if (visibilityByTile[tk] == VisibilityLevel.unknown) {
        visibilityByTile[tk] = VisibilityLevel.fogged;
      }
    }
  }

  final prospectedTiles =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};

  return PlayerView(
    playerId: playerId,
    player: player,
    ownUnitsById: ownUnitsById,
    provincesById: provincesById,
    visibilityByTile: visibilityByTile,
    prospectedTiles: prospectedTiles,
    diplomacyByOtherId: diplomacyByOtherId,
  );
}

/// Resources that require prospecting before the player "knows" them.
/// SPEC/game/fog-and-exploration.md: iron, copper, tin, coal, silver, gold, gems, diamonds.
const Set<String> kProspectRequiredResourceIds = {
  'iron',
  'copper',
  'tin',
  'coal',
  'silver',
  'gold',
  'gems',
  'diamonds',
};

/// Resource commodity id to show in UI for the given visibility and
/// prospection state, or null to show no resource.
///
/// [authoritativeResourceId] is ground truth from the tile map /
/// [WorldState.resourceByTileKey]. SPEC/game/fog-and-exploration.md.
String? resourceIdVisibleToPlayer({
  required String? authoritativeResourceId,
  required VisibilityLevel visibility,
  required bool tileProspectedByPlayer,
}) {
  final id = authoritativeResourceId;
  if (id == null || id.isEmpty) return null;

  switch (visibility) {
    case VisibilityLevel.unknown:
      return null;
    case VisibilityLevel.fogged:
      if (kProspectRequiredResourceIds.contains(id)) {
        return tileProspectedByPlayer ? id : null;
      }
      return id;
    case VisibilityLevel.fullyVisible:
      if (kProspectRequiredResourceIds.contains(id)) {
        return tileProspectedByPlayer ? id : null;
      }
      return id;
  }
}

/// Convenience wrapper using [PlayerView] visibility and prospected-tile set.
String? resourceIdVisibleInPlayerView(
  PlayerView view,
  String tileKey,
  String? authoritativeResourceId,
) {
  return resourceIdVisibleToPlayer(
    authoritativeResourceId: authoritativeResourceId,
    visibility: view.visibilityForTile(tileKey),
    tileProspectedByPlayer: view.tileIsProspected(tileKey),
  );
}

/// True if [playerId] has at least one non-unknown tile containing [resourceId].
/// For prospect-required
/// resources (gold, silver, gems, diamonds, etc.), the tile must also be
/// prospected by that player. SPEC/game/tech-tree.md Discovery prerequisites.
bool hasRevealedResourceForPlayer(
  Game game,
  String playerId,
  String resourceId,
) {
  final ws = game.worldState;
  final visibility = ws.playerVisibilityByTile[playerId] ?? const {};
  final prospected = ws.playerProspectedTiles[playerId] ?? const <String>{};
  final needProspect = kProspectRequiredResourceIds.contains(resourceId);

  for (final e in ws.resourceByTileKey.entries) {
    if (e.value != resourceId) continue;
    final tileKey = e.key;
    final levelName = visibility[tileKey];
    if (levelName == null || levelName == 'unknown') continue;
    if (needProspect && !prospected.contains(tileKey)) continue;
    return true;
  }
  return false;
}

/// Whether [unit] should appear in another player's province UI for civilians.
///
/// The owner's units always count. Enemy [Spy] units never count. Other factions'
/// units require a [Unit.tileKey] and tile visibility other than [VisibilityLevel.unknown].
bool foreignCivilianVisibleToPlayer({
  required Unit unit,
  required String viewerPlayerId,
  required PlayerView view,
}) {
  if (unit.ownerId == viewerPlayerId) return true;
  if (isSpyUnit(unit.type)) return false;
  final tk = unit.tileKey;
  if (tk == null || tk.isEmpty) return false;
  return view.visibilityForTile(tk) != VisibilityLevel.unknown;
}

/// True when province panel may show tile-derived full-intel sections.
///
/// Sections gated by this predicate are Economic, Military, Civilian, and Naval.
/// Political ownership remains authoritative UI data.
///
/// Rules:
/// - Own province: always true.
/// - Foreign province + own Spy present: true.
/// - Foreign province + active Spy fog-decay timer (> 0): true.
/// - Otherwise: every tile in the province must be fully visible in [view].
bool provincePanelShowsFullTileDerivedIntel({
  required Game game,
  required PlayerView view,
  required String humanPlayerId,
  required String provinceId,
  Iterable<String>? provinceTileKeys,
}) {
  final province =
      view.provincesById[provinceId] ??
      tryGetProvince(game.worldState, provinceId);
  final ownerId = province?.ownerId;
  if (ownerId == humanPlayerId) {
    return true;
  }

  final isForeignProvince =
      ownerId != null && ownerId.isNotEmpty && ownerId != humanPlayerId;
  if (isForeignProvince &&
      _hasOwnSpyInProvince(view, humanPlayerId, provinceId)) {
    return true;
  }
  if (isForeignProvince) {
    final turnsLeft =
        game.worldState.spyRevealTurnsByPlayer[humanPlayerId]?[provinceId] ?? 0;
    if (turnsLeft > 0) {
      return true;
    }
  }

  final regionId = ProvinceId.regionIdFrom(provinceId);
  final tileKeys =
      (provinceTileKeys ??
              game
                  .worldState
                  .tileKeysByRegionAndProvince[regionId]?[provinceId] ??
              const <String>[])
          .toList();
  if (tileKeys.isEmpty) {
    return false;
  }
  for (final tk in tileKeys) {
    if (view.visibilityForTile(tk) != VisibilityLevel.fullyVisible) {
      return false;
    }
  }
  return true;
}

bool _hasOwnSpyInProvince(
  PlayerView view,
  String humanPlayerId,
  String provinceId,
) {
  for (final unit in view.ownUnits) {
    if (unit.ownerId != humanPlayerId) continue;
    if (!isSpyUnit(unit.type)) continue;
    if (unit.locationProvinceId == provinceId) return true;
  }
  return false;
}
