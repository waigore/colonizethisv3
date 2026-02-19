import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';

/// Visibility level for a tile from a single player's perspective.
/// Mirrors SPEC/game/fog-and-exploration.md.
enum VisibilityLevel {
  unknown,
  revealed,
  fogged,
  fullyVisible,
}

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
      provincesById[ProvinceId.isPrefixed(provinceId) ? provinceId : ProvinceId.full(regionId, provinceId)];

  Iterable<Unit> unitsInProvince(String regionId, String provinceId) {
    final fullId = ProvinceId.isPrefixed(provinceId) ? provinceId : ProvinceId.full(regionId, provinceId);
    return ownUnits.where((u) => u.provinceId == fullId);
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
PlayerView buildPlayerView(
  Game game,
  MapTopology topology,
  String playerId,
) {
  final player = game.playerById(playerId);
  if (player == null) {
    throw ArgumentError.value(playerId, 'playerId', 'Player not found in game');
  }

  // Provinces: key by full id (p.id is regionId|localId).
  final provincesById = <String, Province>{};
  for (final p in game.worldState.oldWorld.provinces) {
    final key = ProvinceId.isPrefixed(p.id) ? p.id : ProvinceId.full(p.regionId, p.id);
    provincesById[key] = p;
  }
  for (final p in game.worldState.newWorld.provinces) {
    final key = ProvinceId.isPrefixed(p.id) ? p.id : ProvinceId.full(p.regionId, p.id);
    provincesById[key] = p;
  }

  // Units owned by this player across both regions.
  final ownUnitsById = <String, Unit>{};
  for (final u in game.worldState.oldWorld.units) {
    if (u.ownerId == playerId) {
      ownUnitsById[u.id] = u;
    }
  }
  for (final u in game.worldState.newWorld.units) {
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
  final rawVisibility = game.worldState.playerVisibilityByTile[playerId] ?? const {};
  final visibilityByTile = <String, VisibilityLevel>{};
  rawVisibility.forEach((tileKey, levelName) {
    final level = VisibilityLevel.values.firstWhere(
      (e) => e.name == levelName,
      orElse: () => VisibilityLevel.unknown,
    );
    visibilityByTile[tileKey] = level;
  });

  final prospectedTiles =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};

  // Topology is currently unused but is part of the signature for future
  // derived helpers (e.g. province neighbors visible to the player).
  final _ = topology; // ignore: unused_local_variable

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

