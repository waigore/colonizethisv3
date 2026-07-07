part of 'game_map_area_state_logic.dart';

/// Pure-ish helpers for `GameMapArea` state translation.
///
/// Splits per `SPEC/program/dart-file-non-comment-line-size.md` and #2575
/// work item 11. Detailed projection and province-action pipelines live in
/// dedicated modules; this class keeps the public entry points used by the
/// `GameMapArea` widget, tests, and the order-suggestions SPEC pointer
/// (`SPEC/program/order-suggestions.md` § Authoritative pipeline).
abstract final class GameMapAreaStateLogic {
  GameMapAreaStateLogic._();

  static bool allowsFullTurnResolution(ct_models.Game game) =>
      _GameMapAreaStateLogicApiShellWork.allowsFullTurnResolution(game);

  static const ({bool showIcon, bool enabled, bool hasExplorerUnits})
  kHiddenExplorerInlineActionState =
      _GameMapAreaStateLogicApiShellWork.kHiddenExplorerInlineActionState;
  static const ({bool showIcon, bool enabled, bool hasBuilderUnits})
  kHiddenBuilderInlineActionState =
      _GameMapAreaStateLogicApiShellWork.kHiddenBuilderInlineActionState;

  static int regionIndexFromWorldRegionId(String regionId) =>
      _GameMapAreaStateLogicApiShellWork.regionIndexFromWorldRegionId(regionId);

  static ShellEntryAutoCenter? resolveShellEntryAutoCenter({
    required ct_models.Game game,
    required String? currentPlayerId,
  }) =>
      _GameMapAreaStateLogicApiShellWork.resolveShellEntryAutoCenter(
        game: game,
        currentPlayerId: currentPlayerId,
      );

  static String translateWorkTargetTileKey({
    required String tileKey,
    required String workTarget,
  }) =>
      _GameMapAreaStateLogicApiShellWork.translateWorkTargetTileKey(
        tileKey: tileKey,
        workTarget: workTarget,
      );

  static const Set<String> kCacheFirstWorkTargets =
      _GameMapAreaStateLogicApiShellWork.kCacheFirstWorkTargets;

  static Set<String> filterCacheSelectionForRuntimeStaleTileConflicts({
    required Set<String> cachedTileKeys,
    required ct_models.Game game,
    required ct_models.Orders currentOrders,
    required String playerId,
    required String selectedUnitId,
    required String workTarget,
  }) =>
      _GameMapAreaStateLogicApiShellWork
          .filterCacheSelectionForRuntimeStaleTileConflicts(
        cachedTileKeys: cachedTileKeys,
        game: game,
        currentOrders: currentOrders,
        playerId: playerId,
        selectedUnitId: selectedUnitId,
        workTarget: workTarget,
      );

  static Set<String> resolveValidTileKeysForCivilianWorkSelection({
    required String workTarget,
    required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
    required String humanPlayerId,
    required String selectedUnitId,
    required ct_models.Game game,
    required ct_models.Orders currentOrders,
    required PlayerView playerView,
    required MapTopology topology,
    required Map<String, TileMapResult>? tileMapByRegion,
  }) =>
      _GameMapAreaStateLogicApiShellWork
          .resolveValidTileKeysForCivilianWorkSelection(
        workTarget: workTarget,
        workTargetSelectionCache: workTargetSelectionCache,
        humanPlayerId: humanPlayerId,
        selectedUnitId: selectedUnitId,
        game: game,
        currentOrders: currentOrders,
        playerView: playerView,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
      );

  static ct_models.Orders addHumanWorkOrder({
    required ct_models.Orders orders,
    required String humanPlayerId,
    required ct_models.WorkOrder workOrder,
  }) =>
      _GameMapAreaStateLogicApiShellWork.addHumanWorkOrder(
        orders: orders,
        humanPlayerId: humanPlayerId,
        workOrder: workOrder,
      );

  static String? selectionAfterWorkAssignment({
    required String? currentSelectedCivilianTileKey,
    required String assignedTileKey,
  }) =>
      _GameMapAreaStateLogicApiShellWork.selectionAfterWorkAssignment(
        currentSelectedCivilianTileKey: currentSelectedCivilianTileKey,
        assignedTileKey: assignedTileKey,
      );

  static RegionMapViewData projectCivilianMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    Set<String>? civilianMarkerOwnerIds,
  }) =>
      _GameMapAreaStateLogicApiDraft.projectCivilianMarkersForHumanDraft(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        civilianMarkerOwnerIds: civilianMarkerOwnerIds,
      );

  static RegionMapViewData projectFleetMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, MapTopology> topologyByRegion,
    required MapTopology combinedTopology,
  }) =>
      _GameMapAreaStateLogicApiDraft.projectFleetMarkersForHumanDraft(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        tileMapByRegion: tileMapByRegion,
        topologyByRegion: topologyByRegion,
        combinedTopology: combinedTopology,
      );

  static RegionMapViewData projectHumanDraftMarkersForRegion({
    required RegionMapViewData baseRegion,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    Map<String, TileMapResult>? tileMapByRegion,
    Map<String, MapTopology>? topologyByRegion,
    MapTopology? combinedTopology,
    Set<String>? civilianMarkerOwnerIds,
  }) =>
      _GameMapAreaStateLogicApiDraft.projectHumanDraftMarkersForRegion(
        baseRegion: baseRegion,
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        tileMapByRegion: tileMapByRegion,
        topologyByRegion: topologyByRegion,
        combinedTopology: combinedTopology,
        civilianMarkerOwnerIds: civilianMarkerOwnerIds,
      );

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
      _GameMapAreaStateLogicApiProvince.provinceProspectActionState(
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
      _GameMapAreaStateLogicApiProvince.buildExploreEligibleTileKeyCache(
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
      _GameMapAreaStateLogicApiProvince.provinceExploreActionState(
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
      _GameMapAreaStateLogicApiProvince.provinceBuildImprovementActionState(
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
