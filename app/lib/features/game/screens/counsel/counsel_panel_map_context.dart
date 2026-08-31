// Map topology/tile data for counsel tab hosts (`GAME90001`, Refs #4688).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/game_service/try_get_game_map_data.dart';
import '../../../../providers/game_service_provider.dart';

CounselPanelMapContext resolveCounselPanelMapContext(WidgetRef ref, Game game) {
  var topology = const MapTopology();
  var tileMapByRegion = const <String, TileMapResult>{};
  final loaded = tryGetGameMapData(
    () => ref.watch(gameServiceProvider).getMapData(game.id),
  );
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
