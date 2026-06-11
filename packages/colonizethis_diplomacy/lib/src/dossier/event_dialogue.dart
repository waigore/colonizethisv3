// Event dialogue: emit DialogueEvent when game events trigger commentary.
// SPEC/ai/dialogue-and-mood.md (event: battle result, era transition, reactive, negotiation),
// SPEC/program/ai-events-and-dossier.md.
// Only AI leaders emit for event/reactive; deterministic given game state and seed.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'evidence_rules.dart';

/// Era names for dialogue (SPEC/ai/dialogue-and-mood.md: discovery | earlyModern | imperial | industrial).
const List<String> kDialogueEras = [
  'discovery',
  'earlyModern',
  'imperial',
  'industrial',
];

/// Maps calendar year to dialogue era. SPEC/game/turn-time-mapping.md, SPEC/ai/dialogue-and-mood.md.
/// Bands: discovery < 1600, earlyModern 1600–1699, imperial 1700–1799, industrial >= 1800.
String eraFromYear(int year) {
  if (year < 1600) return 'discovery';
  if (year < 1700) return 'earlyModern';
  if (year < 1800) return 'imperial';
  return 'industrial';
}

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
  final mapping = game.turnTimeMapping ?? TurnTimeMapping.gdd01;
  final year = mapping.yearAtTurn(turnNumber);
  final era = eraFromYear(year);
  if (isAiControlledForEvidence(game, victorId)) {
    events.add(
      DialogueEvent(
        leaderId: victorId,
        category: 'event',
        situation: 'battle_won',
        era: era,
        variables: {'otherNation': loserId, 'province': provinceId},
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
        variables: {'otherNation': victorId, 'province': provinceId},
      ),
    );
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
  final mapping = game.turnTimeMapping ?? TurnTimeMapping.gdd01;
  final year = mapping.yearAtTurn(turnNumber);
  final era = eraFromYear(year);
  if (isAiControlledForEvidence(game, victorId)) {
    events.add(
      DialogueEvent(
        leaderId: victorId,
        category: 'event',
        situation: 'battle_won',
        era: era,
        variables: {'otherNation': loserId},
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
        variables: {'otherNation': victorId},
      ),
    );
  }
  return events;
}

