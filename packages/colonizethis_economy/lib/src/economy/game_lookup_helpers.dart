/// Package-local `Game`/`WorldState` lookup helpers shared across the economy
/// layer.
///
/// Both the Great-Power extraction pass ([computeExtraction]) and the non-GP
/// extraction / auto-offer passes need an O(1) province-by-full-id index and
/// the set of port tile keys. These were previously rebuilt inline at several
/// sites with identical comprehensions; extracting them here removes the
/// copy-paste called out in issue #3396 cluster 5 while preserving the exact
/// construction (and therefore iteration semantics) of the originals.
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Builds a province-by-full-id index for [game]'s current world state.
///
/// Keyed by the prefixed province id (`regionId|localId`) per
/// `SPEC/game/world-model.md`; lets per-tile callers resolve province rows in
/// O(1) instead of scanning the region list for every tile.
Map<String, Province> buildProvinceIndex(Game game) => <String, Province>{
  for (final p in allProvinces(game.worldState)) p.id: p,
};

/// Collects the set of port tile keys (one per province seaboard) for [game].
///
/// Mirrors the inline `portsByProvinceSeaboard.values.toSet()` used by the
/// extraction passes to detect port tiles and port town tiles.
Set<String> collectPortTileKeys(Game game) =>
    game.worldState.portsByProvinceSeaboard.values.toSet();

/// Capital province id for a Great Power, minor nation, or tribe [factionId].
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

/// Capital region id for a Great Power, minor nation, or tribe [factionId].
String? capitalRegionIdForFaction(Game game, String factionId) {
  final player = game.playerById(factionId);
  if (player != null) return player.capitalTile?.regionId;
  for (final minor in game.minorNations) {
    if (minor.id == factionId) return minor.capitalTile?.regionId;
  }
  for (final tribe in game.tribes) {
    if (tribe.id == factionId) return tribe.capitalTile?.regionId;
  }
  return null;
}
