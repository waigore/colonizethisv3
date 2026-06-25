import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../naval_resolution.dart';
import '../turn_event_sink.dart';
import '../turn_phase_handler_helpers.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';

TurnPipelineState runNavalInterceptionTurnPhase(
  TurnPipelineState acc,
  MapTopology topology,
  Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId,
  TurnEventSink sink,
) {
  final game = runNavalInterceptionCombatPhase(
    acc.game,
    topology,
    navalMoveOrdersByPlayerId,
    navalFeedingCoverageByPlayerId: acc.navalFeedingCoverageByPlayerId,
    sink: sink,
  );
  return acc.copyWith(game: game);
}

TurnPhaseStepOutcome navalInterceptionCombatTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => simplePipelinePhase(
  (pipeline) => runNavalInterceptionTurnPhase(
    pipeline,
    config.topology,
    config.orders.navalMoveOrdersByPlayerId,
    config.eventSink,
  ),
)(acc, config, turn);
