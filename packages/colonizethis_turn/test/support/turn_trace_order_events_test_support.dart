import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared turn-trace phase capture for army / civilian / work order-event suites
/// (Refs #4039). Keeps movement vs buildWork AC groups in separate test files.
TurnTracePhaseTrace runTurnTracePhaseForOrders({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required String phaseId,
  TurnTraceRuntime? runtime,
}) {
  final traces = <TurnTracePhaseTrace>[];
  resolveTurnForGameWithConfig(
    game: game,
    config: TurnResolverConfig(
      topology: topology,
      orders: orders,
      onTurnTracePhase: traces.add,
      turnTraceRuntime: runtime,
    ),
  );
  return traces.firstWhere((t) => t.phaseId == phaseId);
}

/// Movement-phase capture helper used by army- and civilian-move order suites.
TurnTracePhaseTrace runMovementTraceForOrders({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  TurnTraceRuntime? runtime,
}) {
  return runTurnTracePhaseForOrders(
    game: game,
    topology: topology,
    orders: orders,
    phaseId: TurnPhase.movement.name,
    runtime: runtime,
  );
}

/// Filters [trace.orderEvents] to a single order id (stable across suites).
List<TurnTraceOrderEvent> orderEventsFor(
  TurnTracePhaseTrace trace,
  String orderId,
) {
  return trace.orderEvents.where((e) => e.orderId == orderId).toList();
}
