part of 'game_map_area_state_logic.dart';

class _GameMapAreaStateLogicApiShellWork {
  static bool allowsFullTurnResolution(ct_models.Game game) =>
      GameMapAreaStateLogicShell.allowsFullTurnResolution(game);

  static const ({bool showIcon, bool enabled, bool hasExplorerUnits})
  kHiddenExplorerInlineActionState =
      GameMapAreaProvinceActionStates.kHiddenExplorerInlineActionState;
  static const ({bool showIcon, bool enabled, bool hasBuilderUnits})
  kHiddenBuilderInlineActionState =
      GameMapAreaProvinceActionStates.kHiddenBuilderInlineActionState;

  static int regionIndexFromWorldRegionId(String regionId) =>
      GameMapAreaStateLogicShell.regionIndexFromWorldRegionId(regionId);

  static ShellEntryAutoCenter? resolveShellEntryAutoCenter({
    required ct_models.Game game,
    required String? currentPlayerId,
  }) =>
      GameMapAreaStateLogicShell.resolveShellEntryAutoCenter(
        game: game,
        currentPlayerId: currentPlayerId,
      );

  static String translateWorkTargetTileKey({
    required String tileKey,
    required String workTarget,
  }) =>
      GameMapAreaStateLogicShell.translateWorkTargetTileKey(
        tileKey: tileKey,
        workTarget: workTarget,
      );

  static const Set<String> kCacheFirstWorkTargets =
      GameMapAreaStateLogicWorkTargets.kCacheFirstWorkTargets;

  static Set<String> filterCacheSelectionForRuntimeStaleTileConflicts({
    required Set<String> cachedTileKeys,
    required ct_models.Game game,
    required ct_models.Orders currentOrders,
    required String playerId,
    required String selectedUnitId,
    required String workTarget,
  }) =>
      GameMapAreaStateLogicWorkTargets
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
      GameMapAreaStateLogicWorkTargets.resolveValidTileKeysForCivilianWorkSelection(
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
      GameMapAreaStateLogicWorkTargets.addHumanWorkOrder(
        orders: orders,
        humanPlayerId: humanPlayerId,
        workOrder: workOrder,
      );

  static String? selectionAfterWorkAssignment({
    required String? currentSelectedCivilianTileKey,
    required String assignedTileKey,
  }) =>
      GameMapAreaStateLogicWorkTargets.selectionAfterWorkAssignment(
        currentSelectedCivilianTileKey: currentSelectedCivilianTileKey,
        assignedTileKey: assignedTileKey,
      );
}
