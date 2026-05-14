import 'package:colonizethis_models/colonizethis_models.dart';

import 'orders_application_context.dart';
import 'work_handlers/simple_work_order_handler.dart';
import 'work_handlers/standard_work_handler.dart';
import 'work_handlers/work_order_handler.dart';

final List<WorkOrderHandler> _workOrderHandlers = [
  purchaseLandWorkOrderHandler,
  stealTechWorkOrderHandler,
  counterSpyWorkOrderHandler,
  prospectWorkOrderHandler,
  BuildImprovementWorkOrderHandler(),
  exploreWorkOrderHandler,
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
      if (u == null) {
        current.onWorkOrderTrace?.call(
          playerId: player.id,
          order: order,
          applied: false,
          ignoreReason: 'unit_not_found',
        );
        continue;
      }
      final targetTileKey = order.targetTileKey;
      final hasValidTarget = targetTileKey.isNotEmpty;
      var handled = false;
      var applied = false;
      for (final handler in _workOrderHandlers) {
        if (!handler.supports(order.target)) continue;
        handled = handler.tryApply(
          context,
          order,
          u,
          targetTileKey,
          hasValidTarget,
        );
        if (!handled) continue;
        final nextUnit = context.lookupUnit(order.unitId);
        final nextWork = nextUnit?.currentWork;
        applied = nextWork != null && nextWork.workTarget == order.target;
        break;
      }
      current.onWorkOrderTrace?.call(
        playerId: player.id,
        order: order,
        applied: applied,
        ignoreReason: handled
            ? (applied ? null : 'order_rejected')
            : 'unsupported_target',
      );
    }

    context.persistPlayerSnapshot();
    current = context.state;
  }

  return current;
}
