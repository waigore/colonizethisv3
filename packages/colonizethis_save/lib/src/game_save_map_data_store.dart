import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_save/package_logger.dart';
import 'package:hive/hive.dart';

import 'game_save_keys.dart';

final _log = packageLogger();

/// Saves required map data for [gameId]. Same Hive key suffixes as before.
void saveGameMapData(
  Box<dynamic> box,
  String gameId, {
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  required MapTopology combinedTopology,
  List<WarpLink>? warpLinks,
}) {
  _log.d('saving map data gameId=$gameId');
  box.put(
    gameId + kSuffixTileMapByRegion,
    tileMapByRegion.map((k, v) => MapEntry(k, v.toJson())),
  );
  box.put(
    gameId + kSuffixTopologyByRegion,
    topologyByRegion.map((k, v) => MapEntry(k, v.toJson())),
  );
  box.put(gameId + kSuffixCombinedTopology, combinedTopology.toJson());
  if (warpLinks != null) {
    box.put(
      gameId + kSuffixWarpLinks,
      warpLinks.map((l) => l.toJson()).toList(),
    );
  }
  _log.d('saved map data gameId=$gameId');
}

/// Loads required map data for [gameId].
///
/// Throws [StateError] when any required key is missing.
/// Throws [FormatException] when map data exists but is invalid.
({
  Map<String, TileMapResult> tileMapByRegion,
  Map<String, MapTopology> topologyByRegion,
  MapTopology combinedTopology,
  List<WarpLink>? warpLinks,
})
loadGameMapData(Box<dynamic> box, String gameId) {
  final tileRaw = box.get(gameId + kSuffixTileMapByRegion);
  final topoRaw = box.get(gameId + kSuffixTopologyByRegion);
  final combinedRaw = box.get(gameId + kSuffixCombinedTopology);
  if (tileRaw == null || topoRaw == null || combinedRaw == null) {
    throw StateError('Required map data missing for gameId=$gameId');
  }
  try {
    final tileMapByRegion = (tileRaw as Map<dynamic, dynamic>)
        .map<String, TileMapResult>(
          (k, v) => MapEntry(
            k as String,
            TileMapResult.fromJson(
              Map<String, dynamic>.from(v as Map<dynamic, dynamic>),
            ),
          ),
        );
    final topologyByRegion = (topoRaw as Map<dynamic, dynamic>)
        .map<String, MapTopology>(
          (k, v) => MapEntry(
            k as String,
            MapTopology.fromJson(
              Map<String, dynamic>.from(v as Map<dynamic, dynamic>),
            ),
          ),
        );
    final combinedTopology = MapTopology.fromJson(
      Map<String, dynamic>.from(combinedRaw as Map<dynamic, dynamic>),
    );
    // Warp links are optional for backward compatibility.
    final warpRaw = box.get(gameId + kSuffixWarpLinks);
    List<WarpLink>? warpLinks;
    if (warpRaw != null) {
      warpLinks = (warpRaw as List<dynamic>)
          .map(
            (l) => WarpLink.fromJson(
              Map<String, dynamic>.from(l as Map<dynamic, dynamic>),
            ),
          )
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
    _log.e('load map data failed gameId=$gameId', error: e, stackTrace: st);
    throw FormatException('Invalid map data for gameId=$gameId');
  }
}

/// Deletes map-data sidecar keys for [gameId] (game envelope key untouched).
void deleteGameMapDataKeys(Box<dynamic> box, String gameId) {
  box.delete(gameId + kSuffixTileMapByRegion);
  box.delete(gameId + kSuffixTopologyByRegion);
  box.delete(gameId + kSuffixCombinedTopology);
  box.delete(gameId + kSuffixWarpLinks);
}

/// True when any map-data sidecar key exists for [gameId].
bool hasAnyGameMapDataKey(Box<dynamic> box, String gameId) {
  return box.containsKey(gameId + kSuffixTileMapByRegion) ||
      box.containsKey(gameId + kSuffixTopologyByRegion) ||
      box.containsKey(gameId + kSuffixCombinedTopology) ||
      box.containsKey(gameId + kSuffixWarpLinks);
}
