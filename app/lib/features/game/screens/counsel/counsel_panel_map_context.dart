// Map topology/tile data for counsel tab hosts (`GAME90001`, Refs #4688).

import 'package:colonizethis_data/colonizethis_data.dart';

import '../../../../core/services/game_service/game_service.dart' show GameMapData;

CounselPanelMapContext counselPanelMapContextFromLoaded(GameMapData? loaded) {
  var topology = const MapTopology();
  var tileMapByRegion = const <String, TileMapResult>{};
  if (loaded != null) {
    topology = loaded.combinedTopology;
    tileMapByRegion = loaded.tileMapByRegion;
  }
  return CounselPanelMapContext(
    topology: topology,
    tileMapByRegion: tileMapByRegion,
  );
}

final class CounselPanelMapContext {
  const CounselPanelMapContext({
    required this.topology,
    required this.tileMapByRegion,
  });

  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
}
