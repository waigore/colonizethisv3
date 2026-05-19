import 'package:colonizethis_models/colonizethis_models.dart';

import 'orders_application_context.dart';
import 'work_handlers/work_order_handler.dart';
import 'work_handlers/work_order_handler_registry.dart';

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
      final handler = workOrderHandlerForTarget(order.target);
      if (handler != null) {
        handled = handler.tryApply(
          context,
          order,
          u,
          targetTileKey,
          hasValidTarget,
        );
        if (handled) {
          final nextUnit = context.lookupUnit(order.unitId);
          final nextWork = nextUnit?.currentWork;
          applied = nextWork != null && nextWork.workTarget == order.target;
        }
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
