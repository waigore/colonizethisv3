import 'package:colonizethis_models/colonizethis_models.dart';

import '../game_player_lookup.dart';

/// Resolves a faction's capital tile via player → minor → tribe identity walk.
///
/// Single source of truth for capital-tile projection used by civilian legality,
/// town connectivity, and related ownership paths (Refs #4038).
CapitalTile? capitalTileForFaction(Game game, String factionId) {
  final player = game.playerById(factionId);
  if (player != null) return player.capitalTile;
  for (final minor in game.minorNations) {
    if (minor.id == factionId) return minor.capitalTile;
  }
  for (final tribe in game.tribes) {
    if (tribe.id == factionId) return tribe.capitalTile;
  }
  return null;
}

/// Resolves a faction's capital province id via the same player → minor → tribe
/// walk as [capitalTileForFaction] (Refs #4038).
String? capitalProvinceIdForFaction(Game game, String factionId) {
  final player = game.playerById(factionId);
  if (player != null) return player.capitalProvinceId;
  for (final minor in game.minorNations) {
    if (minor.id == factionId) return minor.capitalProvinceId;
  }
  for (final tribe in game.tribes) {
    if (tribe.id == factionId) return tribe.capitalProvinceId;
  }
  return null;
}
