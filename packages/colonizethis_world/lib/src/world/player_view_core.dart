import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../game_player_lookup.dart';
import 'package:colonizethis_world/src/logic_validation_exception.dart';
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
  for (final u in game.worldState.allUnitsById.values) {
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
        game
            .worldState
            .tileKeysByRegionAndProvince[kOldWorldRegionId]?[localId] ??
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
