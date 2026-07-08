import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Full prefixed province id from a tile key, or null when parsing fails.
String? fullProvinceIdFromTileKey(String tileKey) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return null;
  return ProvinceId.full(coords.regionId, coords.provinceLocalId);
}

/// Invokes [onTile] for each tile in [connectedTiles] that is town-connected
/// and belongs to [provinceId].
void forEachTownConnectedTileInProvince({
  required Iterable<String> connectedTiles,
  required Set<String> townConnected,
  required String provinceId,
  required void Function(String tileKey) onTile,
}) {
  for (final tileKey in connectedTiles) {
    if (!townConnected.contains(tileKey)) continue;
    if (fullProvinceIdFromTileKey(tileKey) != provinceId) continue;
    onTile(tileKey);
  }
}
