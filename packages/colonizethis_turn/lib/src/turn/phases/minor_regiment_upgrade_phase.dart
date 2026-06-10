import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';

Game runMinorRegimentUpgradePhase(Game game) => applyMinorMilitaryParity(game);

TurnPhaseStepOutcome minorRegimentUpgradeTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(
  acc.copyWith(game: runMinorRegimentUpgradePhase(acc.game)),
);
