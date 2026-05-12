import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/map_terrain_config.dart';
import '../perf/app_perf_trace.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';

/// Global province/sea boundary strokes on in-game Empire overview maps.
/// Defaults to true at app start; updated via the Map display options dialog.
/// SPEC/ui/map-widget.md, SPEC/ui/empire-overview.md.
class MapProvinceOverlayVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

final mapProvinceOverlayVisibleProvider =
    NotifierProvider<MapProvinceOverlayVisibleNotifier, bool>(
      MapProvinceOverlayVisibleNotifier.new,
    );

/// Great Power land ownership tint on in-game Empire overview maps.
/// Independent of [mapProvinceOverlayVisibleProvider]. Defaults to false at app start.
class MapProvinceOwnershipTintVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final mapProvinceOwnershipTintVisibleProvider =
    NotifierProvider<MapProvinceOwnershipTintVisibleNotifier, bool>(
      MapProvinceOwnershipTintVisibleNotifier.new,
    );

/// Global land province name labels on in-game Empire overview maps.
/// Independent of boundary and ownership-tint toggles. Defaults to true at app start.
class MapProvinceNamesVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

final mapProvinceNamesVisibleProvider =
    NotifierProvider<MapProvinceNamesVisibleNotifier, bool>(
      MapProvinceNamesVisibleNotifier.new,
    );

/// Map view data for the current game with player-constrained visibility.
/// Null when no game or loading.
final mapViewDataProvider = Provider<InitGameMapViewData?>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return null;
  return ctAppPerfSync('mapViewDataProvider.build', () {
    final service = ref.watch(gameServiceProvider);
    final mapData = service.getMapData(game.id);
    if (mapData == null) {
      throw StateError('Missing required map data for gameId=${game.id}');
    }
    final colorOverride = greatPowerColorOverrideFromGame(game);

    final humanPlayerId =
        game.players.where((p) => p.isHuman).map((p) => p.id).firstOrNull ??
        game.players.first.id;
    final topology = mapData.combinedTopology;
    final view = buildPlayerView(game, topology, humanPlayerId);
    final humanPlayer =
        game.players.where((p) => p.id == humanPlayerId).firstOrNull ??
        game.players.first;

    final visibilityByTile = <String, TileVisibility>{};
    final byRegion = game.worldState.tileKeysByRegionAndProvince;
    for (final provinceMap in byRegion.values) {
      for (final tileKeys in provinceMap.values) {
        for (final tileKey in tileKeys) {
          final level = view.visibilityForTile(tileKey);
          late TileVisibility visibility;
          switch (level) {
            case VisibilityLevel.fullyVisible:
              visibility = TileVisibility.visible;
              break;
            case VisibilityLevel.fogged:
              visibility = TileVisibility.fogged;
              break;
            case VisibilityLevel.unknown:
              visibility = TileVisibility.unrevealed;
              break;
          }
          visibilityByTile[tileKey] = visibility;
        }
      }
    }

    final connectivity = resolveConnectivity(
      game: game,
      tileMapByRegion: mapData.tileMapByRegion,
      topology: topology,
    );
    final connectivityForHuman = connectivity[humanPlayer.id];
    final resourceExtractionUnitsByTile = <String, int>{};
    final resourceExtractionEffectiveUnitsByTile = <String, int>{};
    final resourceExtractionBlockedUnitsByTile = <String, int>{};
    if (connectivityForHuman != null) {
      final portTileKeys = game.worldState.portsByProvinceSeaboard.values
          .toSet();
      final prospected =
          game.worldState.playerProspectedTiles[humanPlayer.id] ??
          const <String>{};
      final provincesByFullId = {
        for (final p in game.worldState.oldWorld.provinces) p.id: p,
        for (final p in game.worldState.newWorld.provinces) p.id: p,
      };
      for (final tileKey in connectivityForHuman.connected) {
        final parts = tileKey.split('|');
        if (parts.length != 4) {
          continue;
        }
        final regionId = parts[0];
        final localProvinceId = parts[1];
        final ownedByHuman =
            (regionId == 'oldWorld'
                    ? game.worldState.oldWorld.provinces
                    : game.worldState.newWorld.provinces)
                .any(
                  (province) =>
                      province.id == '$regionId|$localProvinceId' &&
                      province.ownerId == humanPlayer.id,
                );
        if (!ownedByHuman) {
          continue;
        }
        final contribution = computeTileExtractionContributionForPlayer(
          game: game,
          tileMapByRegion: mapData.tileMapByRegion,
          player: humanPlayer,
          tileKey: tileKey,
          connectedTileKeys: connectivityForHuman.connected,
          pathTransportCap: connectivityForHuman.pathTransportCap,
          connectedByRoadRule: connectivityForHuman.connectedByRoadRule,
          portTileKeys: portTileKeys,
          prospectedTileKeys: prospected,
          capitalRegionId: humanPlayer.capitalTile?.regionId,
          techCapForPlayer: (id) {
            final player = game.playerById(id);
            return extractionCapForUnlocked(player?.techUnlocked);
          },
          provincesByFullId: provincesByFullId,
        );
        if (contribution == null) {
          continue;
        }
        final improvementLevel = game.worldState.tileState
            .improvementLevel(tileKey)
            .clamp(0, 4);
        final techCap = extractionCapForUnlocked(humanPlayer.techUnlocked);
        final productionUnits =
            (improvementLevel < techCap ? improvementLevel : techCap).clamp(
              0,
              4,
            );
        final effectiveUnits = contribution.units.clamp(0, productionUnits);
        final blockedUnits = (productionUnits - effectiveUnits).clamp(0, 4);
        if (productionUnits <= 0) {
          continue;
        }
        resourceExtractionUnitsByTile[tileKey] = productionUnits;
        resourceExtractionEffectiveUnitsByTile[tileKey] = effectiveUnits;
        resourceExtractionBlockedUnitsByTile[tileKey] = blockedUnits;
      }
    }

    return buildInitGameMapViewData(
      game: game,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
      cellSize: MapTerrainConfig.instance.mapCellSizePx,
      greatPowerColorOverride: colorOverride,
      visibilityByTile: visibilityByTile,
      warpLinks: mapData.warpLinks,
      resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
      resourceExtractionEffectiveUnitsByTile:
          resourceExtractionEffectiveUnitsByTile,
      resourceExtractionBlockedUnitsByTile:
          resourceExtractionBlockedUnitsByTile,
    );
  });
});
