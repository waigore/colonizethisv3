import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Runs a single [handler] for [turnNumber] and returns the updated pipeline.
///
/// Fails the test when the handler returns [TurnPhaseStepExit] instead of
/// [TurnPhaseStepContinue]. Refs #3876.
TurnPipelineState runTurnPhaseHandlerPipeline({
  required TurnPhaseHandler handler,
  required Game game,
  required TurnResolverConfig config,
  int turnNumber = 3,
}) =>
    runTurnPhaseHandlerPipelineFrom(
      handler: handler,
      pipeline: TurnPipelineState(game: game),
      config: config,
      turnNumber: turnNumber,
    );

/// Like [runTurnPhaseHandlerPipeline] but preserves pre-seeded pipeline fields
/// on [pipeline] (e.g. overseas extraction tonnage for world-market tests).
TurnPipelineState runTurnPhaseHandlerPipelineFrom({
  required TurnPhaseHandler handler,
  required TurnPipelineState pipeline,
  required TurnResolverConfig config,
  int turnNumber = 3,
}) {
  final outcome = handler(pipeline, config, turnNumber);
  return switch (outcome) {
    TurnPhaseStepContinue(:final pipeline) => pipeline,
    TurnPhaseStepExit(:final result) => throw StateError(
        'Expected TurnPhaseStepContinue but handler exited early: $result',
      ),
  };
}

/// Runs a single [handler] for [turnNumber] and returns the resulting [Game].
Game runTurnPhaseHandler({
  required TurnPhaseHandler handler,
  required Game game,
  required TurnResolverConfig config,
  int turnNumber = 3,
}) =>
    runTurnPhaseHandlerPipeline(
      handler: handler,
      game: game,
      config: config,
      turnNumber: turnNumber,
    ).game;

/// Returns the resulting [Game] after running [handler] on [pipeline].
Game runTurnPhaseHandlerFrom({
  required TurnPhaseHandler handler,
  required TurnPipelineState pipeline,
  required TurnResolverConfig config,
  int turnNumber = 3,
}) =>
    runTurnPhaseHandlerPipelineFrom(
      handler: handler,
      pipeline: pipeline,
      config: config,
      turnNumber: turnNumber,
    ).game;
