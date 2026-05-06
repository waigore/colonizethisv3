import 'package:colonizethis_models/colonizethis_models.dart';

import 'orders_application_context.dart';
import 'work_handlers/counter_spy_work_handler.dart';
import 'work_handlers/explore_work_handler.dart';
import 'work_handlers/prospect_work_handler.dart';
import 'work_handlers/purchase_land_handler.dart';
import 'work_handlers/steal_tech_work_handler.dart';
import 'work_handlers/standard_work_handler.dart';
import 'work_handlers/work_order_handler.dart';

const List<WorkOrderHandler> _workOrderHandlers = [
  PurchaseLandWorkOrderHandler(),
  StealTechWorkOrderHandler(),
  CounterSpyWorkOrderHandler(),
  ProspectWorkOrderHandler(),
  BuildImprovementWorkOrderHandler(),
  ExploreWorkOrderHandler(),
  RemainingStandardBuildTargetsWorkOrderHandler(),
];

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
    final context = WorkOrderExecutionContext(state: current, player: player);

    for (final order in workOrders[player.id] ?? const []) {
      final u = context.lookupUnit(order.unitId);
      if (u == null) continue;
      final targetTileKey = order.targetTileKey;
      final hasValidTarget = targetTileKey.isNotEmpty;
      for (final handler in _workOrderHandlers) {
        if (!handler.supports(order.target)) continue;
        if (handler.tryApply(
          context,
          order,
          u,
          targetTileKey,
          hasValidTarget,
        )) {
          break;
        }
      }
    }

    context.persistPlayerSnapshot();
    current = context.state;
  }

  return current;
}
