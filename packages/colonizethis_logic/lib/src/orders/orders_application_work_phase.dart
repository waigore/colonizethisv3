import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/province_lookup.dart';
import 'build_rail_work_rules.dart';
import 'orders_application_context.dart';
import 'work_handlers/counter_spy_work_handler.dart';
import 'work_handlers/explore_work_handler.dart';
import 'work_handlers/prospect_work_handler.dart';
import 'work_handlers/purchase_land_handler.dart';
import 'work_handlers/steal_tech_work_handler.dart';
import 'work_handlers/standard_work_handler.dart';

BuildWorkState runWorkPhase(
  BuildWorkState state,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
  BuildWorkState Function(
    BuildWorkState,
    Unit,
    CurrentWork,
    List<Province> Function(),
    WorkOrderState Function(WorkOrderState, List<Province>),
  )
  applyCompletedWorkTarget,
) {
  final workOrders = state.workOrders;
  var current = state;

  for (final player in current.game.players) {
    var stockpile = player.stockpile;
    var workers = player.workerPool;
    var treasury = player.treasury;
    var purchasedTiles = Map<String, String>.from(
      current.work.purchasedTilesByTileKey,
    );

    Unit? lookupUnit(String unitId) =>
        current.work.oldUnitsById[unitId] ?? current.work.newUnitsById[unitId];

    void updateUnit(String unitId, Unit updated) {
      if (current.work.oldUnitsById.containsKey(unitId)) {
        current = current.copyWith(
          work: current.work.copyWith(
            oldUnitsById: Map<String, Unit>.from(current.work.oldUnitsById)
              ..[unitId] = updated,
          ),
        );
      } else {
        current = current.copyWith(
          work: current.work.copyWith(
            newUnitsById: Map<String, Unit>.from(current.work.newUnitsById)
              ..[unitId] = updated,
          ),
        );
      }
    }

    String regionForUnit(String unitId) =>
        current.work.oldUnitsById.containsKey(unitId)
            ? kRegionOldWorld
            : kRegionNewWorld;

    Province? provinceById(String id) =>
        current.game.worldState.tryGetProvince(id);

    bool canAffordMaterialCost(WorkOrderCost cost) {
      for (final e in cost.entries) {
        if (stockpile.quantityOf(e.key) < e.value) return false;
      }
      return true;
    }

    void deductMaterialCost(WorkOrderCost cost) {
      for (final e in cost.entries) {
        stockpile = stockpile.applyDelta(e.key, -e.value);
      }
    }

    for (final order in workOrders[player.id] ?? const []) {
      final u = lookupUnit(order.unitId);
      if (u == null) continue;
      final targetTileKey = order.targetTileKey;
      final hasValidTarget = targetTileKey.isNotEmpty;

      if (order.target == kWorkTargetPurchaseLand &&
          isWorkOrderTargetAllowedForUnitType(
            u.type,
            kWorkTargetPurchaseLand,
          ) &&
          u.currentWork == null &&
          hasValidTarget) {
        final land = applyPurchaseLandWorkOrder(
          state: current,
          player: player,
          unit: u,
          targetTileKey: targetTileKey,
          treasury: treasury,
          purchasedTilesByTileKey: purchasedTiles,
          provinceById: provinceById,
          updateUnit: updateUnit,
        );
        treasury = land.treasury;
        purchasedTiles = land.purchasedTilesByTileKey;
        current = current.copyWith(
          work: current.work.copyWith(purchasedTilesByTileKey: purchasedTiles),
        );
        continue;
      }

      if (order.target == kWorkTargetStealTech &&
          tryAssignStealTechWorkOrder(
            order: order,
            unit: u,
            targetTileKey: targetTileKey,
            updateUnit: updateUnit,
          )) {
        continue;
      }

      if (order.target == kWorkTargetCounterSpy &&
          tryAssignCounterSpyWorkOrder(
            order: order,
            unit: u,
            targetTileKey: targetTileKey,
            updateUnit: updateUnit,
          )) {
        continue;
      }

      if (order.target == kWorkTargetProspect) {
        current = current.copyWith(
          game: tryApplyProspectWorkOrder(
            game: current.game,
            tileMapByRegion: current.tileMapByRegion,
            player: player,
            unit: u,
            targetTileKey: targetTileKey,
            updateUnit: updateUnit,
          ),
        );
      }
      if (order.target == kWorkTargetBuildImprovement) {
        if (applyStandardWorkOrder(
          order: order,
          unit: u,
          targetTileKey: targetTileKey,
          hasValidTarget: hasValidTarget,
          orderTarget: kWorkTargetBuildImprovement,
          tileState: current.work.tileState,
          provinceById: provinceById,
          canAffordMaterialCost: canAffordMaterialCost,
          deductMaterialCost: deductMaterialCost,
          updateUnit: updateUnit,
        )) {
          continue;
        }
      }
      if (order.target == kWorkTargetExplore &&
          isExplorerUnit(u.type) &&
          u.currentWork == null &&
          hasValidTarget) {
        if (tryApplyExploreWorkOrder(
          game: current.game,
          order: order,
          unit: u,
          targetTileKey: targetTileKey,
          regionForUnit: regionForUnit,
          updateUnit: updateUnit,
        )) {
          continue;
        }
      }
      if (tryApplyRemainingStandardBuildTargets(
        workTarget: order.target,
        order: order,
        player: player,
        unit: u,
        targetTileKey: targetTileKey,
        hasValidTarget: hasValidTarget,
        tileState: current.work.tileState,
        provinceById: provinceById,
        canAffordMaterialCost: canAffordMaterialCost,
        deductMaterialCost: deductMaterialCost,
        updateUnit: updateUnit,
        terrain: terrainTypeForTileKey(current.tileMapByRegion, targetTileKey),
      )) {
        continue;
      }
    }

    current = current.copyWith(
      work: current.work.copyWith(
        purchasedTilesByTileKey: purchasedTiles,
        updatedPlayers: [
          ...current.work.updatedPlayers,
          player.copyWith(
            stockpile: stockpile,
            workerPool: workers,
            treasury: treasury,
          ),
        ],
      ),
    );
  }

  return current;
}
