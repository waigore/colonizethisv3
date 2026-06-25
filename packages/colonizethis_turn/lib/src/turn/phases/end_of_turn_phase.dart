import '../end_of_turn_resolver.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolution_events.dart';
import '../turn_resolver_config.dart';

/// End-of-turn phase handler — runs victory checks, fog decay, coastal
/// visibility, and turn-advance, then emits victory events. Refs #2560.
TurnPhaseStepOutcome endOfTurnTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final after = runEndOfTurnPhase(
    acc.game,
    topology: config.topology,
    topologyByRegion: config.topologyByRegion,
    onDialogue: config.onDialogue,
  );
  emitVictorySetEvent(after, turn, config.eventSink);
  return TurnPhaseStepContinue(acc.copyWith(game: after));
}
