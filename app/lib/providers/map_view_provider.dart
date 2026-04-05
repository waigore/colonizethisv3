import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/map_terrain_config.dart';
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

  final visibilityByTile = <String, TileVisibility>{};
  view.visibilityByTile.forEach((tileKey, level) {
    late TileVisibility visibility;
    switch (level) {
      case VisibilityLevel.fullyVisible:
        visibility = TileVisibility.visible;
        break;
      case VisibilityLevel.fogged:
      case VisibilityLevel.revealed:
        visibility = TileVisibility.fogged;
        break;
      case VisibilityLevel.unknown:
        visibility = TileVisibility.unrevealed;
        break;
    }
    visibilityByTile[tileKey] = visibility;
  });

  return buildInitGameMapViewData(
    game: game,
    tileMapByRegion: mapData.tileMapByRegion,
    topologyByRegion: mapData.topologyByRegion,
    cellSize: MapTerrainConfig.instance.mapCellSizePx,
    greatPowerColorOverride: colorOverride,
    visibilityByTile: visibilityByTile,
    warpLinks: mapData.warpLinks,
  );
});
