import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

import 'game_service.dart';

/// Cached map data for a game (topology and tile maps for turn resolution).
class GameMapCache {
  GameMapCache({
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

/// In-memory turn-trace session state for one game id.
class TurnTraceSession {
  TurnTraceSession({required this.startedAtUtc});
  final DateTime startedAtUtc;
  final List<TurnTracePhaseTrace> phases = <TurnTracePhaseTrace>[];
  final TurnTraceRuntime turnTraceRuntime = TurnTraceRuntime();
  List<TurnTraceAiSection>? aiTraceSections;
}

/// Mutable session state shared by [GameService] implementation libraries.
class GameServiceState {
  GameServiceState({
    required this.box,
    required this.adapter,
    required this.turnTraceEnabled,
    required this.turnTraceRootDirectory,
  });
  final Box<dynamic> box;
  final GameSaveAdapter adapter;
  final bool turnTraceEnabled;
  final String turnTraceRootDirectory;
  final Map<String, GameMapCache> mapCache = <String, GameMapCache>{};
  final Map<String, TurnTraceSession> turnTraceSessionsByGameId =
      <String, TurnTraceSession>{};
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
final gameServiceMapGenPassLog = packageLogger('tile_map');

GameMapCache gameServiceRequireMapData(GameService service, String gameId) {
  final cached = service.state.mapCache[gameId];
  if (cached != null) return cached;
  final mapData = service.state.adapter.loadMapData(service.state.box, gameId);
  final loaded = GameMapCache(
    combinedTopology: mapData.combinedTopology,
    tileMapByRegion: mapData.tileMapByRegion,
    topologyByRegion: mapData.topologyByRegion,
    warpLinks: mapData.warpLinks,
  );
  service.state.mapCache[gameId] = loaded;
  return loaded;
}

Game? gameServiceLoadGame(GameService service, String gameId) =>
    gameServiceLoadGameSession(service, gameId)?.game;

GameSaveSession? gameServiceLoadGameSession(
  GameService service,
  String gameId,
) {
  final session = service.state.adapter.loadSession(service.state.box, gameId);
  if (session == null) return null;
  try {
    gameServiceRequireMapData(service, gameId);
    return session;
  } catch (e, st) {
    packageLogger().e(
      'required map data missing/invalid for gameId=$gameId',
      error: e,
      stackTrace: st,
    );
    return null;
  }
}

GameMapData? gameServiceGetMapData(GameService service, String gameId) {
  final cached = service.state.mapCache[gameId];
  if (cached != null) {
    return (
      combinedTopology: cached.combinedTopology,
      tileMapByRegion: cached.tileMapByRegion,
      topologyByRegion: cached.topologyByRegion,
      warpLinks: cached.warpLinks,
    );
  }
  final gameExists =
      service.state.adapter.load(service.state.box, gameId) != null;
  if (!gameExists) return null;
  final cache = gameServiceRequireMapData(service, gameId);
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
gameServiceRequiredMapDataView(GameService service, String gameId) {
  final cache = gameServiceRequireMapData(service, gameId);
  return (
    combinedTopology: cache.combinedTopology,
    tileMapByRegion: cache.tileMapByRegion,
    topologyByRegion: cache.topologyByRegion,
    warpLinks: cache.warpLinks,
  );
}

void gameServiceSaveGame(GameService service, Game game) {
  final toSave = service.prepareGameForPersistence?.call(game) ?? game;
  service.state.adapter.save(service.state.box, toSave);
}

void gameServiceSaveGameSession(
  GameService service, {
  required Game sessionGame,
  required String saveGameId,
  required Orders draftOrders,
  required Map<String, int> productionDesiredOutputByRecipe,
  String? displayName,
  required bool mirrorAutoSave,
}) {
  final preparedBase =
      service.prepareGameForPersistence?.call(sessionGame) ?? sessionGame;
  final toSave = preparedBase.copyWith(id: saveGameId);
  final md = gameServiceRequiredMapDataView(service, sessionGame.id);
  service.state.adapter.save(
    service.state.box,
    toSave,
    draftOrders: draftOrders,
    productionDesiredOutputByRecipe: productionDesiredOutputByRecipe,
    displayName: displayName,
  );
  service.state.adapter.saveMapData(
    service.state.box,
    saveGameId,
    tileMapByRegion: md.tileMapByRegion,
    topologyByRegion: md.topologyByRegion,
    combinedTopology: md.combinedTopology,
    warpLinks: md.warpLinks,
  );
  service.state.mapCache[saveGameId] = GameMapCache(
    combinedTopology: md.combinedTopology,
    tileMapByRegion: md.tileMapByRegion,
    topologyByRegion: md.topologyByRegion,
    warpLinks: md.warpLinks,
  );
  if (mirrorAutoSave) {
    gameServiceMirrorAutoSave(
      service,
      preparedBase,
      draftOrders: draftOrders,
      productionDesiredOutputByRecipe: productionDesiredOutputByRecipe,
      displayName: displayName,
    );
  }
}

List<String> gameServiceListGameIds(GameService service) =>
    service.state.adapter.listGameIds(service.state.box);

List<LoadableSaveEntry> gameServiceListLoadableSaves(GameService service) =>
    service.state.adapter.listLoadableSaves(service.state.box);

bool gameServiceHasValidAutoSave(GameService service) =>
    service.state.adapter.hasValidAutoSave(service.state.box);

Game? gameServiceLoadAutoSaveGame(GameService service) =>
    gameServiceLoadAutoSaveSession(service)?.game;

GameSaveSession? gameServiceLoadAutoSaveSession(GameService service) {
  if (!service.state.adapter.hasValidAutoSave(service.state.box)) {
    return null;
  }
  final session =
      service.state.adapter.loadSession(service.state.box, kAutoSaveSlotId);
  if (session == null) {
    return null;
  }
  try {
    final mapData =
        service.state.adapter.loadMapData(service.state.box, kAutoSaveSlotId);
    service.state.mapCache[session.game.id] = GameMapCache(
      combinedTopology: mapData.combinedTopology,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
      warpLinks: mapData.warpLinks,
    );
    return session;
  } catch (e, st) {
    packageLogger().e(
      'save: loadAutoSaveGame failed',
      error: e,
      stackTrace: st,
    );
    service.state.adapter.delete(service.state.box, kAutoSaveSlotId);
    return null;
  }
}

void gameServiceMirrorAutoSave(
  GameService service,
  Game game, {
  Orders draftOrders = const Orders(),
  Map<String, int> productionDesiredOutputByRecipe = const <String, int>{},
  String? displayName,
}) {
  try {
    final md = gameServiceRequiredMapDataView(service, game.id);
    service.state.adapter.saveAutoSave(
      service.state.box,
      game,
      tileMapByRegion: md.tileMapByRegion,
      topologyByRegion: md.topologyByRegion,
      combinedTopology: md.combinedTopology,
      warpLinks: md.warpLinks,
      draftOrders: draftOrders,
      productionDesiredOutputByRecipe: productionDesiredOutputByRecipe,
      displayName: displayName,
    );
  } catch (e, st) {
    packageLogger().e(
      'save: auto-save mirror failed',
      error: e,
      stackTrace: st,
    );
  }
}
