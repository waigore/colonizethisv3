// GameService stub + pump facade for province shortcut host-emit tests.
// Refs #4734 Slice I.

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'province_shortcut_host_emit_map_fixtures.dart';
import 'province_shortcut_host_emit_pump.dart';
import 'province_shortcut_host_emit_test_support.dart' show ProvinceShortcutHostCase;

GameService provinceShortcutHostEmitGameService({
  required Box<dynamic> gamesBox,
  required String gameId,
  required MapTopology combinedTopology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) => _ProvinceShortcutHostEmitGameService(
  gamesBox,
  GameSaveAdapter(),
  gameId: gameId,
  combinedTopology: combinedTopology,
  tileMapByRegion: tileMapByRegion,
  topologyByRegion: topologyByRegion,
);

class ProvinceShortcutHostEmitPump {
  ProvinceShortcutHostEmitPump({
    required this.gamesBox,
    required this.gameId,
    required this.humanPlayerId,
    required this.maps,
    required this.region,
    required this.selectedTileKey,
  });

  final Box<dynamic> gamesBox;
  final String gameId;
  final String humanPlayerId;
  final ProvinceShortcutHostMaps maps;
  final RegionMapViewData region;
  final String selectedTileKey;

  Future<List<OpenCivilianUnitsPanelEvent>> call(
    WidgetTester tester, {
    required Game game,
    required ProvinceShortcutHostCase host,
  }) => pumpProvinceShortcutHostAndSelect(
    tester,
    gamesBox: gamesBox,
    gameService: provinceShortcutHostEmitGameService(
      gamesBox: gamesBox,
      gameId: gameId,
      combinedTopology: maps.combinedTopology,
      tileMapByRegion: maps.tileMapByRegion,
      topologyByRegion: maps.topologyByRegion,
    ),
    game: game,
    humanPlayerId: humanPlayerId,
    host: host,
    region: region,
    combinedTopology: maps.combinedTopology,
    workTargetSelectionCache: refreshedProvinceShortcutWorkTargetCache(
      game: game,
      humanPlayerId: humanPlayerId,
      combinedTopology: maps.combinedTopology,
      tileMapByRegion: maps.tileMapByRegion,
    ),
    selectedTileKey: selectedTileKey,
  );
}

class _ProvinceShortcutHostEmitGameService extends GameService {
  _ProvinceShortcutHostEmitGameService(
    super.box,
    super.adapter, {
    required this.gameId,
    required this.combinedTopology,
    required this.tileMapByRegion,
    required this.topologyByRegion,
  });

  final String gameId;
  final MapTopology combinedTopology;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, MapTopology> topologyByRegion;

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String requestedGameId) {
    if (requestedGameId != gameId) return null;
    return (
      combinedTopology: combinedTopology,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      warpLinks: null,
    );
  }
}
