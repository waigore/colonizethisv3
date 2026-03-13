/// Visibility level for a tile.
enum TileVisibility { unexplored, fogged, revealed, fullyVisible }

/// Gets visibility level from player visibility map.
TileVisibility getTileVisibility(
  String tileKey,
  Map<String, String>? playerVisibilityByTile,
) {
  if (playerVisibilityByTile == null) return TileVisibility.unexplored;

  final level = playerVisibilityByTile[tileKey];
  switch (level) {
    case 'fullyVisible':
      return TileVisibility.fullyVisible;
    case 'fogged':
      return TileVisibility.fogged;
    case 'revealed':
      return TileVisibility.revealed;
    case null:
    default:
      return TileVisibility.unexplored;
  }
}

/// Checks if a tile is at least revealed (visible info shown).
bool isTileVisible(
  String tileKey,
  Map<String, String>? playerVisibilityByTile,
) {
  final visibility = getTileVisibility(tileKey, playerVisibilityByTile);
  return visibility == TileVisibility.fullyVisible ||
      visibility == TileVisibility.revealed ||
      visibility == TileVisibility.fogged;
}

/// Checks if a tile is fully visible (no fog).
bool isTileFullyVisible(
  String tileKey,
  Map<String, String>? playerVisibilityByTile,
) {
  return getTileVisibility(tileKey, playerVisibilityByTile) ==
      TileVisibility.fullyVisible;
}

