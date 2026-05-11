import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show PlayerView, TurnTraceAiSection;
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator.dart';
import 'economy_planner.dart';
import '../goal_manager.dart';
import 'ai_order_reporting.dart';
import 'ai_trace_builder.dart';
import '../social/mood_state_machine.dart';
import '../perception.dart';

final _log = packageLogger();

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
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
}) {
  return generateStrategicOrdersWithTrace(
    game: game,
    topology: topology,
    nationId: nationId,
    view: view,
    config: config,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    tileMapByRegion: tileMapByRegion,
    onDialogue: onDialogue,
    onMood: onMood,
  ).result;
}

class StrategicOrderTraceResult {
  const StrategicOrderTraceResult({
    required this.result,
    required this.aiTraceSection,
  });

  final StrategicOrderResult result;
  final TurnTraceAiSection aiTraceSection;
}

StrategicOrderTraceResult generateStrategicOrdersWithTrace({
  required Game game,
  required MapTopology topology,
  required String nationId,
  required PlayerView view,
  required AIConfig config,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
  void Function(String phaseId)? onStagedPlannerProgress,
}) {
  final turn = game.worldState.turnState.turnNumber;
  _log.i('generateStrategicOrders nationId=$nationId turn=$turn');
  final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);
  final goalScores = evaluateStrategicGoalScores(snapshot, config);
  final primaryGoal = selectPrimaryGoal(
    snapshot,
    config,
    seeds.goalSeed,
    nationId: nationId,
    turn: turn,
  );
  _log.d('primaryGoal=$primaryGoal');
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
    tileMapByRegion: tileMapByRegion,
    onStagedPlannerProgress: onStagedPlannerProgress,
  );
  final moveCount = orders.moveOrdersByPlayerId[nationId]?.length ?? 0;
  final armyMoveCount = orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
  final buildCount = orders.buildUnitOrdersByPlayerId[nationId]?.length ?? 0;
  final workCount = orders.workOrdersByPlayerId[nationId]?.length ?? 0;
  final researchCount = orders.researchOrdersByPlayerId[nationId]?.length ?? 0;
  _log.i(
    'generated orders nationId=$nationId move=$moveCount armyMove=$armyMoveCount build=$buildCount work=$workCount research=$researchCount',
  );
  _emitDialogueAndMood(
    config: config,
    seeds: seeds,
    onDialogue: onDialogue,
    onMood: onMood,
  );
  final result = StrategicOrderResult(orders: orders, economyPlan: economyPlan);
  final ordersByDomain = orderCountsByDomain(nationId, orders);
  final finalOrders = finalAggregatedOrders(nationId, orders);
  return StrategicOrderTraceResult(
    result: result,
    aiTraceSection: buildAiTraceSection(
      nationId: nationId,
      turn: turn,
      config: config,
      seeds: seeds,
      snapshot: snapshot,
      primaryGoal: primaryGoal,
      goalScores: goalScores,
      economyPlan: economyPlan,
      orders: orders,
      ordersByDomain: ordersByDomain,
      finalOrders: finalOrders,
    ),
  );
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
    onDialogue(
      DialogueEvent(
        leaderId: config.leaderId,
        category: 'agenda',
        situation: 'comment',
        era: 'earlyModern',
        variables: const {},
      ),
    );
  }
  if (onMood != null &&
      seeds.dialogueSeed % kDialogueTurnsBetweenComments == 0) {
    onMood(
      PortraitMoodEvent(
        leaderId: config.leaderId,
        fromMood: kDefaultMood,
        toMood: kDefaultMood,
        durationMs: 0,
      ),
    );
  }
}
