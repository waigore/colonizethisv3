/// Shared radial catalog compute record (Refs #4680 compute-once).
library;

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

String tileRadialProvinceIdFromTileKey(String tileKey) {
  final parsed = tileKey.split('|');
  return parsed.length >= 2 ? '${parsed[0]}|${parsed[1]}' : tileKey;
}

typedef TileRadialUpgradeTownState = ({
  bool showControl,
  bool enabled,
  bool hasBuilderUnits,
  String? townTileKey,
});

/// Shared radial catalog inputs computed once per open/rebuild.
typedef TileRadialHostCatalogContext = ({
  ProvinceActionStates states,
  TileRadialUpgradeTownState upgradeTown,
  String provinceId,
  GameMapData? mapData,
});

TileRadialHostCatalogContext computeTileRadialHostCatalogContext({
  required ct_models.Game game,
  required String humanPlayerId,
  required String tileKey,
  required RegionMapViewData region,
  required PlayerView playerView,
  required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  required ct_models.Orders draftOrders,
  required GameMapData? mapData,
}) {
  final provinceId = tileRadialProvinceIdFromTileKey(tileKey);
  final states = ProvinceActionStateCalculator.compute(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: tileKey,
    region: region,
    playerView: playerView,
    currentOrders: draftOrders,
    workTargetSelectionCache: workTargetSelectionCache,
    mapData: mapData,
  );
  final upgradeTown =
      GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: provinceId,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
        topology: mapData?.combinedTopology,
        currentOrders: draftOrders,
        tileMapByRegion: mapData?.tileMapByRegion,
      );
  return (
    states: states,
    upgradeTown: upgradeTown,
    provinceId: provinceId,
    mapData: mapData,
  );
}
