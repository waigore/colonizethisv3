// Event dialogue: emit DialogueEvent when game events trigger commentary.
// SPEC/ai/dialogue-and-mood.md (event: battle result, era transition, reactive, negotiation),
// SPEC/program/ai-events-and-dossier.md.
// Only AI leaders emit for event/reactive; deterministic given game state and seed.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/movement.dart';
import 'evidence_rules.dart';

const String _eraDefault = 'earlyModern';

/// Era names for dialogue (SPEC/ai/dialogue-and-mood.md: discovery | earlyModern | imperial | industrial).
const List<String> kDialogueEras = ['discovery', 'earlyModern', 'imperial', 'industrial'];

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
    events.add(DialogueEvent(
      leaderId: p.id,
      category: 'event',
      situation: 'era_change',
      era: newEra,
      variables: {'previousEra': previousEra},
    ));
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

/// Neighbor province local ids in [regionId] that share an edge with [localId]. Province nodes only.
List<String> neighborProvinceLocalIds(MapTopology topology, String regionId, String localId) {
  return neighborProvinceIdsInRegion(topology, regionId, localId).toList();
}

String? _ownerOfProvince(Game game, String fullProvinceId) {
  for (final p in game.worldState.oldWorld.provinces) {
    if (p.id == fullProvinceId) return p.ownerId;
  }
  for (final p in game.worldState.newWorld.provinces) {
    if (p.id == fullProvinceId) return p.ownerId;
  }
  return null;
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
  final builder = game.players.where((p) => p.id == builderPlayerId).firstOrNull;
  if (builder == null || builder.isHuman != true) return [];
  final regionId = ProvinceId.regionIdFrom(provinceId);
  final localId = ProvinceId.localIdFrom(provinceId);
  final neighborLocalIds = neighborProvinceLocalIds(topology, regionId, localId);
  final mapping = game.turnTimeMapping ?? TurnTimeMapping.gdd01;
  final year = mapping.yearAtTurn(game.worldState.turnState.turnNumber);
  final era = eraFromYear(year);
  final events = <DialogueEvent>[];
  final seenAi = <String>{};
  for (final neighborLocal in neighborLocalIds) {
    final fullId = ProvinceId.full(regionId, neighborLocal);
    final ownerId = _ownerOfProvince(game, fullId);
    if (ownerId == null || !isAiControlledForEvidence(game, ownerId) || !seenAi.add(ownerId)) {
      continue;
    }
    events.add(DialogueEvent(
      leaderId: ownerId,
      category: 'reactive',
      situation: 'forts_on_border',
      era: era,
      variables: {'otherNation': builderPlayerId, 'province': provinceId},
    ));
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
