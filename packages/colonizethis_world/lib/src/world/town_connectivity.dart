import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'connectivity_tile_helpers.dart';
import 'faction_capital.dart';
import 'province_lookup.dart';

/// Town-tile connectivity for town manufacturing bonus (Refs #3872).
///
/// Distinct from capital extraction connectivity per
/// `SPEC/game/capital-and-connectivity.md` § Town-tile connectivity.
/// A tile in province [provinceId] is town-connected when it lies in that
/// province and is either 4-adjacent to the effective town tile or reachable
/// via a path of province tiles with transport level ≥ 1.

/// Effective town tile for connectivity: capital tile when [province] is a
/// faction capital province; otherwise [Province.townTileKey].
String? effectiveTownTileKeyForProvince({
  required Province province,
  required String? capitalProvinceId,
  required CapitalTile? capitalTile,
}) {
  if (capitalProvinceId != null &&
      capitalTile != null &&
      province.id == capitalProvinceId) {
    return capitalTile.toTileKey();
  }
  final town = province.townTileKey;
  if (town == null || town.isEmpty) return null;
  return town;
}

/// Returns town-connected tile keys within [provinceId].
Set<String> resolveTownConnectedTileKeysForProvince({
  required String provinceId,
  required String? townTileKey,
  required WorldState worldState,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, (String, String)> portTileToProvinceSeaZone,
}) {
  if (townTileKey == null || townTileKey.isEmpty) {
    return const {};
  }
  final coords = parseTileKeyCoordinates(townTileKey);
  if (coords == null) return const {};
  final map = tileMapByRegion[coords.regionId];
  if (map == null) return const {};

  final provinceTiles = landTileKeysForProvinceBucket(
    worldState,
    coords.regionId,
    provinceId,
  );
  if (provinceTiles.isEmpty) return const {};

  final townConnected = <String>{};

  for (final tileKey in provinceTiles) {
    if (_isFourAdjacentToTown(
      tileKey: tileKey,
      townTileKey: townTileKey,
      map: map,
      regionId: coords.regionId,
      provinceIdsByType: _landProvinceIdsFromTiles(provinceTiles),
    )) {
      townConnected.add(tileKey);
    }
  }

  final queue = <String>[townTileKey];
  final visited = <String>{townTileKey};
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    townConnected.add(current);
    final currentCoords = parseTileKeyCoordinates(current);
    if (currentCoords == null) continue;
    for (final neighbor in adjacentTileKeys(
      currentCoords.regionId,
      currentCoords.provinceLocalId,
      currentCoords.x,
      currentCoords.y,
      map,
      _landProvinceIdsFromTiles(provinceTiles),
    )) {
      if (!provinceTiles.contains(neighbor)) continue;
      if (visited.contains(neighbor)) continue;
      final transport = transportLevelAtTile(
        worldState,
        neighbor,
        portTileToProvinceSeaZone,
      );
      if (transport < 1) continue;
      visited.add(neighbor);
      queue.add(neighbor);
    }
  }

  return townConnected;
}

bool _isFourAdjacentToTown({
  required String tileKey,
  required String townTileKey,
  required TileMapResult map,
  required String regionId,
  required Set<String> provinceIdsByType,
}) {
  final townCoords = parseTileKeyCoordinates(townTileKey);
  final tileCoords = parseTileKeyCoordinates(tileKey);
  if (townCoords == null || tileCoords == null) return false;
  if (townCoords.regionId != tileCoords.regionId) return false;
  for (final neighbor in adjacentTileKeys(
    regionId,
    tileCoords.provinceLocalId,
    tileCoords.x,
    tileCoords.y,
    map,
    provinceIdsByType,
  )) {
    if (neighbor == townTileKey) return true;
  }
  return false;
}

Set<String> _landProvinceIdsFromTiles(Iterable<String> tileKeys) {
  final ids = <String>{};
  for (final key in tileKeys) {
    final coords = parseTileKeyCoordinates(key);
    if (coords == null) continue;
    ids.add(coords.provinceLocalId);
    ids.add(ProvinceId.full(coords.regionId, coords.provinceLocalId));
  }
  return ids;
}

/// Town-connected tile keys keyed by full province id for all provinces with a
/// town tile.
Map<String, Set<String>> resolveTownConnectedTileKeysByProvince({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final portInfo = portToProvinceSeaZone(game.worldState);
  final out = <String, Set<String>>{};
  for (final province in allProvinces(game.worldState)) {
    final townKey = province.townTileKey;
    if (townKey == null || townKey.isEmpty) continue;
    final ownerId = province.ownerId;
    if (ownerId == null || ownerId.isEmpty) continue;
    final capitalProvinceId = capitalProvinceIdForFaction(game, ownerId);
    final capitalTile = capitalTileForFaction(game, ownerId);
    final effectiveTown = effectiveTownTileKeyForProvince(
      province: province,
      capitalProvinceId: capitalProvinceId,
      capitalTile: capitalTile,
    );
    final connected = resolveTownConnectedTileKeysForProvince(
      provinceId: province.id,
      townTileKey: effectiveTown,
      worldState: game.worldState,
      tileMapByRegion: tileMapByRegion,
      portTileToProvinceSeaZone: portInfo,
    );
    if (connected.isNotEmpty) {
      out[province.id] = connected;
    }
  }
  return out;
}
