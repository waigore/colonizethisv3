part of 'game_service.dart';

/// Cached map data for a game (topology and tile maps for turn resolution).
class _GameMapCache {
  _GameMapCache({
    required this.combinedTopology,
    required this.tileMapByRegion,
    required this.topologyByRegion,
    this.warpLinks,
  });
  final MapTopology combinedTopology;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, MapTopology> topologyByRegion;
  final List<WarpLink>? warpLinks;
}

/// Public record type for [GameService.getMapData] (Refs #2575 Phase 4).
/// Lets callers replace `dynamic` with an explicit type while still using
/// record-style access (`mapData.combinedTopology`, etc.).
typedef GameMapData = ({
  MapTopology combinedTopology,
  Map<String, TileMapResult> tileMapByRegion,
  Map<String, MapTopology> topologyByRegion,
  List<WarpLink>? warpLinks,
});

/// Pass milestones for in-app tile map generation (SPEC/program/logging/map-generation.md).
final _mapGenPassLog = packageLogger('tile_map');

_GameMapCache _gameServiceRequireMapData(GameService service, String gameId) {
  final cached = service._mapCache[gameId];
  if (cached != null) return cached;
  final mapData = service._adapter.loadMapData(service._box, gameId);
  final loaded = _GameMapCache(
    combinedTopology: mapData.combinedTopology,
    tileMapByRegion: mapData.tileMapByRegion,
    topologyByRegion: mapData.topologyByRegion,
    warpLinks: mapData.warpLinks,
  );
  service._mapCache[gameId] = loaded;
  return loaded;
}

Game? _gameServiceLoadGame(GameService service, String gameId) {
  final game = service._adapter.load(service._box, gameId);
  if (game == null) return null;
  try {
    _gameServiceRequireMapData(service, gameId);
    return game;
  } catch (e, st) {
    packageLogger().e(
      'required map data missing/invalid for gameId=$gameId',
      error: e,
      stackTrace: st,
    );
    return null;
  }
}

GameMapData? _gameServiceGetMapData(GameService service, String gameId) {
  final cached = service._mapCache[gameId];
  if (cached != null) {
    return (
      combinedTopology: cached.combinedTopology,
      tileMapByRegion: cached.tileMapByRegion,
      topologyByRegion: cached.topologyByRegion,
      warpLinks: cached.warpLinks,
    );
  }
  final gameExists = service._adapter.load(service._box, gameId) != null;
  if (!gameExists) return null;
  final cache = _gameServiceRequireMapData(service, gameId);
  return (
    combinedTopology: cache.combinedTopology,
    tileMapByRegion: cache.tileMapByRegion,
    topologyByRegion: cache.topologyByRegion,
    warpLinks: cache.warpLinks,
  );
}

({
  MapTopology combinedTopology,
  Map<String, TileMapResult> tileMapByRegion,
  Map<String, MapTopology> topologyByRegion,
  List<WarpLink>? warpLinks,
})
_gameServiceRequiredMapDataView(GameService service, String gameId) {
  final cache = _gameServiceRequireMapData(service, gameId);
  return (
    combinedTopology: cache.combinedTopology,
    tileMapByRegion: cache.tileMapByRegion,
    topologyByRegion: cache.topologyByRegion,
    warpLinks: cache.warpLinks,
  );
}

void _gameServiceSaveGame(GameService service, Game game) {
  final toSave = service.prepareGameForPersistence?.call(game) ?? game;
  service._adapter.save(service._box, toSave);
}

List<String> _gameServiceListGameIds(GameService service) =>
    service._adapter.listGameIds(service._box);

bool _gameServiceHasValidAutoSave(GameService service) =>
    service._adapter.hasValidAutoSave(service._box);

Game? _gameServiceLoadAutoSaveGame(GameService service) {
  if (!service._adapter.hasValidAutoSave(service._box)) {
    return null;
  }
  final game = service._adapter.load(service._box, kAutoSaveSlotId);
  if (game == null) {
    return null;
  }
  try {
    final mapData = service._adapter.loadMapData(service._box, kAutoSaveSlotId);
    service._mapCache[game.id] = _GameMapCache(
      combinedTopology: mapData.combinedTopology,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
      warpLinks: mapData.warpLinks,
    );
    return game;
  } catch (e, st) {
    packageLogger().e(
      'save: loadAutoSaveGame failed',
      error: e,
      stackTrace: st,
    );
    service._adapter.delete(service._box, kAutoSaveSlotId);
    return null;
  }
}

void _gameServiceMirrorAutoSave(GameService service, Game game) {
  try {
    final md = _gameServiceRequiredMapDataView(service, game.id);
    service._adapter.saveAutoSave(
      service._box,
      game,
      tileMapByRegion: md.tileMapByRegion,
      topologyByRegion: md.topologyByRegion,
      combinedTopology: md.combinedTopology,
      warpLinks: md.warpLinks,
    );
  } catch (e, st) {
    packageLogger().e(
      'save: auto-save mirror failed',
      error: e,
      stackTrace: st,
    );
  }
}
