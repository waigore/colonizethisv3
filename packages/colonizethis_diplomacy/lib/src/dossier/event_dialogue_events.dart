// Event-category dialogue emitters (era, battle, tech, colony, capital).
// SPEC/ai/dialogue-and-mood.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../diplomacy/diplomacy_shared_helpers.dart'
    show isAiControlledForEvidence, isTargetHumanGp;
import 'event_dialogue_shared.dart';

/// Dialogue events for era transition. Emit one per AI leader when game era changes at end of turn.
/// Deterministic given [game] and [seed]. SPEC/ai/dialogue-and-mood.md (event: era transition).
List<DialogueEvent> dialogueEventsForEraChange(
  Game game,
  String previousEra,
  String newEra,
  int seed,
) {
  final events = <DialogueEvent>[];
  for (final p in game.players) {
    if (!isAiControlledForEvidence(game, p.id)) continue;
    events.add(
      DialogueEvent(
        leaderId: p.id,
        category: 'event',
        situation: 'era_change',
        era: newEra,
        variables: {'previousEra': previousEra},
      ),
    );
  }
  return events;
}

List<DialogueEvent> _dialogueEventsForBattleResult(
  Game game, {
  required String victorId,
  required String loserId,
  required int turnNumber,
  String? provinceId,
}) {
  final events = <DialogueEvent>[];
  final era = eraForDialogueTurn(game, turnNumber);
  Map<String, String> vars(String otherNation) {
    final m = <String, String>{'otherNation': otherNation};
    if (provinceId != null) m['province'] = provinceId;
    return m;
  }

  if (isAiControlledForEvidence(game, victorId)) {
    events.add(
      DialogueEvent(
        leaderId: victorId,
        category: 'event',
        situation: 'battle_won',
        era: era,
        variables: vars(loserId),
      ),
    );
  }
  if (isAiControlledForEvidence(game, loserId)) {
    events.add(
      DialogueEvent(
        leaderId: loserId,
        category: 'event',
        situation: 'battle_lost',
        era: era,
        variables: vars(victorId),
      ),
    );
  }
  return events;
}

/// Dialogue events for land battle result. Victor/loser are GP ids.
/// Emits battle_won for AI victor, battle_lost for AI loser. Deterministic.
List<DialogueEvent> dialogueEventsForLandBattleResult(
  Game game,
  String victorId,
  String loserId,
  String provinceId,
  int turnNumber,
  int seed,
) =>
    _dialogueEventsForBattleResult(
      game,
      victorId: victorId,
      loserId: loserId,
      turnNumber: turnNumber,
      provinceId: provinceId,
    );

/// Dialogue events for naval battle result (one side eliminated).
/// Emits battle_won for AI victor, battle_lost for AI loser. Deterministic.
List<DialogueEvent> dialogueEventsForNavalBattleResult(
  Game game,
  String victorId,
  String loserId,
  int turnNumber,
  int seed,
) =>
    _dialogueEventsForBattleResult(
      game,
      victorId: victorId,
      loserId: loserId,
      turnNumber: turnNumber,
    );

/// Event dialogue for AI tech discoveries.
List<DialogueEvent> dialogueEventsForTechDiscovered(
  Game game, {
  required String discovererId,
  required String techId,
  required int turnNumber,
  required int seed,
}) {
  if (!isAiGpForDialogue(game, discovererId)) return const [];
  return [
    DialogueEvent(
      leaderId: discovererId,
      category: 'event',
      situation: 'tech_discovered',
      era: eraForDialogueTurn(game, turnNumber),
      variables: {'techId': techId},
    ),
  ];
}

/// Event dialogue when an AI capital is targeted by human attackers.
List<DialogueEvent> dialogueEventsForCapitalThreatened(
  Game game, {
  required String capitalOwnerId,
  required String provinceId,
  required List<String> attackerFactionIds,
  required int turnNumber,
  required int seed,
}) {
  if (!isAiGpForDialogue(game, capitalOwnerId)) return const [];
  final humanAttackers =
      attackerFactionIds.where((id) => isTargetHumanGp(game, id));
  final primaryAttacker = humanAttackers.toList()..sort();
  if (primaryAttacker.isEmpty) return const [];
  return [
    aiSubjectDialogueEvent(
      leaderId: capitalOwnerId,
      category: 'event',
      situation: 'capital_threatened',
      era: eraForDialogueTurn(game, turnNumber),
      variables: {'otherNation': primaryAttacker.first, 'province': provinceId},
    ),
  ];
}

/// Event dialogue for New World colony foundation when owner changes null -> AI.
List<DialogueEvent> dialogueEventsForColonyFounded(
  Game game, {
  required String provinceId,
  required String? previousOwnerId,
  required String newOwnerId,
  required int turnNumber,
  required int seed,
}) {
  if (previousOwnerId != null && previousOwnerId.isNotEmpty) return const [];
  if (ProvinceId.regionIdFrom(provinceId) != kRegionNewWorld) return const [];
  if (!isAiGpForDialogue(game, newOwnerId)) return const [];
  return [
    aiSubjectDialogueEvent(
      leaderId: newOwnerId,
      category: 'event',
      situation: 'colony_founded',
      era: eraForDialogueTurn(game, turnNumber),
      variables: {'province': provinceId},
    ),
  ];
}
