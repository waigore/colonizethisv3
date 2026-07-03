import '../spy_resolver.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolution_events.dart';
import '../turn_resolver_config.dart';

/// Pre-Research spy-resolution phase handler (Refs #3834 R12).
TurnPhaseStepOutcome spyResolutionTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final result = resolveSpyPhase(acc.game);
  emitSpyResolutionEvents(result.game, result, turn, config.eventSink);
  return TurnPhaseStepContinue(acc.copyWith(game: result.game));
}
