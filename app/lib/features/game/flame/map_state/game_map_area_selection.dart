
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../widgets/shell/shell_player_context.dart';

import 'game_map_area_state_logic.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';

/// Civilian work-target tile selection for [GameMapArea]: maintaining the
/// per-player valid-tile cache, starting/cancelling a selection, and committing
/// the resulting work order (Refs #3699 Theme 3).
mixin GameMapAreaSelection on ConsumerState<GameMapArea>, GameMapAreaStateBase {
  void refreshWorkTargetSelectionCache(ct_models.Game game) {
    final view = buildPlayerView(
      game,
      widget.mapViewData.combinedTopology,
      mapPlayerId,
    );
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    workTargetSelectionCache.refresh(
      WorkTargetSelectionSnapshot(
        game: game,
        playerId: mapPlayerId,
        playerView: view,
        topology: widget.mapViewData.combinedTopology,
        currentOrders: const ct_models.Orders(),
        tileMapByRegion: mapData?.tileMapByRegion,
      ),
    );
  }

  int? preferredRegionIndexForValidSelection(Set<String> validTileKeys) {
    if (validTileKeys.isEmpty) {
      return null;
    }
    final currentRegionId = currentRegion.regionId;
    final hasCurrent = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$currentRegionId|'),
    );
    if (hasCurrent) {
      return null;
    }
    final hasOldWorld = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$kRegionOldWorld|'),
    );
    final hasNewWorld = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$kRegionNewWorld|'),
    );
    if (hasOldWorld && !hasNewWorld) {
      return 0;
    }
    if (hasNewWorld && !hasOldWorld) {
      return 1;
    }
    return null;
  }

  void computeValidTileKeysForSelection() {
    if (workTargetSelection == null) {
      cachedValidTileKeys = null;
      return;
    }
    final game = ref.read(currentGameProvider);
    if (game == null) {
      cachedValidTileKeys = null;
      return;
    }
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? const MapTopology();
    final view = buildPlayerView(game, topology, mapPlayerId);
    final workTarget = workTargetSelection!.workTarget;
    cachedValidTileKeys =
        GameMapAreaStateLogic.resolveValidTileKeysForCivilianWorkSelection(
          workTarget: workTarget,
          workTargetSelectionCache: workTargetSelectionCache,
          humanPlayerId: mapPlayerId,
          selectedUnitId: workTargetSelection!.unit.id,
          game: game,
          currentOrders: orders,
          playerView: view,
          topology: topology,
          tileMapByRegion: mapData?.tileMapByRegion,
        );
  }

  ct_models.Unit? findUnitById(String unitId) {
    for (final unit in widget.game.worldState.oldWorld.units) {
      if (unit.id == unitId) return unit;
    }
    for (final unit in widget.game.worldState.newWorld.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  void startWorkTargetSelection(String unitId, String workTarget) {
    if (civilianRelocateSelection != null) {
      civilianRelocateSelection = null;
    }
    final unit = findUnitById(unitId);
    if (unit == null) return;
    setState(() {
      workTargetSelection = (unit: unit, workTarget: workTarget);
      computeValidTileKeysForSelection();
      final validTileKeys = cachedValidTileKeys;
      if (validTileKeys != null) {
        final preferredRegionIndex = preferredRegionIndexForValidSelection(
          validTileKeys,
        );
        if (preferredRegionIndex != null) {
          regionIndex = preferredRegionIndex;
        }
      }
    });
  }

  void cancelWorkTargetSelection() {
    if (workTargetSelection == null) {
      return;
    }
    setState(() {
      workTargetSelection = null;
      cachedValidTileKeys = null;
    });
  }

  void onTileSelectedForWork(String tileKey) {
    if (!ref.read(shellPlayerContextProvider).canMutateViaUi) {
      return;
    }
    final sel = workTargetSelection;
    if (sel == null) return;
    final target = sel.workTarget;
    final targetTileKey = GameMapAreaStateLogic.translateWorkTargetTileKey(
      tileKey: tileKey,
      workTarget: target,
    );
    final workOrder = ct_models.WorkOrder(
      unitId: sel.unit.id,
      target: target,
      targetTileKey: targetTileKey,
    );
    final orders = ref.read(currentOrdersProvider);
    ref
        .read(currentOrdersProvider.notifier)
        .replaceAll(
          GameMapAreaStateLogic.addHumanWorkOrder(
            orders: orders,
            humanPlayerId: mapPlayerId,
            workOrder: workOrder,
          ),
        );
    setState(() {
      selectedCivilianTileKey =
          GameMapAreaStateLogic.selectionAfterWorkAssignment(
            currentSelectedCivilianTileKey: selectedCivilianTileKey,
            assignedTileKey: targetTileKey,
          );
      workTargetSelection = null;
      cachedValidTileKeys = null;
    });
  }
}
