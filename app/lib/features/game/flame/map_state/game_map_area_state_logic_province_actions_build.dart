import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

import 'game_map_area_province_action_states.dart';
import 'game_map_area_province_action_states_assignable.dart'
    show ProvinceInlineActionState;

/// Build/purchase overlay forwarders for [GameMapAreaStateLogicProvinceActions].
abstract final class GameMapAreaStateLogicProvinceBuildActions {
  static ProvinceInlineActionState provinceBuildImprovementActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStates.buildImprovement(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: topology,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  static ProvinceInlineActionState provinceBuildRoadActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStates.buildRoad(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: topology,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  static ProvinceInlineActionState provinceBuildFortActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStates.buildFort(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: topology,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  static ProvinceInlineActionState provinceBuildPortActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStates.buildPort(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: topology,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  static ProvinceInlineActionState provinceBuildRailActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStates.buildRail(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: topology,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  static ProvinceInlineActionState provincePurchaseLandActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStates.purchaseLand(
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