/// Neighbor province local ids in [regionId] that share an edge with [localId]. Province nodes only.
List<String> neighborProvinceLocalIds(
  MapTopology topology,
  String regionId,
  String localId,
) {
  return neighborProvinceIdsInRegion(topology, regionId, localId).toList();
}

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
  final mapping = game.turnTimeMapping ?? TurnTimeMapping.gdd01;
  final year = mapping.yearAtTurn(game.worldState.turnState.turnNumber);
  final era = eraFromYear(year);
  final events = <DialogueEvent>[];
  final seenAi = <String>{};
  for (final neighborLocal in neighborLocalIds) {
    final fullId = ProvinceId.full(regionId, neighborLocal);
    final ownerId = game.worldState.tryGetProvince(fullId)?.ownerId;
    if (ownerId == null ||
        !isAiControlledForEvidence(game, ownerId) ||
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

bool _isHumanGp(Game game, String factionId) {
  final player = game.playerById(factionId);
  return player?.isHuman == true;
}

bool _isAiGp(Game game, String factionId) {
  return isAiControlledForEvidence(game, factionId);
}

bool _isMinorFaction(Game game, String factionId) {
  return game.minorNations.any((m) => m.id == factionId);
}

bool _isTribeFaction(Game game, String factionId) {
  return game.tribes.any((t) => t.id == factionId);
}

DiplomacyRelation? _relationBetween(Game game, String a, String b) {
  for (final rel in game.diplomacyRelations) {
    final direct = rel.factionId1 == a && rel.factionId2 == b;
    final reverse = rel.factionId1 == b && rel.factionId2 == a;
    if (direct || reverse) return rel;
  }
  return null;
}

bool _isAllied(Game game, String a, String b) {
  final rel = _relationBetween(game, a, b);
  if (rel == null) return false;
  return rel.level == RelationLevel.allied &&
      rel.state == RelationState.atPeace;
}

bool _hasEmbassyWithTarget(Game game, String gpId, String targetId) {
  return game.overtureStates.any(
    (o) => o.gpId == gpId && o.targetId == targetId && o.hasEmbassy,
  );
}

String _eraForTurn(Game game, int turnNumber) {
  final mapping = game.turnTimeMapping ?? TurnTimeMapping.gdd01;
  final year = mapping.yearAtTurn(turnNumber);
  return eraFromYear(year);
}

String? _reactiveHumanAttackSituationForSpeaker(
  Game game,
  String speakerId,
  String defenderFactionId, {
  required bool isMinor,
  required bool isTribe,
}) {
  if (isMinor) {
    final tiedToMinor =
        _hasEmbassyWithTarget(game, speakerId, defenderFactionId) ||
        _isAllied(game, speakerId, defenderFactionId);
    return tiedToMinor ? 'attack_on_minor' : null;
  }
  if (isTribe) {
    final tiedToTribe =
        _hasEmbassyWithTarget(game, speakerId, defenderFactionId) ||
        _isAllied(game, speakerId, defenderFactionId);
    return tiedToTribe ? 'attack_on_tribe' : null;
  }
  if (_isAllied(game, speakerId, defenderFactionId)) {
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
  if (!_isHumanGp(game, attackerFactionId)) return const [];
  final era = _eraForTurn(game, turnNumber);
  final aiSpeakers =
      game.players.where((p) => _isAiGp(game, p.id)).map((p) => p.id).toList()
        ..sort();
  final events = <DialogueEvent>[];
  final seenKeys = <String>{};
  final isMinor = _isMinorFaction(game, defenderFactionId);
  final isTribe = _isTribeFaction(game, defenderFactionId);
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

/// Event dialogue for AI tech discoveries.
List<DialogueEvent> dialogueEventsForTechDiscovered(
  Game game, {
  required String discovererId,
  required String techId,
  required int turnNumber,
  required int seed,
}) {
  if (!_isAiGp(game, discovererId)) return const [];
  return [
    DialogueEvent(
      leaderId: discovererId,
      category: 'event',
      situation: 'tech_discovered',
      era: _eraForTurn(game, turnNumber),
      variables: {'techId': techId},
    ),
  ];
}

/// Reactive dialogue for human first-to-tech milestone.
List<DialogueEvent> dialogueEventsForReactiveTechFirst(
  Game game, {
  required String discovererId,
  required String techId,
  required int turnNumber,
  required int seed,
}) {
  if (!_isHumanGp(game, discovererId)) return const [];
  final era = _eraForTurn(game, turnNumber);
  final aiSpeakers =
      game.players.where((p) => _isAiGp(game, p.id)).map((p) => p.id).toList()
        ..sort();
  return aiSpeakers
      .map(
        (speakerId) => DialogueEvent(
          leaderId: speakerId,
          category: 'reactive',
          situation: 'tech_first',
          era: era,
          variables: {'otherNation': discovererId, 'techId': techId},
        ),
      )
      .toList();
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
  if (!_isAiGp(game, capitalOwnerId)) return const [];
  final humanAttackers = attackerFactionIds.where((id) => _isHumanGp(game, id));
  final primaryAttacker = humanAttackers.toList()..sort();
  if (primaryAttacker.isEmpty) return const [];
  return [
    DialogueEvent(
      leaderId: capitalOwnerId,
      category: 'event',
      situation: 'capital_threatened',
      era: _eraForTurn(game, turnNumber),
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
  if (!_isAiGp(game, newOwnerId)) return const [];
  return [
    DialogueEvent(
      leaderId: newOwnerId,
      category: 'event',
      situation: 'colony_founded',
      era: _eraForTurn(game, turnNumber),
      variables: {'province': provinceId},
    ),
  ];
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
  if (!_isAiGp(game, speakerId)) return const [];
  if (!_isHumanGp(game, caughtSpyOwnerId)) return const [];
  return [
    DialogueEvent(
      leaderId: speakerId,
      category: 'reactive',
      situation: 'spies_caught',
      era: _eraForTurn(game, turnNumber),
      variables: {'otherNation': caughtSpyOwnerId, 'province': provinceId},
    ),
  ];
}
