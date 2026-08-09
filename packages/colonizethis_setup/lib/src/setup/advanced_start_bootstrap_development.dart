// Advanced-start tile development (steps 11–12). SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'advanced_start_bootstrap_development_tiles.dart';
import 'advanced_start_bootstrap_roads.dart';
import 'advanced_start_selection.dart';
import 'setup_logging.dart';

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
        updated = applyAdvancedStartPlayerProvinceDevelopment(
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
    final buyerId = minorBuyerIdRoundRobin(game, i);
    final buyerProspected =
        updated.worldState.playerProspectedTiles[buyerId] ?? const <String>{};
    final tileKeysByProvince =
        game.worldState.tileKeysByRegionAndProvince[kRegionOldWorld] ??
        const <String, List<String>>{};

    final developable = <String>[];
    for (final province in game.worldState.oldWorld.provinces) {
      if (province.ownerId != minor.id) continue;
      developable.addAll(
        rankDevelopableAdvancedStartTileKeys(
          tileKeys: tileKeysByProvince[province.id] ?? const [],
          resourceByTileKey: game.worldState.resourceByTileKey,
          prospectedTileKeys: buyerProspected,
        ),
      );
    }
    if (developable.isEmpty) continue;

    final selected = selectByFractionCeil(developable, fraction);
    for (final key in selected) {
      purchased[key] = buyerId;
      tileState = tileState.setImprovement(key, 1);
    }

    for (final province in game.worldState.oldWorld.provinces) {
      if (province.ownerId != minor.id) continue;
      final provinceFullId = ProvinceId.prefixedFrom(
        province.regionId,
        province.id,
      );
      final provinceSelected = selected.where((key) {
        final coords = parseTileKeyCoordinates(key);
        if (coords == null) return false;
        return ProvinceId.full(coords.regionId, coords.provinceLocalId) ==
            provinceFullId;
      }).toList();
      if (provinceSelected.isEmpty) continue;
      final hub = hubTileKeyForAdvancedStartProvince(
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
      updated = applyAdvancedStartDevelopmentRoadsFromTilesToHub(
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
