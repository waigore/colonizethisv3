// Advanced-start tile development (steps 11–12). SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'advanced_start_bootstrap_roads.dart';
import 'setup_logging.dart';

bool _isDevelopableTile({
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

List<String> _rankDevelopableTileKeys({
  required Iterable<String> tileKeys,
  required Map<String, String> resourceByTileKey,
  required Set<String> prospectedTileKeys,
}) {
  final ranked = <(int priority, String key)>[];
  for (final key in tileKeys) {
    final resourceId = resourceByTileKey[key];
    if (!_isDevelopableTile(
      tileKey: key,
      resourceId: resourceId,
      prospectedTileKeys: prospectedTileKeys,
    )) {
      continue;
    }
    ranked.add((
      advancedStartDevelopableTilePriority(resourceId!),
      key,
    ));
  }
  ranked.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    if (c != 0) return c;
    return a.$2.compareTo(b.$2);
  });
  return ranked.map((e) => e.$2).toList();
}

String? _hubTileKeyForProvince({
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

Game _applyPlayerProvinceDevelopment({
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
  final candidates = _rankDevelopableTileKeys(
    tileKeys: tileKeys,
    resourceByTileKey: game.worldState.resourceByTileKey,
    prospectedTileKeys: prospected,
  );
  if (candidates.isEmpty) return game;

  final target = (candidates.length * fraction).ceil();
  final selected = candidates.take(target).toList();
  var tileState = game.worldState.tileState;
  for (final key in selected) {
    tileState = tileState.setImprovement(key, 1);
  }
  var updated = game.withTileState(tileState);

  final hub = _hubTileKeyForProvince(
    game: updated,
    province: province,
    ownerId: playerId,
  );
  if (hub == null) return updated;

  return _wireRoadsFromTilesToHub(
    game: updated,
    regionId: regionId,
    ownerId: playerId,
    hubTileKey: hub,
    fromTileKeys: selected,
    map: map,
  );
}

Game _wireRoadsFromTilesToHub({
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

Game applyAdvancedStartPlayerDevelopment({
  required Game game,
  required AdvancedStartType startType,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final fraction = advancedStartDevelopmentFraction(startType);
  if (fraction <= 0) return game;

  var updated = game;
  for (final player in game.players) {
    final prospected =
        game.worldState.playerProspectedTiles[player.id] ?? const <String>{};

    for (final regionId in [kRegionOldWorld, kRegionNewWorld]) {
      final map = tileMapByRegion[regionId];
      if (map == null) continue;
      final tileKeysByProvince =
          game.worldState.tileKeysByRegionAndProvince[regionId] ??
          const <String, List<String>>{};

      for (final province in game.worldState.provincesForRegion(regionId)) {
        if (province.ownerId != player.id) continue;
        updated = _applyPlayerProvinceDevelopment(
          game: updated,
          playerId: player.id,
          regionId: regionId,
          province: province,
          fraction: fraction,
          prospected: prospected,
          map: map,
          tileKeysByProvince: tileKeysByProvince,
        );
      }
    }
  }

  setupLog.i(
    'logic: advanced start player development applied fraction=$fraction',
  );
  return updated;
}

Game applyAdvancedStartMinorDevelopment({
  required Game game,
  required AdvancedStartType startType,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final fraction = advancedStartDevelopmentFraction(startType);
  if (fraction <= 0 || game.players.isEmpty || game.minorNations.isEmpty) {
    return game;
  }

  final map = tileMapByRegion[kRegionOldWorld];
  if (map == null) return game;

  var updated = game;
  var purchased = Map<String, String>.from(
    updated.worldState.purchasedTilesByTileKey,
  );
  var tileState = updated.worldState.tileState;

  for (var i = 0; i < game.minorNations.length; i++) {
    final minor = game.minorNations[i];
    final buyerId = game.players[i % game.players.length].id;
    final buyerProspected =
        updated.worldState.playerProspectedTiles[buyerId] ?? const <String>{};
    final tileKeysByProvince =
        game.worldState.tileKeysByRegionAndProvince[kRegionOldWorld] ??
        const <String, List<String>>{};

    final developable = <String>[];
    for (final province in game.worldState.oldWorld.provinces) {
      if (province.ownerId != minor.id) continue;
      developable.addAll(
        _rankDevelopableTileKeys(
          tileKeys: tileKeysByProvince[province.id] ?? const [],
          resourceByTileKey: game.worldState.resourceByTileKey,
          prospectedTileKeys: buyerProspected,
        ),
      );
    }
    if (developable.isEmpty) continue;

    final target = (developable.length * fraction).ceil();
    final selected = developable.take(target).toList();
    for (final key in selected) {
      purchased[key] = buyerId;
      tileState = tileState.setImprovement(key, 1);
    }

    for (final province in game.worldState.oldWorld.provinces) {
      if (province.ownerId != minor.id) continue;
      final provinceFullId = ProvinceId.isPrefixed(province.id)
          ? province.id
          : ProvinceId.full(province.regionId, province.id);
      final provinceSelected = selected.where((key) {
        final coords = parseTileKeyCoordinates(key);
        if (coords == null) return false;
        return ProvinceId.full(coords.regionId, coords.provinceLocalId) ==
            provinceFullId;
      }).toList();
      if (provinceSelected.isEmpty) continue;
      final hub = _hubTileKeyForProvince(
        game: updated,
        province: province,
        ownerId: minor.id,
      );
      if (hub == null) continue;
      updated = updated.copyWith(
        worldState: updated.worldState.copyWith(
          purchasedTilesByTileKey: purchased,
          tileState: tileState,
        ),
      );
      updated = _wireRoadsFromTilesToHub(
        game: updated,
        regionId: kRegionOldWorld,
        ownerId: minor.id,
        hubTileKey: hub,
        fromTileKeys: provinceSelected,
        map: map,
      );
      purchased = Map<String, String>.from(
        updated.worldState.purchasedTilesByTileKey,
      );
      tileState = updated.worldState.tileState;
    }
  }

  setupLog.i(
    'logic: advanced start minor development applied fraction=$fraction',
  );
  return updated.copyWith(
    worldState: updated.worldState.copyWith(
      purchasedTilesByTileKey: purchased,
      tileState: tileState,
    ),
  );
}

Game applyAdvancedStartNwProvinceRoads({
  required Game game,
  required AdvancedStartType startType,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) {
  if (advancedStartNwColonizationCount(startType) <= 0) return game;

  final nwMap = tileMapByRegion[kRegionNewWorld];
  final nwTopology = topologyByRegion[kRegionNewWorld];
  if (nwMap == null || nwTopology == null) return game;

  var ws = game.worldState;
  for (final player in game.players) {
    for (final province in ws.newWorld.provinces) {
      if (province.ownerId != player.id) continue;
      final townKey = province.townTileKey;
      if (townKey == null) continue;
      ws = applySeaboardPortAndRoadToTile(
        worldState: ws,
        provinceId: province.id,
        inlandTileKey: townKey,
        topology: nwTopology,
        map: nwMap,
      );
    }
  }

  return game.copyWith(worldState: ws);
}

Game applyAdvancedStartDevelopment({
  required Game game,
  required AdvancedStartType startType,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) {
  var updated = applyAdvancedStartPlayerDevelopment(
    game: game,
    startType: startType,
    tileMapByRegion: tileMapByRegion,
  );
  updated = applyAdvancedStartMinorDevelopment(
    game: updated,
    startType: startType,
    tileMapByRegion: tileMapByRegion,
  );
  updated = applyAdvancedStartNwProvinceRoads(
    game: updated,
    startType: startType,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
  );
  return updated;
}
