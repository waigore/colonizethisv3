// Advanced-start developable tile ranking and hub road wiring helpers.
// SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'advanced_start_selection.dart';
import 'setup_road_wiring.dart';

bool isDevelopableAdvancedStartTile({
  required String tileKey,
  required String? resourceId,
  required Set<String> prospectedTileKeys,
}) {
  if (resourceId == null || resourceId.isEmpty) return false;
  if (kAdvancedStartDevelopableResourceIds.contains(resourceId)) return true;
  if (kProspectRequiredResourceIds.contains(resourceId)) {
    return prospectedTileKeys.contains(tileKey);
  }
  return false;
}

List<String> rankDevelopableAdvancedStartTileKeys({
  required Iterable<String> tileKeys,
  required Map<String, String> resourceByTileKey,
  required Set<String> prospectedTileKeys,
}) {
  final ranked = <(int priority, String key)>[];
  for (final key in tileKeys) {
    final resourceId = resourceByTileKey[key];
    if (!isDevelopableAdvancedStartTile(
      tileKey: key,
      resourceId: resourceId,
      prospectedTileKeys: prospectedTileKeys,
    )) {
      continue;
    }
    ranked.add((advancedStartDevelopableTilePriority(resourceId!), key));
  }
  ranked.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    if (c != 0) return c;
    return a.$2.compareTo(b.$2);
  });
  return ranked.map((e) => e.$2).toList();
}

String? hubTileKeyForAdvancedStartProvince({
  required Game game,
  required Province province,
  required String ownerId,
}) {
  if (province.townTileKey != null) return province.townTileKey;
  for (final player in game.players) {
    if (player.id != ownerId) continue;
    if (player.capitalProvinceId == province.id) {
      return player.capitalTile?.toTileKey();
    }
  }
  for (final minor in game.minorNations) {
    if (minor.id != ownerId) continue;
    if (minor.capitalProvinceId == province.id) {
      return minor.capitalTile?.toTileKey();
    }
  }
  return null;
}

Game applyAdvancedStartDevelopmentRoadsFromTilesToHub({
  required Game game,
  required String regionId,
  required String ownerId,
  required String hubTileKey,
  required Iterable<String> fromTileKeys,
  required TileMapResult map,
}) {
  final ws = game.worldState;
  final allowed = ownedTileKeysForFaction(ws, regionId, ownerId);
  if (!allowed.contains(hubTileKey)) return game;

  final coordToKey = coordToTileKeyForRegion(ws, regionId);
  final parent = bfsParentsFromTileKey(
    startTileKey: hubTileKey,
    allowed: allowed,
    coordToKey: coordToKey,
    mapWidth: map.width,
    mapHeight: map.height,
  );

  var tileState = ws.tileState;
  for (final fromKey in fromTileKeys) {
    if (fromKey == hubTileKey) continue;
    final path = pathTileKeysTowardHub(
      fromTileKey: fromKey,
      hubTileKey: hubTileKey,
      parent: parent,
    );
    tileState = wireRoadPathsOnOwnedTiles(
      tileState: tileState,
      pathTileKeys: path,
    );
  }

  return game.withTileState(tileState);
}

Game applyAdvancedStartPlayerProvinceDevelopment({
  required Game game,
  required String playerId,
  required String regionId,
  required Province province,
  required double fraction,
  required Set<String> prospected,
  required TileMapResult map,
  required Map<String, List<String>> tileKeysByProvince,
}) {
  final tileKeys = tileKeysByProvince[province.id] ?? const [];
  final candidates = rankDevelopableAdvancedStartTileKeys(
    tileKeys: tileKeys,
    resourceByTileKey: game.worldState.resourceByTileKey,
    prospectedTileKeys: prospected,
  );
  if (candidates.isEmpty) return game;

  final selected = selectByFractionCeil(candidates, fraction);
  var tileState = game.worldState.tileState;
  for (final key in selected) {
    tileState = tileState.setImprovement(key, 1);
  }
  var updated = game.withTileState(tileState);

  final hub = hubTileKeyForAdvancedStartProvince(
    game: updated,
    province: province,
    ownerId: playerId,
  );
  if (hub == null) return updated;

  return applyAdvancedStartDevelopmentRoadsFromTilesToHub(
    game: updated,
    regionId: regionId,
    ownerId: playerId,
    hubTileKey: hub,
    fromTileKeys: selected,
    map: map,
  );
}
