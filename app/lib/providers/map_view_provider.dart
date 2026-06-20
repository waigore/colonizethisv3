import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/map_terrain_config.dart';
import '../features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import '../features/game/shell_player_context.dart';
import '../perf/app_perf_trace.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';

/// Global province/sea boundary strokes on in-game Empire overview maps.
/// Defaults to true at app start; updated via the Map display options dialog.
/// SPEC/ui/map-widget.md, SPEC/ui/empire-overview.md.
final mapProvinceOverlayVisibleProvider =
    NotifierProvider<StateToggleNotifier, bool>(
      () => StateToggleNotifier(true),
    );

/// Great Power land ownership tint on in-game Empire overview maps.
/// Independent of [mapProvinceOverlayVisibleProvider]. Defaults to false at app start.
final mapProvinceOwnershipTintVisibleProvider =
    NotifierProvider<StateToggleNotifier, bool>(
      () => StateToggleNotifier(false),
    );

/// Global land province name labels on in-game Empire overview maps.
/// Independent of boundary and ownership-tint toggles. Defaults to true at app start.
final mapProvinceNamesVisibleProvider =
    NotifierProvider<StateToggleNotifier, bool>(
      () => StateToggleNotifier(true),
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

    final shell = ref.watch(shellPlayerContextProvider);
    final mapPlayerId = shell.mapPlayerIdFor(game);
    final topology = mapData.combinedTopology;
    final view = shell.playerView ??
        buildPlayerView(game, topology, mapPlayerId);
    final mapPlayer =
        game.playerById(mapPlayerId) ??
        game.players.first;

    final visibilityByTile = <String, TileVisibility>{};
    final byRegion = game.worldState.tileKeysByRegionAndProvince;
    final useFullVisibility =
        shell.mapVisibilityMode == CtMapVisibilityMode.full;
    for (final provinceMap in byRegion.values) {
      for (final tileKeys in provinceMap.values) {
        for (final tileKey in tileKeys) {
          final TileVisibility visibility;
          if (useFullVisibility) {
            visibility = TileVisibility.visible;
          } else {
            switch (view.visibilityForTile(tileKey)) {
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
    final connectivityForHuman = connectivity[mapPlayer.id];
    final resourceExtractionUnitsByTile = <String, int>{};
    final resourceExtractionEffectiveUnitsByTile = <String, int>{};
    final resourceExtractionBlockedUnitsByTile = <String, int>{};
    if (connectivityForHuman != null) {
      final portTileKeys = game.worldState.portsByProvinceSeaboard.values
          .toSet();
      final prospected =
          game.worldState.playerProspectedTiles[mapPlayer.id] ??
          const <String>{};
      final provincesByFullId = {
        for (final p in game.worldState.oldWorld.provinces) p.id: p,
        for (final p in game.worldState.newWorld.provinces) p.id: p,
      };
      for (final tileKey in connectivityForHuman.connected) {
        final parsed = tryParseTileKey(tileKey);
        if (parsed == null) {
          continue;
        }
        final regionId = parsed.regionId;
        final localProvinceId = parsed.provinceLocalId;
        final ownedByHuman =
            (regionId == 'oldWorld'
                    ? game.worldState.oldWorld.provinces
                    : game.worldState.newWorld.provinces)
                .any(
                  (province) =>
                      province.id == '$regionId|$localProvinceId' &&
                      province.ownerId == mapPlayer.id,
                );
        if (!ownedByHuman) {
          continue;
        }
        final contribution = computeTileExtractionContributionForPlayer(
          game: game,
          tileMapByRegion: mapData.tileMapByRegion,
          player: mapPlayer,
          tileKey: tileKey,
          connectedTileKeys: connectivityForHuman.connected,
          pathTransportCap: connectivityForHuman.pathTransportCap,
          connectedByRoadRule: connectivityForHuman.connectedByRoadRule,
          portTileKeys: portTileKeys,
          prospectedTileKeys: prospected,
          capitalRegionId: mapPlayer.capitalTile?.regionId,
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
        final techCap = extractionCapForUnlocked(mapPlayer.techUnlocked);
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
      civilianMarkerOwnerIds: civilianMarkerOwnerIdsFor(shell, game),
    );
  });
});

/// Owner set whose civilians get tile markers on the in-game map. Mirrors
/// the observe-mode contract in SPEC/ui/observe-mode.md and avoids relying
/// on `Player.isHuman`, which observe handoff clears for every GP. Returns
/// null when the current shell context implies legacy single-player behavior
/// (the map builder then falls back to its own `isHuman` filter).
Set<String>? civilianMarkerOwnerIdsFor(
  ShellPlayerContext shell,
  Game game,
) {
  // Player observe pins markers to the observed GP only; player chrome stays
  // visible so we use the panel/viewing id rather than the full GP list.
  if (shell.inObservePhase && shell.viewingPlayerId != null) {
    return <String>{shell.viewingPlayerId!};
  }
  // Global observe: every faction with civilians may appear on the map (P6).
  if (shell.inObservePhase) {
    return <String>{
      for (final p in game.players) p.id,
      for (final m in game.minorNations) m.id,
      for (final t in game.tribes) t.id,
    };
  }
  return null;
}
