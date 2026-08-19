import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_logic/ai_api.dart';

/// Work-target tile selection and order-merge helpers for [GameMapAreaStateLogic].
abstract final class GameMapAreaStateLogicWorkTargets {
  static const Set<String> kCacheFirstWorkTargets = {
    kWorkTargetExplore,
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
    for (final unit in game.worldState.allUnitsById.values) {
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
}
