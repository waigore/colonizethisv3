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

  final entries = <DossierEvidenceEntry>[
    if (wasAllied || treatyBreakAttack)
      ...evidenceEntriesForObservers(
        observers,
        subjectId: actorGpId,
        agendaType: 'backstabber',
        turnNumber: turnNumber,
        description: wasAllied
            ? 'declared war on ally'
            : 'declared war soon after breaking alliance obligation',
        scoreDelta: 3,
      ),
    if (weaker)
      ...evidenceEntriesForObservers(
        observers,
        subjectId: actorGpId,
        agendaType: 'warmonger',
        turnNumber: turnNumber,
        description: 'declared war on weaker neighbor',
        scoreDelta: 2,
      ),
  ];
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

  final entries = evidenceEntriesForObservers(
    observers,
    subjectId: actorGpId,
    agendaType: 'peacemaker',
    turnNumber: turnNumber,
    description: 'offered peace',
    scoreDelta: 1,
  );
  diploLog.d(
    'evidence for offerPeace actor=$actorGpId target=$targetFactionId entries=${entries.length}',
  );
  return entries;
}
