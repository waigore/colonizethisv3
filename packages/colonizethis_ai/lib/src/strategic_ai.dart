import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:logger/logger.dart';

import 'ai_config.dart';
import 'domain_planners.dart';
import 'economy_planner.dart';
import 'goal_manager.dart';
import 'mood_state_machine.dart';
import 'perception.dart';
import 'seed_bundle.dart';

/// Result of strategic order generation: orders and economy plan. SPEC/ai/economy-planner.md.
class StrategicOrderResult {
  const StrategicOrderResult({
    required this.orders,
    required this.economyPlan,
  });
  final Orders orders;
  final EconomyPlan economyPlan;
}

/// Strategic order generation for full AI. SPEC/program/ai-systems-impl.md.
///
/// Returns valid [Orders] and [EconomyPlan] for [nationId] for the current turn
/// using [view] as the only source of visibility. Optionally emits dialogue and mood via callbacks.
StrategicOrderResult generateStrategicOrders({
  required Game game,
  required MapTopology topology,
  required String nationId,
  required PlayerView view,
  required AIConfig config,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
}) {
  final turn = game.worldState.turnState.turnNumber;
  Logger().i('ai: generateStrategicOrders nationId=$nationId turn=$turn');
  final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);
  final primaryGoal = selectPrimaryGoal(snapshot, config, seeds.goalSeed);
  Logger().d('ai: primaryGoal=$primaryGoal');
  final economyPlan = runEconomyPlanner(
    game: game,
    view: view,
    config: config,
    seeds: seeds,
  );
  final orders = runDomainPlanners(
    game: game,
    topology: topology,
    nationId: nationId,
    view: view,
    snapshot: snapshot,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    economyPlan: economyPlan,
  );
  final moveCount = orders.moveOrdersByPlayerId[nationId]?.length ?? 0;
  final buildCount = orders.buildUnitOrdersByPlayerId[nationId]?.length ?? 0;
  final workCount = orders.workOrdersByPlayerId[nationId]?.length ?? 0;
  final researchCount = orders.researchOrdersByPlayerId[nationId]?.length ?? 0;
  Logger().i('ai: generated orders nationId=$nationId move=$moveCount build=$buildCount work=$workCount research=$researchCount');
  _emitDialogueAndMood(
    config: config,
    seeds: seeds,
    onDialogue: onDialogue,
    onMood: onMood,
  );
  return StrategicOrderResult(orders: orders, economyPlan: economyPlan);
}

void _emitDialogueAndMood({
  required AIConfig config,
  required AISeedBundle seeds,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
}) {
  // Optional dialogue/mood emission (deterministic from dialogueSeed).
  // SPEC/ai/dialogue-and-mood.md § When to emit:
  // Strategic AI may emit optional agenda/comment and base mood once every
  // kDialogueTurnsBetweenComments turns per leader, when
  // `dialogueSeed % kDialogueTurnsBetweenComments == 0`.
  if (onDialogue != null &&
      seeds.dialogueSeed % kDialogueTurnsBetweenComments == 0) {
    onDialogue(DialogueEvent(
      leaderId: config.leaderId,
      category: 'agenda',
      situation: 'comment',
      era: 'earlyModern',
      variables: const {},
    ));
  }
  if (onMood != null &&
      seeds.dialogueSeed % kDialogueTurnsBetweenComments == 0) {
    onMood(PortraitMoodEvent(
      leaderId: config.leaderId,
      fromMood: kDefaultMood,
      toMood: kDefaultMood,
      durationMs: 0,
    ));
  }
}
