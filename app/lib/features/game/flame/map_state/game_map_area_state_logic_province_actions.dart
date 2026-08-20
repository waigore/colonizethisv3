import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states.dart';
import 'game_map_area_province_action_states_assignable.dart'
    show ProvinceInlineActionState;
import 'game_map_area_province_action_states_establish_consulate.dart';
import 'game_map_area_province_action_states_offer_peace.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

/// Province-overlay inline action state helpers for [GameMapAreaStateLogic].
abstract final class GameMapAreaStateLogicProvinceActions {
  /// Returns province-overlay prospect action visibility + enablement.
  ///
  /// Thin forwarder to [GameMapAreaProvinceActionStates.prospect] (#2575).
  static ProvinceInlineActionState provinceProspectActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    required MapTopology? topology,
    required ct_models.Orders currentOrders,
    required Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStates.prospect(
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
  }) => GameMapAreaProvinceActionStates.buildExploreEligibleTileKeyCache(
    game: game,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    currentOrders: currentOrders,
  );

  static ProvinceInlineActionState provinceExploreActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required RegionMapViewData selectedRegion,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    Set<String>? cachedExploreEligibleTileKeys,
  }) => GameMapAreaProvinceActionStates.explore(
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

  static ({
    bool showControl,
    bool enabled,
    bool hasBuilderUnits,
    String? townTileKey,
  })
  provinceUpgradeTownActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String provinceId,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStates.upgradeTown(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: topology,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  static ProvinceEstablishConsulateActionState
  provinceEstablishConsulateActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String provinceId,
    required MapTopology? topology,
    required ct_models.Orders currentOrders,
  }) => GameMapAreaProvinceActionStates.establishConsulate(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    topology: topology,
    currentOrders: currentOrders,
  );

  static ProvinceOwnerStandingOfferPeaceState provinceOfferPeaceActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String provinceId,
    required MapTopology? topology,
    required ct_models.Orders currentOrders,
    required bool isSeaZone,
  }) => GameMapAreaProvinceActionStates.offerPeace(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    topology: topology,
    currentOrders: currentOrders,
    isSeaZone: isSeaZone,
  );
}
