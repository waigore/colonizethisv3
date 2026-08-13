import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_province_action_states_build_improvement.dart';
import 'game_map_area_province_action_states_build_road.dart';
import 'game_map_area_province_action_states_build_fort.dart';
import 'game_map_area_province_action_states_build_port.dart';
import 'game_map_area_province_action_states_explore.dart';
import 'game_map_area_province_action_states_establish_consulate.dart';
import 'game_map_area_province_action_states_prospect.dart';
import 'game_map_area_province_action_states_purchase_land.dart';
import 'game_map_area_province_action_states_upgrade_town.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

/// Province-overlay action visibility/enablement computations for prospect,
/// explore, and build-improvement shortcuts.
///
/// Extracted from `GameMapAreaStateLogic` (#2575 work item 11) so the
/// province action state logic lives in a single, separately testable
/// module. `GameMapAreaStateLogic.province*ActionState` /
/// `buildExploreEligibleTileKeyCache` remain as thin forwarders for backward
/// compatibility with call sites and existing tests, including the SPEC
/// reference in `SPEC/program/order-suggestions.md` § Authoritative pipeline.
class GameMapAreaProvinceActionStates {
  GameMapAreaProvinceActionStates._();

  static const ({bool showIcon, bool enabled, bool hasExplorerUnits})
  kHiddenExplorerInlineActionState = (
    showIcon: false,
    enabled: false,
    hasExplorerUnits: false,
  );
  static const ({bool showIcon, bool enabled, bool hasBuilderUnits})
  kHiddenBuilderInlineActionState = (
    showIcon: false,
    enabled: false,
    hasBuilderUnits: false,
  );
  static const ({bool showIcon, bool enabled, bool hasEngineerUnits})
  kHiddenEngineerInlineActionState = (
    showIcon: false,
    enabled: false,
    hasEngineerUnits: false,
  );
  static const ({bool showIcon, bool enabled, bool hasMerchantUnits})
  kHiddenMerchantInlineActionState = (
    showIcon: false,
    enabled: false,
    hasMerchantUnits: false,
  );

  /// Returns province-overlay prospect action visibility + enablement.
  static ({bool showIcon, bool enabled, bool hasExplorerUnits}) prospect({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    required MapTopology? topology,
    required ct_models.Orders currentOrders,
    required Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStatesProspect.compute(
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
  }) => GameMapAreaProvinceActionStatesExplore.buildEligibleTileKeyCache(
    game: game,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    currentOrders: currentOrders,
  );

  static ({bool showIcon, bool enabled, bool hasExplorerUnits}) explore({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required RegionMapViewData selectedRegion,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    Set<String>? cachedExploreEligibleTileKeys,
  }) => GameMapAreaProvinceActionStatesExplore.compute(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    selectedRegion: selectedRegion,
    workTargetSelectionCache: workTargetSelectionCache,
    cachedExploreEligibleTileKeys: cachedExploreEligibleTileKeys,
  );

  static ({bool showIcon, bool enabled, bool hasBuilderUnits})
  buildImprovement({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStatesBuildImprovement.compute(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: topology,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  static ({bool showIcon, bool enabled, bool hasEngineerUnits}) buildRoad({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStatesBuildRoad.compute(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: topology,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  static ({bool showIcon, bool enabled, bool hasEngineerUnits}) buildFort({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStatesBuildFort.compute(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: topology,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  static ({bool showIcon, bool enabled, bool hasEngineerUnits}) buildPort({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStatesBuildPort.compute(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: topology,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  static ({bool showIcon, bool enabled, bool hasMerchantUnits}) purchaseLand({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStatesPurchaseLand.compute(
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
  upgradeTown({
    required ct_models.Game game,
    required String humanPlayerId,
    required String provinceId,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) => GameMapAreaProvinceActionStatesUpgradeTown.compute(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    topology: topology,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  static ProvinceEstablishConsulateActionState establishConsulate({
    required ct_models.Game game,
    required String humanPlayerId,
    required String provinceId,
    required MapTopology? topology,
    required ct_models.Orders currentOrders,
  }) => GameMapAreaProvinceActionStatesEstablishConsulate.compute(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    topology: topology,
    currentOrders: currentOrders,
  );
}
