import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart';

import 'game_map_area_civilian_draft_projection.dart';
import 'game_map_area_fleet_draft_projection.dart';
import 'game_map_area_province_action_states.dart';

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

  static const Set<String> kCacheFirstWorkTargets = {
    kWorkTargetExplore,
    kWorkTargetStealTech,
    kWorkTargetCounterSpy,
    kWorkTargetPurchaseLand,
    kWorkTargetProspect,
    kWorkTargetBuildImprovement,
    kWorkTargetUpgradeTown,
    kWorkTargetBuildRoad,
    kWorkTargetBuildPort,
    kWorkTargetBuildFort,
    kWorkTargetBuildRail,
  };

  static const Set<String> _runtimeConflictProtectedCacheTargets = {
    kWorkTargetExplore,
    kWorkTargetStealTech,
    kWorkTargetCounterSpy,
    kWorkTargetPurchaseLand,
    kWorkTargetProspect,
    kWorkTargetBuildImprovement,
    kWorkTargetUpgradeTown,
    kWorkTargetBuildRoad,
    kWorkTargetBuildPort,
    kWorkTargetBuildFort,
    kWorkTargetBuildRail,
  };

  /// Filters stale conflict tiles from app-cached work-target selections.
  ///
  /// This is a post-cache set-subtraction guard only: it does not recompute
  /// valid tiles and applies only to targets that use worker-family stale-tile
  /// protection.
  static Set<String> filterCacheSelectionForRuntimeStaleTileConflicts({
    required Set<String> cachedTileKeys,
    required ct_models.Game game,
    required ct_models.Orders currentOrders,
    required String playerId,
    required String selectedUnitId,
    required String workTarget,
  }) {
    if (cachedTileKeys.isEmpty ||
        !_runtimeConflictProtectedCacheTargets.contains(workTarget)) {
      return cachedTileKeys;
    }
    final conflicting = <String>{};
    final pending = currentOrders.workOrdersByPlayerId[playerId] ?? const [];
    for (final order in pending) {
      if (order.targetTileKey.isEmpty || order.unitId == selectedUnitId) {
        continue;
      }
      if (!_runtimeConflictProtectedCacheTargets.contains(order.target)) {
        continue;
      }
      conflicting.add(order.targetTileKey);
    }
    for (final unit in [
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ]) {
      if (unit.ownerId != playerId || unit.id == selectedUnitId) {
        continue;
      }
      final currentWork = unit.currentWork;
      if (currentWork == null || currentWork.tileKey.isEmpty) {
        continue;
      }
      if (!_runtimeConflictProtectedCacheTargets.contains(
        currentWork.workTarget,
      )) {
        continue;
      }
      conflicting.add(currentWork.tileKey);
    }
    if (conflicting.isEmpty) {
      return cachedTileKeys;
    }
    return cachedTileKeys.difference(conflicting);
  }

  /// Resolves selectable work-target tile keys for the civilian map picker.
  ///
  /// [kCacheFirstWorkTargets] read from [workTargetSelectionCache] only (no
  /// live `getValidWorkOrderTileKeysWithVisibility` fallback in that path).
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
  }) {
    if (kCacheFirstWorkTargets.contains(workTarget)) {
      return filterCacheSelectionForRuntimeStaleTileConflicts(
        cachedTileKeys: workTargetSelectionCache.get(humanPlayerId, workTarget),
        game: game,
        currentOrders: currentOrders,
        playerId: humanPlayerId,
        selectedUnitId: selectedUnitId,
        workTarget: workTarget,
      );
    }
    return getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: playerView,
      unitId: selectedUnitId,
      workTarget: workTarget,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
    );
  }

  static ct_models.Orders addHumanWorkOrder({
    required ct_models.Orders orders,
    required String humanPlayerId,
    required ct_models.WorkOrder workOrder,
  }) {
    final prior = List<ct_models.WorkOrder>.from(
      orders.workOrdersByPlayerId[humanPlayerId] ??
          const <ct_models.WorkOrder>[],
    )..removeWhere((o) => o.unitId == workOrder.unitId);
    prior.add(workOrder);
    final movesWithoutUnit = List<ct_models.MoveOrder>.from(
      orders.moveOrdersByPlayerId[humanPlayerId] ??
          const <ct_models.MoveOrder>[],
    )..removeWhere((o) => o.unitId == workOrder.unitId);
    return orders.copyWith(
      moveOrdersByPlayerId: {
        ...orders.moveOrdersByPlayerId,
        humanPlayerId: movesWithoutUnit,
      },
      workOrdersByPlayerId: {
        ...orders.workOrdersByPlayerId,
        humanPlayerId: prior,
      },
    );
  }

  /// Returns the post-assignment civilian selection key.
  /// Keeps selection only when the selected key already points at the assigned
  /// marker tile; otherwise clears stale blink state.
  static String? selectionAfterWorkAssignment({
    required String? currentSelectedCivilianTileKey,
    required String assignedTileKey,
  }) {
    if (currentSelectedCivilianTileKey == assignedTileKey) {
      return currentSelectedCivilianTileKey;
    }
    return null;
  }

  /// Projects player-owned civilian markers using current-turn pending orders.
  ///
  /// Thin forwarder to [GameMapAreaCivilianDraftProjection.project] (#2575).
  static RegionMapViewData projectCivilianMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    Set<String>? civilianMarkerOwnerIds,
  }) =>
      GameMapAreaCivilianDraftProjection.project(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        civilianMarkerOwnerIds: civilianMarkerOwnerIds,
      );

  /// Projects fleet marker tiles using human naval move drafts.
  ///
  /// Thin forwarder to [GameMapAreaFleetDraftProjection.project] (#2575).
  static RegionMapViewData projectFleetMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, MapTopology> topologyByRegion,
    required MapTopology combinedTopology,
  }) =>
      GameMapAreaFleetDraftProjection.project(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        tileMapByRegion: tileMapByRegion,
        topologyByRegion: topologyByRegion,
        combinedTopology: combinedTopology,
      );

  /// Civilian and fleet draft marker projection for one [RegionMapViewData].
  static RegionMapViewData projectHumanDraftMarkersForRegion({
    required RegionMapViewData baseRegion,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    Map<String, TileMapResult>? tileMapByRegion,
    Map<String, MapTopology>? topologyByRegion,
    MapTopology? combinedTopology,
    Set<String>? civilianMarkerOwnerIds,
  }) {
    var projected = GameMapAreaCivilianDraftProjection.project(
      region: baseRegion,
      game: game,
      orders: orders,
      humanPlayerId: humanPlayerId,
      civilianMarkerOwnerIds: civilianMarkerOwnerIds,
    );
    if (tileMapByRegion != null &&
        topologyByRegion != null &&
        combinedTopology != null) {
      projected = GameMapAreaFleetDraftProjection.project(
        region: projected,
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        tileMapByRegion: tileMapByRegion,
        topologyByRegion: topologyByRegion,
        combinedTopology: combinedTopology,
      );
    }
    return projected;
  }

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
