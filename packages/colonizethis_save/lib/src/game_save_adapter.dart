import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

final Logger _log = Logger();

const String _suffixTileMapByRegion = '_tileMapByRegion';
const String _suffixTopologyByRegion = '_topologyByRegion';
const String _suffixCombinedTopology = '_combinedTopology';

/// Saves and loads [Game] state to/from a Hive box. One entry per game, keyed by [Game.id].
/// Optional map data (tile maps, topology) can be stored per game for Load Savegame view. SPEC/project/phase-1, plan-update-gp-colours-save-load.
class GameSaveAdapter {
  /// Saves [game] to [box]. Key = game.id, value = game.toJson().
  void save(Box<dynamic> box, Game game) {
    _log.i('save: saving gameId=${game.id}');
    box.put(game.id, game.toJson());
    _log.i('save: saved gameId=${game.id}');
  }

  /// Loads game by [gameId]. Returns null if not found or invalid.
  Game? load(Box<dynamic> box, String gameId) {
    _log.i('save: loading gameId=$gameId');
    final raw = box.get(gameId);
    if (raw == null) {
      _log.w('save: gameId=$gameId not found');
      return null;
    }
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      final game = Game.fromJson(map);
      _log.i('save: loaded gameId=$gameId');
      return game;
    } catch (e, st) {
      _log.e('save: load failed gameId=$gameId', error: e, stackTrace: st);
      return null;
    }
  }

  /// Lists all game ids stored in [box]. Excludes internal map-data keys.
  List<String> listGameIds(Box<dynamic> box) {
    return box.keys
        .whereType<String>()
        .where((k) =>
            !k.endsWith(_suffixTileMapByRegion) &&
            !k.endsWith(_suffixTopologyByRegion) &&
            !k.endsWith(_suffixCombinedTopology))
        .toList();
  }

  /// Saves map data for [gameId] so Load Savegame can build InitGameMapViewData. Optional; legacy saves have none.
  void saveMapData(
    Box<dynamic> box,
    String gameId, {
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, MapTopology> topologyByRegion,
    required MapTopology combinedTopology,
  }) {
    _log.d('save: saving map data gameId=$gameId');
    box.put(
      gameId + _suffixTileMapByRegion,
      tileMapByRegion.map((k, v) => MapEntry(k, v.toJson())),
    );
    box.put(
      gameId + _suffixTopologyByRegion,
      topologyByRegion.map((k, v) => MapEntry(k, v.toJson())),
    );
    box.put(gameId + _suffixCombinedTopology, combinedTopology.toJson());
    _log.d('save: saved map data gameId=$gameId');
  }

  /// Loads map data for [gameId]. Returns null if any key is missing (legacy save).
  ({Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    MapTopology combinedTopology})? loadMapData(Box<dynamic> box, String gameId) {
    final tileRaw = box.get(gameId + _suffixTileMapByRegion);
    final topoRaw = box.get(gameId + _suffixTopologyByRegion);
    final combinedRaw = box.get(gameId + _suffixCombinedTopology);
    if (tileRaw == null || topoRaw == null || combinedRaw == null) {
      return null;
    }
    try {
      final tileMapByRegion = (tileRaw as Map).map<String, TileMapResult>(
        (k, v) => MapEntry(
          k as String,
          TileMapResult.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
      final topologyByRegion = (topoRaw as Map).map<String, MapTopology>(
        (k, v) => MapEntry(
          k as String,
          MapTopology.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
      final combinedTopology =
          MapTopology.fromJson(Map<String, dynamic>.from(combinedRaw as Map));
      _log.d('save: loaded map data gameId=$gameId');
      return (
        tileMapByRegion: tileMapByRegion,
        topologyByRegion: topologyByRegion,
        combinedTopology: combinedTopology,
      );
    } catch (e, st) {
      _log.e('save: load map data failed gameId=$gameId',
          error: e, stackTrace: st);
      return null;
    }
  }

  /// Deletes game [gameId] from [box]. No-op if not present. Also removes map data keys.
  void delete(Box<dynamic> box, String gameId) {
    box.delete(gameId);
    box.delete(gameId + _suffixTileMapByRegion);
    box.delete(gameId + _suffixTopologyByRegion);
    box.delete(gameId + _suffixCombinedTopology);
  }
}
