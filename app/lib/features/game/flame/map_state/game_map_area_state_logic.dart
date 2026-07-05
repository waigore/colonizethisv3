import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart';

import 'game_map_area_civilian_draft_projection.dart';
import 'game_map_area_fleet_draft_projection.dart';
import 'game_map_area_province_action_states.dart';

part 'game_map_area_state_logic_work_targets.dart';
part 'game_map_area_state_logic_draft_projection.dart';
part 'game_map_area_state_logic_province_actions.dart';

/// Resolved mount-time / home-to-capital auto-center target for the in-game
/// shell. SPEC/ui/empire-overview.md § Initial map viewport (shell entry).
class ShellEntryAutoCenter {
  const ShellEntryAutoCenter({
    required this.tileKey,
    required this.regionIndex,
  });

  /// Capital tile key (`regionId|localId|x|y`) to center on and highlight.
  final String tileKey;

  /// Region tab index for the capital region (`0` oldWorld, `1` newWorld).
  final int regionIndex;
}

/// Pure-ish helpers for `GameMapArea` state translation.
///
/// Splits per `SPEC/program/dart-file-non-comment-line-size.md` and #2575
/// work item 11. Detailed projection and province-action pipelines live in
/// dedicated modules; this class keeps the public entry points used by the
/// `GameMapArea` widget, tests, and the order-suggestions SPEC pointer
/// (`SPEC/program/order-suggestions.md` § Authoritative pipeline).
class GameMapAreaStateLogic {
  /// Full turn resolution is a no-op once military [Game.victory] is set or the
  /// campaign calendar cap has been reached ([Game.calendarCampaignHalted]).
  /// SPEC/game/victory.md § UI blocking.
  static bool allowsFullTurnResolution(ct_models.Game game) {
    return !game.calendarCampaignHalted && game.victory == null;
  }

  static const ({bool showIcon, bool enabled, bool hasExplorerUnits})
  kHiddenExplorerInlineActionState =
      GameMapAreaProvinceActionStates.kHiddenExplorerInlineActionState;
  static const ({bool showIcon, bool enabled, bool hasBuilderUnits})
  kHiddenBuilderInlineActionState =
      GameMapAreaProvinceActionStates.kHiddenBuilderInlineActionState;

  static int regionIndexFromWorldRegionId(String regionId) {
    if (regionId == kRegionNewWorld) return 1;
    return 0; // oldWorld (default)
  }

  /// Resolves the in-game shell auto-center target for [currentPlayerId].
  ///
  /// Returns `null` when auto-center must be skipped: [currentPlayerId] is
  /// `null` (global observe has no viewing player) or that player has no
  /// `capitalTile`. SPEC/ui/empire-overview.md § Initial map viewport.
  static ShellEntryAutoCenter? resolveShellEntryAutoCenter({
    required ct_models.Game game,
    required String? currentPlayerId,
  }) {
    if (currentPlayerId == null) {
      return null;
    }
    final capital = game.playerById(currentPlayerId)?.capitalTile;
    if (capital == null) {
      return null;
    }
    return ShellEntryAutoCenter(
      tileKey: capital.toTileKey(),
      regionIndex: regionIndexFromWorldRegionId(capital.regionId),
    );
  }

  /// Work-target tile translation hook for assignment flows.
  ///
  /// Civilian draft projection and locate use exact assigned tile keys for every
  /// work target, so no target-specific tile normalization is applied here.
  static String translateWorkTargetTileKey({
    required String tileKey,
    required String workTarget,
  }) {
    if (workTarget.isEmpty) return tileKey;
    return tileKey;
  }

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

  static RegionMapViewData projectCivilianMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    Set<String>? civilianMarkerOwnerIds,
  }) =>
      GameMapAreaStateLogicDraftProjection.projectCivilianMarkersForHumanDraft(
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
      GameMapAreaStateLogicDraftProjection.projectFleetMarkersForHumanDraft(
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
      GameMapAreaStateLogicDraftProjection.projectHumanDraftMarkersForRegion(
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
