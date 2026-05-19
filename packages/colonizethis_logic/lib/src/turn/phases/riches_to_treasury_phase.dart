import 'package:colonizethis_models/colonizethis_models.dart';

import '../../economy/economy_riches_to_treasury.dart';
import '../../world/player_state_pipeline.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';

Game runRichesToTreasuryPhase(Game game) {
  final multiplier = game.richesCashMultiplier;

  return game.mapPlayers((player) {
    final result = resolveRichesToTreasury(
      stockpile: player.stockpile,
      richesCashMultiplier: multiplier,
    );
    return player.copyWith(
      stockpile: result.stockpile,
      treasury: player.treasury + result.treasuryDelta,
    );
  });
}

TurnPhaseStepOutcome richesToTreasuryTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(
  acc.copyWith(game: runRichesToTreasuryPhase(acc.game)),
);
