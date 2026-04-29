import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/province_lookup.dart';
import 'build_rail_work_rules.dart';
import 'orders_application_context.dart';
import 'work_handlers/explore_work_handler.dart';
import 'work_handlers/prospect_work_handler.dart';
import 'work_handlers/purchase_land_handler.dart';
import 'work_handlers/shared_work_assignment.dart';
import 'work_handlers/standard_work_handler.dart';

void runWorkPhase(
  BuildWorkState state,
  void Function(BuildWorkState, Unit, String) applyExploreCompletion,
  void Function(
    BuildWorkState,
    Unit,
    CurrentWork,
    List<Province> Function(),
    void Function(List<Province>),
  )
  applyCompletedWorkTarget,
) {
  final workOrders = state.workOrders;
  final tileState = state.work.tileState;
  final oldUnitsById = state.work.oldUnitsById;
  final newUnitsById = state.work.newUnitsById;
  final purchasedTilesByTileKey = state.work.purchasedTilesByTileKey;

  for (final player in state.game.players) {
    var stockpile = player.stockpile;
    var workers = player.workerPool;
    var treasury = player.treasury;

    Unit? lookupUnit(String unitId) =>
        oldUnitsById[unitId] ?? newUnitsById[unitId];

    void updateUnit(String unitId, Unit updated) {
      if (oldUnitsById.containsKey(unitId)) {
        oldUnitsById[unitId] = updated;
      } else {
        newUnitsById[unitId] = updated;
      }
    }

    String regionForUnit(String unitId) =>
        oldUnitsById.containsKey(unitId) ? kRegionOldWorld : kRegionNewWorld;

    Province? provinceById(String id) =>
        state.game.worldState.tryGetProvince(id);

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
        // SPEC/game/diplomacy.md (GP–Minor/Tribe Rules): purchase_land requires an Embassy
        // with the Minor/Tribe and the buyer must not be at war with that faction.
        treasury = applyPurchaseLandWorkOrder(
          state: state,
          player: player,
          unit: u,
          targetTileKey: targetTileKey,
          treasury: treasury,
          purchasedTilesByTileKey: purchasedTilesByTileKey,
          provinceById: provinceById,
          updateUnit: updateUnit,
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
        state.game = tryApplyProspectWorkOrder(
          game: state.game,
          tileMapByRegion: state.tileMapByRegion,
          player: player,
          unit: u,
          targetTileKey: targetTileKey,
          updateUnit: updateUnit,
        );
      }
      if (order.target == kWorkTargetBuildImprovement) {
        if (applyStandardWorkOrder(
          order: order,
          unit: u,
          targetTileKey: targetTileKey,
          hasValidTarget: hasValidTarget,
          orderTarget: kWorkTargetBuildImprovement,
          tileState: tileState,
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
          state: state,
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
        tileState: tileState,
        provinceById: provinceById,
        canAffordMaterialCost: canAffordMaterialCost,
        deductMaterialCost: deductMaterialCost,
        updateUnit: updateUnit,
        terrain: terrainTypeForTileKey(state.tileMapByRegion, targetTileKey),
      )) {
        continue;
      }
    }

    state.work.updatedPlayers.add(
      player.copyWith(
        stockpile: stockpile,
        workerPool: workers,
        treasury: treasury,
      ),
    );
  }
}
