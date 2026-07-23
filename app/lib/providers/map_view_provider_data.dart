part of 'map_view_provider.dart';

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
    _MapResourceExtractionMaps extractionMaps = const _MapResourceExtractionMaps(
      unitsByTile: {},
      effectiveUnitsByTile: {},
      blockedUnitsByTile: {},
    );
    if (connectivityForHuman != null) {
      extractionMaps = _mapViewBuildResourceExtractionMaps(
        game: game,
        mapPlayer: mapPlayer,
        tileMapByRegion: mapData.tileMapByRegion,
        connectivityForHuman: connectivityForHuman,
      );
    }

    return buildInitGameMapViewData(
      game: game,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
      cellSize: MapTerrainConfig.instance.mapCellSizePx,
      greatPowerColorOverride: colorOverride,
      visibilityByTile: visibilityByTile,
      warpLinks: mapData.warpLinks,
      resourceExtractionUnitsByTile: extractionMaps.unitsByTile,
      resourceExtractionEffectiveUnitsByTile:
          extractionMaps.effectiveUnitsByTile,
      resourceExtractionBlockedUnitsByTile: extractionMaps.blockedUnitsByTile,
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
