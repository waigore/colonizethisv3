import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'game_service_provider.dart';
import 'games_provider.dart';

/// Global province/sea boundary strokes on in-game Empire overview maps.
/// Defaults to true at app start; updated via the Map display options dialog.
/// SPEC/ui/map-widget.md, SPEC/ui/empire-overview.md.
final mapProvinceOverlayVisibleProvider = StateProvider<bool>((ref) => true);

/// Great Power land ownership tint on in-game Empire overview maps.
/// Independent of [mapProvinceOverlayVisibleProvider]. Defaults to true at app start.
final mapProvinceOwnershipTintVisibleProvider = StateProvider<bool>((ref) => true);

/// Global land province name labels on in-game Empire overview maps.
/// Independent of boundary and ownership-tint toggles. Defaults to true at app start.
final mapProvinceNamesVisibleProvider = StateProvider<bool>((ref) => true);

/// Map view data for the current game with player-constrained visibility.
/// Null when no game, no map data (legacy save), or loading.
final mapViewDataProvider = Provider<InitGameMapViewData?>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return null;
  final service = ref.watch(gameServiceProvider);
  final mapData = service.getMapData(game.id);
  if (mapData == null) return null;
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
    cellSize: 24,
    greatPowerColorOverride: colorOverride,
    visibilityByTile: visibilityByTile,
    warpLinks: mapData.warpLinks,
  );
});
