import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:logger/logger.dart';

import 'ai_config.dart';
import 'domain_planners.dart';
import 'goal_manager.dart';
import 'perception.dart';
import 'seed_bundle.dart';

/// Strategic order generation for full AI. SPEC/program/ai-systems-impl.md.
///
/// Returns valid [Orders] for [nationId] for the current turn using [view] as
/// the only source of visibility. Optionally emits dialogue and mood via callbacks.
Orders generateStrategicOrders({
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
  );
  final moveCount = orders.moveOrdersByPlayerId[nationId]?.length ?? 0;
  final buildCount = orders.buildUnitOrdersByPlayerId[nationId]?.length ?? 0;
  final workCount = orders.workOrdersByPlayerId[nationId]?.length ?? 0;
  final researchCount = orders.researchOrdersByPlayerId[nationId]?.length ?? 0;
  Logger().i('ai: generated orders nationId=$nationId move=$moveCount build=$buildCount work=$workCount research=$researchCount');
  // Optional dialogue/mood emission (deterministic from dialogueSeed).
  if (onDialogue != null && seeds.dialogueSeed % 7 == 0) {
    onDialogue(DialogueEvent(
      leaderId: config.leaderId,
      category: 'agenda',
      situation: 'comment',
      era: 'earlyModern',
      variables: const {},
    ));
  }
  return orders;
}
