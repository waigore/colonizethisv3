import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';

/// Province-overlay inline action state helpers for [GameMapAreaStateLogic].
abstract final class GameMapAreaStateLogicProvinceActions {
  /// Returns province-overlay prospect action visibility + enablement.
  ///
  /// Thin forwarder to [GameMapAreaProvinceActionStates.prospect] (#2575).
  static ({bool showIcon, bool enabled, bool hasExplorerUnits})
  provinceProspectActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    required MapTopology? topology,
    required ct_models.Orders currentOrders,
    required Map<String, TileMapResult>? tileMapByRegion,
  }) =>
      GameMapAreaProvinceActionStates.prospect(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: selectedTileKey,
        playerView: playerView,
        topology: topology,
        currentOrders: currentOrders,
        tileMapByRegion: tileMapByRegion,
      );

  static Set<String> buildExploreEligibleTileKeyCache({
    required ct_models.Game game,
    required String humanPlayerId,
    required PlayerView playerView,
    required MapTopology topology,
    required Map<String, TileMapResult>? tileMapByRegion,
    required ct_models.Orders currentOrders,
  }) =>
      GameMapAreaProvinceActionStates.buildExploreEligibleTileKeyCache(
        game: game,
        humanPlayerId: humanPlayerId,
        playerView: playerView,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        currentOrders: currentOrders,
      );

  static ({bool showIcon, bool enabled, bool hasExplorerUnits})
  provinceExploreActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required RegionMapViewData selectedRegion,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    Set<String>? cachedExploreEligibleTileKeys,
  }) =>
      GameMapAreaProvinceActionStates.explore(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: selectedTileKey,
        selectedRegion: selectedRegion,
        workTargetSelectionCache: workTargetSelectionCache,
        cachedExploreEligibleTileKeys: cachedExploreEligibleTileKeys,
      );

  /// SPEC anchor: `SPEC/program/order-suggestions.md` § Authoritative pipeline
  /// references this method by name; the forwarder keeps that reference valid
  /// after the #2575 module split.
  static ({bool showIcon, bool enabled, bool hasBuilderUnits})
  provinceBuildImprovementActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) =>
      GameMapAreaProvinceActionStates.buildImprovement(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: selectedTileKey,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
        topology: topology,
        currentOrders: currentOrders,
        tileMapByRegion: tileMapByRegion,
      );
}
