import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../economy/projected_cost_engine.dart';
import '../orders_application_context.dart';
import '../../world/province_lookup.dart';

abstract class WorkOrderHandler {
  const WorkOrderHandler();

  bool supports(String target);

  bool tryApply(
    WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  );
}

class WorkOrderExecutionContext {
  WorkOrderExecutionContext({required this.state, required this.player})
    : stockpile = player.stockpile,
      workers = player.workerPool,
      treasury = player.treasury,
      purchasedTilesByTileKey = Map<String, String>.from(
        state.work.purchasedTilesByTileKey,
      );

  BuildWorkState state;
  final Player player;
  Stockpile stockpile;
  WorkerPool workers;
  int treasury;
  Map<String, String> purchasedTilesByTileKey;

  Unit? lookupUnit(String unitId) =>
      state.work.oldUnitsById[unitId] ?? state.work.newUnitsById[unitId];

  void updateUnit(String unitId, Unit updated) {
    if (state.work.oldUnitsById.containsKey(unitId)) {
      state = state.copyWith(
        work: state.work.copyWith(
          oldUnitsById: Map<String, Unit>.from(state.work.oldUnitsById)
            ..[unitId] = updated,
        ),
      );
    } else {
      state = state.copyWith(
        work: state.work.copyWith(
          newUnitsById: Map<String, Unit>.from(state.work.newUnitsById)
            ..[unitId] = updated,
        ),
      );
    }
  }

  String regionForUnit(String unitId) =>
      state.work.oldUnitsById.containsKey(unitId)
      ? kRegionOldWorld
      : kRegionNewWorld;

  Province? provinceById(String id) => state.game.worldState.tryGetProvince(id);

  bool canAffordMaterialCost(WorkOrderCost cost) =>
      ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost);

  void deductMaterialCost(WorkOrderCost cost) {
    stockpile = ProjectedCostEngine.deductWorkMaterialCost(stockpile, cost);
  }

  void persistPlayerSnapshot() {
    state = state.copyWith(
      work: state.work.copyWith(
        purchasedTilesByTileKey: purchasedTilesByTileKey,
        updatedPlayers: [
          ...state.work.updatedPlayers,
          player.copyWith(
            stockpile: stockpile,
            workerPool: workers,
            treasury: treasury,
          ),
        ],
      ),
    );
  }
}
