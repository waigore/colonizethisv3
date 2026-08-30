// Shared GameService stub for the six MAP20001 shortcut-host golden suites
// (purchase land, railroad, road, fort, port, improvement). Consulate goldens
// stay out of scope. Refs #4606 Slice A.

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

import 'province_shortcut_host_emit_fixtures.dart';

/// Parameterized `getMapData` stub used by shortcut-host goldens.
class ProvinceShortcutHostGoldenGameService extends GameService {
  ProvinceShortcutHostGoldenGameService(
    Box<dynamic> box,
    GameSaveAdapter adapter, {
    required this.gameId,
    this.includeNewWorld = false,
    this.useCoastalTileMap = true,
  }) : super(box, adapter);

  final String gameId;
  final bool includeNewWorld;
  final bool useCoastalTileMap;

  static MapTopology combinedTopologyFor({bool includeNewWorld = false}) =>
      provinceShortcutHostCombinedTopology(includeNewWorld: includeNewWorld);

  static Map<String, MapTopology> topologyByRegionFor({
    bool includeNewWorld = false,
  }) => provinceShortcutHostTopologyByRegion(includeNewWorld: includeNewWorld);

  static Map<String, TileMapResult> tileMapByRegionFor({
    bool includeNewWorld = false,
    bool useCoastalTileMap = true,
  }) {
    if (useCoastalTileMap) {
      return provinceShortcutHostGoldenCoastalTileMapByRegion(
        includeNewWorld: includeNewWorld,
      );
    }
    return provinceShortcutHostTileMapByRegion(
      includeNewWorld: includeNewWorld,
    );
  }

  @override
  GameMapData? getMapData(String requestedGameId) {
    if (requestedGameId != gameId) return null;
    return (
      combinedTopology: combinedTopologyFor(includeNewWorld: includeNewWorld),
      tileMapByRegion: tileMapByRegionFor(
        includeNewWorld: includeNewWorld,
        useCoastalTileMap: useCoastalTileMap,
      ),
      topologyByRegion: topologyByRegionFor(includeNewWorld: includeNewWorld),
      warpLinks: null,
    );
  }
}
