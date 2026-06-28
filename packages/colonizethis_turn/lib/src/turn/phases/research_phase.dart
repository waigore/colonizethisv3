import '../research_resolver.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolution_events.dart';
import '../turn_resolver_config.dart';

/// Research phase handler — resolves research orders, emits research-complete
/// events, and updates the pipeline. Refs #2560.
TurnPhaseStepOutcome researchTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final stateBeforeResearch = acc.game;
  final afterResearch = resolveResearchPhase(acc.game, config.orders);
  emitResearchCompleteEvents(
    stateBeforeResearch,
    afterResearch,
    turn,
    config.eventSink,
  );
  return TurnPhaseStepContinue(acc.copyWith(game: afterResearch));
}
