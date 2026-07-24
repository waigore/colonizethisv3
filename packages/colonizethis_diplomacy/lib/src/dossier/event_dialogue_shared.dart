// Shared dialogue helpers: era mapping, AI-subject builders, relation gates.
// SPEC/ai/dialogue-and-mood.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../diplomacy/diplomacy_relation_lookup.dart';
import '../diplomacy/diplomacy_shared_helpers.dart' show isAiControlledForEvidence;

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

/// Neighbor province local ids in [regionId] that share an edge with [localId]. Province nodes only.
List<String> neighborProvinceLocalIds(
  MapTopology topology,
  String regionId,
  String localId,
) {
  return neighborProvinceIdsInRegion(topology, regionId, localId).toList();
}

bool isAiGpForDialogue(Game game, String factionId) {
  return isAiControlledForEvidence(game, factionId);
}

/// Sorted AI Great Power speaker ids for reactive dialogue enumeration.
List<String> sortedAiSpeakerIdsForDialogue(Game game) =>
    game.players.where((p) => isAiGpForDialogue(game, p.id)).map((p) => p.id).toList()
      ..sort();

/// Single AI-subject dialogue event (event / reactive categories share shape).
DialogueEvent aiSubjectDialogueEvent({
  required String leaderId,
  required String category,
  required String situation,
  required String era,
  required Map<String, String> variables,
}) =>
    DialogueEvent(
      leaderId: leaderId,
      category: category,
      situation: situation,
      era: era,
      variables: variables,
    );

bool isMinorFactionForDialogue(Game game, String factionId) {
  return game.minorNations.any((m) => m.id == factionId);
}

bool isTribeFactionForDialogue(Game game, String factionId) {
  return game.tribes.any((t) => t.id == factionId);
}

bool isAlliedForDialogue(Game game, String a, String b) {
  final rel = getRelation(game, a, b);
  if (rel == null) return false;
  return rel.level == RelationLevel.allied &&
      rel.state == RelationState.atPeace;
}

/// True when [a] and [b] hold a persisted formal alliance treaty and are at
/// peace. Mutual-defence reactions (attack_on_ally) gate on this, not the
/// informal [RelationLevel.allied] band. SPEC/game/diplomacy.md § Alliances,
/// SPEC/ai/dialogue-and-mood.md (reactive: attack_on_ally).
bool hasFormalAllianceForDialogue(Game game, String a, String b) {
  final rel = getRelation(game, a, b);
  if (rel == null) return false;
  return rel.formalAlliance && rel.state == RelationState.atPeace;
}

bool hasEmbassyOrAllianceForDialogue(
  Game game,
  String speakerId,
  String targetId,
) =>
    hasEmbassyWithTargetForDialogue(game, speakerId, targetId) ||
    isAlliedForDialogue(game, speakerId, targetId);

bool hasEmbassyWithTargetForDialogue(Game game, String gpId, String targetId) {
  return game.overtureStates.any(
    (o) => o.gpId == gpId && o.targetId == targetId && o.hasEmbassy,
  );
}

String eraForDialogueTurn(Game game, int turnNumber) {
  final mapping = game.turnTimeMapping ?? TurnTimeMapping.gdd01;
  final year = mapping.yearAtTurn(turnNumber);
  return eraFromYear(year);
}
