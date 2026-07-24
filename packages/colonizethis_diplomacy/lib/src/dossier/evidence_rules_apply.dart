// Evidence application rules for dossier suspicion scoring.
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../diplomacy/diplomacy_logging.dart';
import '../diplomacy/diplomacy_relation_lookup.dart';
import 'evidence_rules_predicates.dart';

/// Evidence entries for "AI declared war". Warmonger if target is weaker GP; backstabber if was allied.
List<DossierEvidenceEntry> evidenceForDeclareWar(
  Game game,
  String actorGpId,
  String targetFactionId,
  int turnNumber,
) {
  final observers = evidenceObservers(game, actorGpId);
  if (observers == null) return [];

  final rel = getRelation(game, actorGpId, targetFactionId);
  final wasAllied = rel != null && rel.level == RelationLevel.allied;
  final targetIsGp = game.playerById(targetFactionId) != null;
  final weaker =
      targetIsGp && isWeakerGpForEvidence(game, actorGpId, targetFactionId);

  final treatyBreakAttack =
      !wasAllied &&
      hadCallToArmsRefusedWithTargetInAttackWindow(
        game,
        actorGpId,
        targetFactionId,
        turnNumber,
      );

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    if (wasAllied) {
      entries.add(
        DossierEvidenceEntry(
          observerId: observerId,
          subjectId: actorGpId,
          agendaType: 'backstabber',
          turnNumber: turnNumber,
          description: 'declared war on ally',
          scoreDelta: 3,
        ),
      );
    } else if (treatyBreakAttack) {
      entries.add(
        DossierEvidenceEntry(
          observerId: observerId,
          subjectId: actorGpId,
          agendaType: 'backstabber',
          turnNumber: turnNumber,
          description: 'declared war soon after breaking alliance obligation',
          scoreDelta: 3,
        ),
      );
    }
    if (weaker) {
      entries.add(
        DossierEvidenceEntry(
          observerId: observerId,
          subjectId: actorGpId,
          agendaType: 'warmonger',
          turnNumber: turnNumber,
          description: 'declared war on weaker neighbor',
          scoreDelta: 2,
        ),
      );
    }
  }
  if (entries.isNotEmpty) {
    diploLog.d(
      'evidence for declareWar actor=$actorGpId target=$targetFactionId entries=${entries.length}',
    );
  }
  return entries;
}

/// Evidence entries for "AI offered peace". Peacemaker tendency.
List<DossierEvidenceEntry> evidenceForOfferPeace(
  Game game,
  String actorGpId,
  String targetFactionId,
  int turnNumber,
) {
  final observers = evidenceObservers(game, actorGpId);
  if (observers == null) return [];

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    entries.add(
      DossierEvidenceEntry(
        observerId: observerId,
        subjectId: actorGpId,
        agendaType: 'peacemaker',
        turnNumber: turnNumber,
        description: 'offered peace',
        scoreDelta: 1,
      ),
    );
  }
  diploLog.d(
    'evidence for offerPeace actor=$actorGpId target=$targetFactionId entries=${entries.length}',
  );
  return entries;
}

/// Evidence entries for "AI won land battle as attacker". Warmonger; +2 if defender was weaker GP.
/// SPEC/ai/hidden-agendas.md: observable actions add suspicion (e.g. attacks weaker neighbors).
List<DossierEvidenceEntry> evidenceForLandBattleVictory(
  Game game,
  String victorGpId,
  String defenderFactionId,
  int turnNumber,
) {
  final observers = evidenceObservers(game, victorGpId);
  if (observers == null) return [];

  final targetIsGp = game.playerById(defenderFactionId) != null;
  final weaker =
      targetIsGp && isWeakerGpForEvidence(game, victorGpId, defenderFactionId);
  final scoreDelta = weaker ? 2 : 1;

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    entries.add(
      DossierEvidenceEntry(
        observerId: observerId,
        subjectId: victorGpId,
        agendaType: 'warmonger',
        turnNumber: turnNumber,
        description: weaker
            ? 'won battle vs weaker neighbor'
            : 'won battle as attacker',
        scoreDelta: scoreDelta,
      ),
    );
  }
  if (entries.isNotEmpty) {
    diploLog.d(
      'evidence for land battle victory victor=$victorGpId defender=$defenderFactionId entries=${entries.length}',
    );
  }
  return entries;
}

/// Evidence entries for "AI won naval battle" (one side eliminated). Warmonger tendency.
List<DossierEvidenceEntry> evidenceForNavalBattleVictory(
  Game game,
  String victorOwnerId,
  String loserOwnerId,
  int turnNumber,
) {
  final observers = evidenceObservers(game, victorOwnerId);
  if (observers == null) return [];

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    entries.add(
      DossierEvidenceEntry(
        observerId: observerId,
        subjectId: victorOwnerId,
        agendaType: 'warmonger',
        turnNumber: turnNumber,
        description: 'won naval battle',
        scoreDelta: 1,
      ),
    );
  }
  if (entries.isNotEmpty) {
    diploLog.d(
      'evidence for naval battle victory victor=$victorOwnerId loser=$loserOwnerId entries=${entries.length}',
    );
  }
  return entries;
}

/// Isolationist agenda: AI declines call to arms while still at peace with defender.
/// SPEC/ai/hidden-agendas.md.
List<DossierEvidenceEntry> evidenceForIsolationistCallToArmsRefuse(
  Game game,
  String allyGpId,
  String defenderGpId,
  int turnNumber,
) {
  final observers = evidenceObservers(game, allyGpId);
  if (observers == null) return [];
  final rel = getRelation(game, allyGpId, defenderGpId);
  if (rel == null || !rel.atPeace) {
    return [];
  }

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    entries.add(
      DossierEvidenceEntry(
        observerId: observerId,
        subjectId: allyGpId,
        agendaType: 'isolationist',
        turnNumber: turnNumber,
        description: 'declined call to arms while at peace',
        scoreDelta: 2,
      ),
    );
  }
  return entries;
}

/// Envy agenda: AI completed research (or extraction build) in the same tech-catalog
/// category the human most recently completed, within **2 turns** after that human
/// completion (same turn counts).
/// **+1** per qualifying completion, **max +3** total envy suspicion for the
/// subject AI in that turn. SPEC/ai/hidden-agendas.md.
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

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    entries.add(
      DossierEvidenceEntry(
        observerId: observerId,
        subjectId: aiGpId,
        agendaType: 'envy',
        turnNumber: turnNumber,
        description:
            'mirrored human category (research or extraction build) within window',
        scoreDelta: 1,
      ),
    );
  }
  if (entries.isNotEmpty) {
    diploLog.d(
      'evidence envy mirror ai=$aiGpId category=$completedCategory turn=$turnNumber',
    );
  }
  return entries;
}
