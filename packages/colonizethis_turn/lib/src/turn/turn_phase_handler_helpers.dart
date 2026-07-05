import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_phase_sequence.dart';
import 'turn_pipeline_state.dart';
import 'turn_resolver_config.dart';

/// Adapts a game-only resolver into the [TurnPhaseHandler] shape.
TurnPhaseHandler simpleGamePhase(
  Game Function(Game game, TurnResolverConfig config) run,
) =>
    (acc, config, _) =>
        TurnPhaseStepContinue(acc.copyWith(game: run(acc.game, config)));

/// Adapts a pipeline-state resolver into the [TurnPhaseHandler] shape.
TurnPhaseHandler simplePipelinePhase(
  TurnPipelineState Function(TurnPipelineState acc) run,
) =>
    (acc, _, _) => TurnPhaseStepContinue(run(acc));

/// Adapts an [EconomyPhaseStepRunner] into the [TurnPhaseHandler] shape.
TurnPhaseHandler economyPhaseHandlerFromStep(
  EconomyPhaseStepRunner step, {
  bool applyPurchasedTileRichesHandoff = false,
  bool recordOverseasTonnage = false,
}) =>
    (acc, config, _) {
      final overseasShippedTonnageOut = recordOverseasTonnage
          ? <String, int>{}
          : null;
      return TurnPhaseStepContinue(
        step(
          acc,
          economyPhaseStepContextFromConfig(
            config,
            overseasShippedTonnageOut: overseasShippedTonnageOut,
            applyPurchasedTileRichesHandoff: applyPurchasedTileRichesHandoff,
          ),
        ),
      );
    };
