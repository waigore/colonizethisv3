// Agenda-specific evidence application rules for dossier suspicion scoring.
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_relation_lookup.dart';
import 'evidence_rules_predicates.dart';

/// Isolationist agenda: AI declines call to arms while still at peace with defender.
List<DossierEvidenceEntry> evidenceForIsolationistCallToArmsRefuse(
  Game game,
  String allyGpId,
  String defenderGpId,
  int turnNumber,
) {
  final observers = evidenceObservers(game, allyGpId);
  if (observers == null) return [];
  final rel = getRelation(game, allyGpId, defenderGpId);
  if (rel == null || !rel.atPeace) return [];
  return evidenceEntriesForObservers(
    observers,
    subjectId: allyGpId,
    agendaType: 'isolationist',
    turnNumber: turnNumber,
    description: 'declined call to arms while at peace',
    scoreDelta: 2,
  );
}

/// Envy agenda evidence for matching a recently completed human research category.
List<DossierEvidenceEntry> evidenceForEnvyResearchMirror(
  Game game,
  String aiGpId,
  String completedCategory,
  int turnNumber,
  List<DossierEvidenceEntry> pendingSameTurn,
) {
  final observers = evidenceObservers(game, aiGpId);
  if (observers == null) return [];
  final refCat = game.lastHumanCompletedResearchCategory;
  final refTurn = game.lastHumanResearchCategoryCompletionTurn;
  if (refCat == null || refTurn == null) return [];
  if (completedCategory != refCat) return [];
  if (turnNumber < refTurn || turnNumber > refTurn + 2) return [];
  final already = envyScoreAccumulatedForSubjectAndTurn(
    game,
    aiGpId,
    turnNumber,
    pendingSameTurn,
  );
  if (already >= 3) return [];
  return evidenceEntriesForObservers(
    observers,
    subjectId: aiGpId,
    agendaType: 'envy',
    turnNumber: turnNumber,
    description:
        'mirrored human category (research or extraction build) within window',
    scoreDelta: 1,
  );
}
