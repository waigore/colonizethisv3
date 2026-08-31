import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show RegionMapViewData, factionOwnershipColorMapForOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/game_service/try_get_game_map_data.dart';
import '../features/game/screens/victory/victory_political_minimap.dart';
import '../features/game/screens/victory/victory_standings.dart';
import 'development_panel_projection_provider.dart'
    show developmentPanelWorldRevision;
import 'game_service_provider.dart';
import 'games_provider.dart';

typedef VictoryPanelSessionRevision = ({
  String gameId,
  int turnNumber,
  int worldRevision,
});

/// Open-path projections reused across `GAME70001` reopen (Refs #4688 Slice 5).
class VictoryPanelOpenPathSnapshot {
  const VictoryPanelOpenPathSnapshot({
    required this.standings,
    required this.ownershipColors,
    required this.owRegion,
  });

  final List<VictoryStandingRow> standings;
  final Map<String, (int r, int g, int b)> ownershipColors;
  final RegionMapViewData? owRegion;
}

class VictoryPanelSessionCacheState {
  const VictoryPanelSessionCacheState({
    this.revision,
    this.snapshot,
  });

  final VictoryPanelSessionRevision? revision;
  final VictoryPanelOpenPathSnapshot? snapshot;
}

/// Cross-visit cache for `GAME70001` standings + minimap view data.
class VictoryPanelSessionCache {
  VictoryPanelSessionCacheState state = const VictoryPanelSessionCacheState();

  void reset() {
    state = const VictoryPanelSessionCacheState();
  }
}

final victoryPanelSessionCacheProvider = Provider<VictoryPanelSessionCache>(
  (ref) => VictoryPanelSessionCache(),
);

VictoryPanelSessionRevision victoryPanelSessionRevision({required Game game}) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: developmentPanelWorldRevision(game),
  );
}

VictoryPanelOpenPathSnapshot resolveVictoryPanelOpenPath({
  required VictoryPanelSessionCache cache,
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) {
  final revision = victoryPanelSessionRevision(game: game);
  if (cache.state.revision == revision && cache.state.snapshot != null) {
    return cache.state.snapshot!;
  }
  final snapshot = ctAppPerfSync('victory.openPath', () {
    final standings = buildVictoryStandings(game);
    final ownershipColors = factionOwnershipColorMapForOldWorld(game);
    final owRegion = buildVictoryOldWorldMapViewData(
      game: game,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
    );
    return VictoryPanelOpenPathSnapshot(
      standings: standings,
      ownershipColors: ownershipColors,
      owRegion: owRegion,
    );
  });
  cache.state = VictoryPanelSessionCacheState(
    revision: revision,
    snapshot: snapshot,
  );
  return snapshot;
}

/// Session-cached victory open-path snapshot for `GAME70001` (Refs #4688 Slice 5).
final victoryPanelOpenPathProvider =
    Provider.autoDispose<VictoryPanelOpenPathSnapshot?>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return null;
  final mapData = tryGetGameMapData(
    () => ref.watch(gameServiceProvider).getMapData(game.id),
  );
  if (mapData == null) return null;

  return resolveVictoryPanelOpenPath(
    cache: ref.read(victoryPanelSessionCacheProvider),
    game: game,
    tileMapByRegion: mapData.tileMapByRegion,
    topologyByRegion: mapData.topologyByRegion,
  );
});
