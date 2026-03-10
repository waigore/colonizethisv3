import 'package:colonizethis_data/colonizethis_data.dart';

/// Gets a tile's region ID from the grid.
String? getTileRegionId(TileMapResult tileMap, int x, int y) {
  if (x < 0 || x >= tileMap.width || y < 0 || y >= tileMap.height) {
    return null;
  }
  return tileMap.cell(x, y);
}

/// Generates a tile key in format "regionId|x|y".
String makeTileKey(String regionId, int x, int y) {
  return '$regionId|$x|$y';
}

/// Full tile key per SPEC/game/world-model-identity.md: regionId|localId|x|y.
String makeFullTileKey(String regionId, String localId, int x, int y) {
  return '$regionId|$localId|$x|$y';
}

