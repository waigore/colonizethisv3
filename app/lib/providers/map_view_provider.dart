import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_service_provider.dart';
import 'games_provider.dart';

/// Map view data for the current game. Null when no game, no map data (legacy save), or loading.
final mapViewDataProvider = Provider<InitGameMapViewData?>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return null;
  final service = ref.watch(gameServiceProvider);
  final mapData = service.getMapData(game.id);
  if (mapData == null) return null;
  final colorOverride = greatPowerColorOverrideFromGame(game);
  return buildInitGameMapViewData(
    game: game,
    tileMapByRegion: mapData.tileMapByRegion,
    topologyByRegion: mapData.topologyByRegion,
    cellSize: 24,
    greatPowerColorOverride: colorOverride,
  );
});
