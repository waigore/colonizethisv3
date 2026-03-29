// Tile keys for centering the map on provinces and sea zones from game UI.
// SPEC/ui/military-units-panel.md, SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';

/// Resolves the tile key to use when centering on [province] (town tile or first tile).
/// Uses `(regionId, province.id)` via [Province.regionId] and prefixed map keys.
/// Returns null if no tile can be resolved.
String? tileKeyForProvinceLocation(Game game, Province province) {
  final prefixedId = '${province.regionId}|${province.id}';
  if (province.townTileKey != null && province.townTileKey!.isNotEmpty) {
    return province.townTileKey;
  }
  final byProvince =
      game.worldState.tileKeysByRegionAndProvince[province.regionId];
  final tiles = byProvince?[prefixedId] ?? byProvince?[province.id];
  if (tiles != null && tiles.isNotEmpty) return tiles.first;
  return null;
}

/// Resolves a port tile key adjacent to the given sea zone in [regionId].
/// [seaZoneId] may be prefixed (`regionId|localId`) or local. Returns null if none.
String? tileKeyForSeaZoneLocation(
  Game game,
  String regionId,
  String seaZoneId,
) {
  final localSeaZone = seaZoneId.contains('|')
      ? seaZoneId.split('|').last
      : seaZoneId;
  for (final e in game.worldState.portsByProvinceSeaboard.entries) {
    final parts = e.key.split('|');
    if (parts.length < 2) continue;
    final keyRegion = parts[0];
    final keySeaZone = parts.last;
    if (keyRegion == regionId && keySeaZone == localSeaZone) {
      return e.value;
    }
  }
  return null;
}
