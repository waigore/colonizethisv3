// Event dialogue: emit DialogueEvent when game events trigger commentary.
// SPEC/ai/dialogue-and-mood.md (event: battle result), SPEC/program/ai-events-and-dossier.md.
// Only AI leaders emit; deterministic given game state and seed.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'evidence_rules.dart';

const String _eraDefault = 'earlyModern';

/// Dialogue events for land battle result. Victor/loser are GP ids.
/// Emits battle_won for AI victor, battle_lost for AI loser. Deterministic.
List<DialogueEvent> dialogueEventsForLandBattleResult(
  Game game,
  String victorId,
  String loserId,
  String provinceId,
  int turnNumber,
  int seed,
) {
  final events = <DialogueEvent>[];
  if (isAiControlledForEvidence(game, victorId)) {
    events.add(DialogueEvent(
      leaderId: victorId,
      category: 'event',
      situation: 'battle_won',
      era: _eraDefault,
      variables: {'otherNation': loserId, 'province': provinceId},
    ));
  }
  if (isAiControlledForEvidence(game, loserId)) {
    events.add(DialogueEvent(
      leaderId: loserId,
      category: 'event',
      situation: 'battle_lost',
      era: _eraDefault,
      variables: {'otherNation': victorId, 'province': provinceId},
    ));
  }
  return events;
}

/// Dialogue events for naval battle result (one side eliminated).
/// Emits battle_won for AI victor, battle_lost for AI loser. Deterministic.
List<DialogueEvent> dialogueEventsForNavalBattleResult(
  Game game,
  String victorId,
  String loserId,
  int turnNumber,
  int seed,
) {
  final events = <DialogueEvent>[];
  if (isAiControlledForEvidence(game, victorId)) {
    events.add(DialogueEvent(
      leaderId: victorId,
      category: 'event',
      situation: 'battle_won',
      era: _eraDefault,
      variables: {'otherNation': loserId},
    ));
  }
  if (isAiControlledForEvidence(game, loserId)) {
    events.add(DialogueEvent(
      leaderId: loserId,
      category: 'event',
      situation: 'battle_lost',
      era: _eraDefault,
      variables: {'otherNation': victorId},
    ));
  }
  return events;
}
