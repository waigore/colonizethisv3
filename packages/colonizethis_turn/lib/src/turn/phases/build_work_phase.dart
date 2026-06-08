import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_orders/src/orders/orders_application.dart';
import 'package:colonizethis_world/src/trace/turn_trace_runtime.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolution_events.dart';
import '../turn_resolver_config.dart';

Game runBuildWorkPhase(
  Game game,
  Orders orders,
  MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion, {
  void Function(DialogueEvent)? onDialogue,
  WorkOrderTraceCallback? onWorkOrderTrace,
}) {
  return applyBuildAndWorkOrders(
    game,
    orders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    onDialogue: onDialogue,
    onWorkOrderTrace: onWorkOrderTrace,
  );
}

/// Build/work phase handler — runs build and work orders and emits
/// work-order-completed events. Refs #2560.
TurnPhaseStepOutcome buildWorkTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final stateBeforeBuildWork = acc.game;
  final afterBuildWork = runBuildWorkPhase(
    acc.game,
    config.orders,
    config.topology,
    config.tileMapByRegion,
    onDialogue: config.onDialogue,
    onWorkOrderTrace: config.turnTraceRuntime?.handleWorkOrderTrace,
  );
  emitWorkOrderCompletedEvents(
    stateBeforeBuildWork,
    afterBuildWork,
    turn,
    config.eventBus,
    config.onGameEvent,
  );
  return TurnPhaseStepContinue(acc.copyWith(game: afterBuildWork));
}
