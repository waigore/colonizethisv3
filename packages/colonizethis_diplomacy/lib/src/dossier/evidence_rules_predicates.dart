// Evidence rule predicates and observer guards.
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../diplomacy/diplomacy_shared_helpers.dart'
    show isAiControlledForEvidence;

/// Human Great Power ids (observers for whom we store evidence).
List<String> humanObserverIds(Game game) {
  return game.players.where((p) => p.isHuman).map((p) => p.id).toList();
}

/// Returns the human observer ids for which evidence about [subjectId] should
/// be recorded, or null when no evidence applies.
///
/// Consolidates the AI-subject + at-least-one-human-observer guard repeated at
/// the top of every `evidenceFor*` rule (Refs #3419): evidence is recorded only
/// when [subjectId] is AI-controlled and at least one human observer exists.
List<String>? evidenceObservers(Game game, String subjectId) {
  if (!isAiControlledForEvidence(game, subjectId)) return null;
  final observers = humanObserverIds(game);
  if (observers.isEmpty) return null;
  return observers;
}

/// Builds one identical evidence entry for each human observer.
List<DossierEvidenceEntry> evidenceEntriesForObservers(
  List<String> observerIds, {
  required String subjectId,
  required String agendaType,
  required int turnNumber,
  required String description,
  required int scoreDelta,
}) {
  return [
    for (final observerId in observerIds)
      DossierEvidenceEntry(
        observerId: observerId,
        subjectId: subjectId,
        agendaType: agendaType,
        turnNumber: turnNumber,
        description: description,
        scoreDelta: scoreDelta,
      ),
  ];
}

/// True when [actorGpId] refused call-to-arms toward [targetGpId] in the same
/// turn as [warTurn] or within the prior [window] turns (treaty strain then attack).
/// SPEC/ai/hidden-agendas.md (Backstabber evidence).
bool hadCallToArmsRefusedWithTargetInAttackWindow(
  Game game,
  String actorGpId,
  String targetGpId,
  int warTurn, {
  int window = 3,
}) {
  for (final e in game.diplomaticHistoryEvents) {
    if (e.type != DiplomaticEventType.callToArmsRefused) continue;
    if (e.fromFactionId != actorGpId || e.toFactionId != targetGpId) continue;
    final delta = warTurn - e.turn;
    if (delta >= 0 && delta <= window) {
      return true;
    }
  }
  return false;
}

/// Returns true if [targetId] is a weaker GP than [actorId] by military level (for warmonger evidence).
bool isWeakerGpForEvidence(Game game, String actorId, String targetId) {
  final actor = game.playerById(actorId);
  final target = game.playerById(targetId);
  if (actor == null || target == null) return false;
  final aLevel = actor.militaryLevel ?? 0;
  final tLevel = target.militaryLevel ?? 0;
  return tLevel < aLevel;
}

int envyScoreAccumulatedForSubjectAndTurn(
  Game game,
  String subjectId,
  int turnNumber,
  List<DossierEvidenceEntry> pendingSameTurn,
) {
  var sum = 0;
  for (final e in game.dossierEvidenceEntries) {
    if (e.subjectId == subjectId &&
        e.agendaType == 'envy' &&
        e.turnNumber == turnNumber) {
      sum += e.scoreDelta;
    }
  }
  for (final e in pendingSameTurn) {
    if (e.subjectId == subjectId &&
        e.agendaType == 'envy' &&
        e.turnNumber == turnNumber) {
      sum += e.scoreDelta;
    }
  }
  return sum;
}
