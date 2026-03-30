import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:hive/hive.dart';

final _log = saveLogger();

const String _suffixTileMapByRegion = '_tileMapByRegion';
const String _suffixTopologyByRegion = '_topologyByRegion';
const String _suffixCombinedTopology = '_combinedTopology';
const String _suffixWarpLinks = '_warpLinks';

/// Saves and loads [Game] state to/from a Hive box. One entry per game, keyed by [Game.id].
/// Optional map data (tile maps, topology) can be stored per game for Load Savegame view. See SPEC/program/save-load.md.
class GameSaveAdapter {
  /// Saves [game] to [box]. Key = game.id, value = game.toJson().
  void save(Box<dynamic> box, Game game) {
    _log.i('saving gameId=${game.id}');
    box.put(game.id, game.toJson());
    _log.i('saved gameId=${game.id}');
  }

  /// Loads game by [gameId]. Returns null if not found or invalid.
  Game? load(Box<dynamic> box, String gameId) {
    _log.i('loading gameId=$gameId');
    final raw = box.get(gameId);
    if (raw == null) {
      _log.w('gameId=$gameId not found');
      return null;
    }
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      final game = Game.fromJson(map);
      _log.i('loaded gameId=$gameId');
      return game;
    } catch (e, st) {
      _log.e('load failed gameId=$gameId', error: e, stackTrace: st);
      return null;
    }
  }

  /// Lists all game ids stored in [box]. Excludes internal map-data keys.
  ///
  /// A key is treated as a game id unless it ends with a map-data suffix AND
  /// its prefix exists as a separate key in the box (proving it is map data for
  /// that game). This ensures game ids like `mygame_tileMapByRegion` are not
  /// incorrectly excluded when no corresponding `mygame` key exists.
  List<String> listGameIds(Box<dynamic> box) {
    final allKeys = box.keys.whereType<String>().toSet();

    final definiteGameIds = allKeys
        .where(
          (k) =>
              !k.endsWith(_suffixTileMapByRegion) &&
              !k.endsWith(_suffixTopologyByRegion) &&
              !k.endsWith(_suffixCombinedTopology) &&
              !k.endsWith(_suffixWarpLinks),
        )
        .toSet();

    final result = <String>[...definiteGameIds];

    for (final key in allKeys) {
      if (key.endsWith(_suffixTileMapByRegion)) {
        final prefix = key.substring(
          0,
          key.length - _suffixTileMapByRegion.length,
        );
        if (!definiteGameIds.contains(prefix)) result.add(key);
      } else if (key.endsWith(_suffixTopologyByRegion)) {
        final prefix = key.substring(
          0,
          key.length - _suffixTopologyByRegion.length,
        );
        if (!definiteGameIds.contains(prefix)) result.add(key);
      } else if (key.endsWith(_suffixCombinedTopology)) {
        final prefix = key.substring(
          0,
          key.length - _suffixCombinedTopology.length,
        );
        if (!definiteGameIds.contains(prefix)) result.add(key);
      } else if (key.endsWith(_suffixWarpLinks)) {
        final prefix = key.substring(0, key.length - _suffixWarpLinks.length);
        if (!definiteGameIds.contains(prefix)) result.add(key);
      }
    }

    return result;
  }

  /// Saves map data for [gameId] so Load Savegame can build InitGameMapViewData. Optional; legacy saves have none.
  void saveMapData(
    Box<dynamic> box,
    String gameId, {
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, MapTopology> topologyByRegion,
    required MapTopology combinedTopology,
    List<WarpLink>? warpLinks,
  }) {
    _log.d('saving map data gameId=$gameId');
    box.put(
      gameId + _suffixTileMapByRegion,
      tileMapByRegion.map((k, v) => MapEntry(k, v.toJson())),
    );
    box.put(
      gameId + _suffixTopologyByRegion,
      topologyByRegion.map((k, v) => MapEntry(k, v.toJson())),
    );
    box.put(gameId + _suffixCombinedTopology, combinedTopology.toJson());
    if (warpLinks != null) {
      box.put(
        gameId + _suffixWarpLinks,
        warpLinks.map((l) => l.toJson()).toList(),
      );
    }
    _log.d('saved map data gameId=$gameId');
  }

  /// Loads map data for [gameId]. Returns null if any key is missing (legacy save).
  /// Warp links are optional for backward compatibility with legacy saves.
  ({
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    MapTopology combinedTopology,
    List<WarpLink>? warpLinks,
  })?
  loadMapData(Box<dynamic> box, String gameId) {
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
      final combinedTopology = MapTopology.fromJson(
        Map<String, dynamic>.from(combinedRaw as Map),
      );
      // Warp links are optional for backward compatibility.
      final warpRaw = box.get(gameId + _suffixWarpLinks);
      List<WarpLink>? warpLinks;
      if (warpRaw != null) {
        warpLinks = (warpRaw as List)
            .map((l) => WarpLink.fromJson(Map<String, dynamic>.from(l as Map)))
            .toList();
      }
      _log.d('loaded map data gameId=$gameId');
      return (
        tileMapByRegion: tileMapByRegion,
        topologyByRegion: topologyByRegion,
        combinedTopology: combinedTopology,
        warpLinks: warpLinks,
      );
    } catch (e, st) {
      _log.e(
        'load map data failed gameId=$gameId',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Deletes game [gameId] from [box]. No-op if not present. Also removes map data keys.
  void delete(Box<dynamic> box, String gameId) {
    box.delete(gameId);
    box.delete(gameId + _suffixTileMapByRegion);
    box.delete(gameId + _suffixTopologyByRegion);
    box.delete(gameId + _suffixCombinedTopology);
    box.delete(gameId + _suffixWarpLinks);
  }
}
