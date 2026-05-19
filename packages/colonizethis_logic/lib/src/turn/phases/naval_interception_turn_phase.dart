import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../event_bus/game_event_bus.dart';
import '../../game_events.dart';
import '../../world/naval_resolution.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';

TurnPipelineState runNavalInterceptionTurnPhase(
  TurnPipelineState acc,
  MapTopology topology,
  Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId,
  GameEventBus? eventBus,
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
) {
  final game = runNavalInterceptionCombatPhase(
    acc.game,
    topology,
    navalMoveOrdersByPlayerId,
    navalFeedingCoverageByPlayerId: acc.navalFeedingCoverageByPlayerId,
    onDialogue: onDialogue,
    onGameEvent: onGameEvent,
    eventBus: eventBus,
  );
  return acc.copyWith(game: game);
}

TurnPhaseStepOutcome navalInterceptionCombatTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(
  runNavalInterceptionTurnPhase(
    acc,
    config.topology,
    config.orders.navalMoveOrdersByPlayerId,
    config.eventBus,
    config.onDialogue,
    config.onGameEvent,
  ),
);
