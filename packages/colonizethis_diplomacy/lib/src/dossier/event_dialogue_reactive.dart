// Reactive and negotiation dialogue emitters.
// SPEC/ai/dialogue-and-mood.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../diplomacy/diplomacy_shared_helpers.dart' show isTargetHumanGp;
import 'event_dialogue_shared.dart';

/// Reactive dialogue when a human builds a fort on a province adjacent to an AI.
/// Emits one [DialogueEvent] per AI leader who owns a neighboring province. SPEC/ai/dialogue-and-mood.md (reactive).
List<DialogueEvent> dialogueEventsForReactiveFortsOnBorder(
  Game game,
  MapTopology topology,
  String builderPlayerId,
  String provinceId,
  int seed,
) {
  final builder = game.playerById(builderPlayerId);
  if (builder == null || builder.isHuman != true) return [];
  final regionId = ProvinceId.regionIdFrom(provinceId);
  final localId = ProvinceId.localIdFrom(provinceId);
  final neighborLocalIds = neighborProvinceLocalIds(
    topology,
    regionId,
    localId,
  );
  final era = eraForDialogueTurn(game, game.worldState.turnState.turnNumber);
  final events = <DialogueEvent>[];
  final seenAi = <String>{};
  for (final neighborLocal in neighborLocalIds) {
    final fullId = ProvinceId.full(regionId, neighborLocal);
    final ownerId = game.worldState.tryGetProvince(fullId)?.ownerId;
    if (ownerId == null ||
        !isAiGpForDialogue(game, ownerId) ||
        !seenAi.add(ownerId)) {
      continue;
    }
    events.add(
      DialogueEvent(
        leaderId: ownerId,
        category: 'reactive',
        situation: 'forts_on_border',
        era: era,
        variables: {'otherNation': builderPlayerId, 'province': provinceId},
      ),
    );
  }
  return events;
}

/// Builds a [DialogueEvent] for negotiation (opening, counter_offer, accepting, rejecting).
/// UI or negotiation flow calls this to get the event; then passes to onDialogue or displays.
/// SPEC/ai/dialogue-and-mood.md (negotiation).
DialogueEvent dialogueEventForNegotiation({
  required String leaderId,
  required String situation,
  required String era,
  String? mood,
  Map<String, String> variables = const {},
}) {
  return DialogueEvent(
    leaderId: leaderId,
    category: 'negotiation',
    situation: situation,
    era: era,
    mood: mood,
    variables: variables,
  );
}

String? _reactiveHumanAttackSituationForSpeaker(
  Game game,
  String speakerId,
  String defenderFactionId, {
  required bool isMinor,
  required bool isTribe,
}) {
  if (isMinor) {
    return hasEmbassyOrAllianceForDialogue(game, speakerId, defenderFactionId)
        ? 'attack_on_minor'
        : null;
  }
  if (isTribe) {
    return hasEmbassyOrAllianceForDialogue(game, speakerId, defenderFactionId)
        ? 'attack_on_tribe'
        : null;
  }
  if (hasFormalAllianceForDialogue(game, speakerId, defenderFactionId)) {
    return 'attack_on_ally';
  }
  return null;
}

/// Reactive dialogue for human-initiated attacks.
/// Emits attack_on_ally / attack_on_minor / attack_on_tribe for affected AI leaders.
List<DialogueEvent> dialogueEventsForReactiveHumanAttack(
  Game game, {
  required String attackerFactionId,
  required String defenderFactionId,
  required String provinceId,
  required int turnNumber,
  required int seed,
}) {
  if (!isTargetHumanGp(game, attackerFactionId)) return const [];
  final era = eraForDialogueTurn(game, turnNumber);
  final aiSpeakers = sortedAiSpeakerIdsForDialogue(game);
  final events = <DialogueEvent>[];
  final seenKeys = <String>{};
  final isMinor = isMinorFactionForDialogue(game, defenderFactionId);
  final isTribe = isTribeFactionForDialogue(game, defenderFactionId);
  for (final speakerId in aiSpeakers) {
    if (speakerId == attackerFactionId) continue;
    final situation = _reactiveHumanAttackSituationForSpeaker(
      game,
      speakerId,
      defenderFactionId,
      isMinor: isMinor,
      isTribe: isTribe,
    );
    if (situation == null) continue;
    final dedupeKey = '$speakerId|$situation|$provinceId';
    if (!seenKeys.add(dedupeKey)) continue;
    events.add(
      DialogueEvent(
        leaderId: speakerId,
        category: 'reactive',
        situation: situation,
        era: era,
        variables: {
          'otherNation': attackerFactionId,
          'targetNation': defenderFactionId,
          'province': provinceId,
        },
      ),
    );
  }
  return events;
}

/// Reactive dialogue for human first-to-tech milestone.
List<DialogueEvent> dialogueEventsForReactiveTechFirst(
  Game game, {
  required String discovererId,
  required String techId,
  required int turnNumber,
  required int seed,
}) {
  if (!isTargetHumanGp(game, discovererId)) return const [];
  final era = eraForDialogueTurn(game, turnNumber);
  return sortedAiSpeakerIdsForDialogue(game)
      .map(
        (speakerId) => aiSubjectDialogueEvent(
          leaderId: speakerId,
          category: 'reactive',
          situation: 'tech_first',
          era: era,
          variables: {'otherNation': discovererId, 'techId': techId},
        ),
      )
      .toList();
}

/// Reactive dialogue for AI when human spy is caught by counter-spy.
List<DialogueEvent> dialogueEventsForReactiveSpiesCaught(
  Game game, {
  required String speakerId,
  required String caughtSpyOwnerId,
  required String provinceId,
  required int turnNumber,
  required int seed,
}) {
  if (!isAiGpForDialogue(game, speakerId)) return const [];
  if (!isTargetHumanGp(game, caughtSpyOwnerId)) return const [];
  return [
    aiSubjectDialogueEvent(
      leaderId: speakerId,
      category: 'reactive',
      situation: 'spies_caught',
      era: eraForDialogueTurn(game, turnNumber),
      variables: {'otherNation': caughtSpyOwnerId, 'province': provinceId},
    ),
  ];
}

/// Reactive dialogue for AI when a human spy defects via counter-espionage.
List<DialogueEvent> dialogueEventsForReactiveSpiesDefected(
  Game game, {
  required String newOwnerId,
  required String previousOwnerId,
  required String provinceId,
  required int turnNumber,
  required int seed,
}) {
  if (!isAiGpForDialogue(game, newOwnerId)) return const [];
  if (!isTargetHumanGp(game, previousOwnerId)) return const [];
  return [
    aiSubjectDialogueEvent(
      leaderId: newOwnerId,
      category: 'reactive',
      situation: 'spies_defected',
      era: eraForDialogueTurn(game, turnNumber),
      variables: {'otherNation': previousOwnerId, 'province': provinceId},
    ),
  ];
}
