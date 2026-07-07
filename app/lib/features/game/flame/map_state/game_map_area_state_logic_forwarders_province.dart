part of 'game_map_area_state_logic.dart';

class _GameMapAreaStateLogicApiProvince {
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
      GameMapAreaStateLogicProvinceActions.provinceProspectActionState(
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
      GameMapAreaStateLogicProvinceActions.buildExploreEligibleTileKeyCache(
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
      GameMapAreaStateLogicProvinceActions.provinceExploreActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: selectedTileKey,
        selectedRegion: selectedRegion,
        workTargetSelectionCache: workTargetSelectionCache,
        cachedExploreEligibleTileKeys: cachedExploreEligibleTileKeys,
      );

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
      GameMapAreaStateLogicProvinceActions.provinceBuildImprovementActionState(
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
