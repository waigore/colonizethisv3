import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../dossier/evidence_rules.dart'
    show evidenceForIsolationistCallToArmsRefuse;
import 'diplomacy_event_logging.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_relation_upsert.dart';
import 'diplomacy_shared_helpers.dart';
import 'intervention_resolver_cta_subsidy.dart';

export 'intervention_resolver_cta_subsidy.dart' show cancelSubsidiesBetweenGps;

Game applyCallToArmsAccept(
  Game game,
  String allyGpId,
  String aggressorGpId,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  final relationsIndex = RelationUpsertIndex(game.diplomacyRelations);
  relationsIndex.upsert(
    allyGpId,
    aggressorGpId,
    warStateRelationUpdater(allyGpId, aggressorGpId, turn),
  );
  var g = withCommittedRelations(game, relationsIndex);
  g = cancelSubsidiesBetweenGps(
    g,
    allyGpId,
    aggressorGpId,
    turn,
    eventTally: eventTally,
  );
  g = logDiplomaticEvent(
    g,
    turn,
    DiplomaticEventType.callToArmsAccepted,
    {allyGpId, aggressorGpId},
    fromFactionId: allyGpId,
    toFactionId: aggressorGpId,
    wasAiInitiator: isAiControlledForEvidence(g, allyGpId),
    eventTally: eventTally,
    logMessage:
        'diplomacy call to arms accept $allyGpId joins war vs $aggressorGpId',
  );
  return g;
}

Game applyCallToArmsRefuse(
  Game game,
  String allyGpId,
  String defenderGpId,
  int turn, {
  required String aggressorGpId,
  required DiplomacyFactionMembership factionMembership,
  IntraTurnEventTally? eventTally,
}) {
  // Refusing a call to arms breaks the formal alliance with the defended ally
  // and applies the unified alliance-break penalty (R11): −50 to the ally pair
  // (alliance flag cleared) and −10 to every other Great Power the refuser has
  // a relation with. The aggressor that triggered the call to arms is excluded
  // from the −10 cascade (its relation is governed by the war rules, not the
  // alliance break). SPEC/game/diplomacy.md § Alliances.
  final otherGpIds = otherRelatedGreatPowerIds(game, allyGpId, {
    defenderGpId,
    aggressorGpId,
  });
  final relations = applyAllianceBreakPenalties(
    relations: game.diplomacyRelations,
    breakerId: allyGpId,
    brokenWithAllyId: defenderGpId,
    otherGpIds: otherGpIds,
    turn: turn,
  );
  final refuseEvidence = evidenceForIsolationistCallToArmsRefuse(
    game,
    allyGpId,
    defenderGpId,
    turn,
  );
  var g = game.copyWith(
    diplomacyRelations: relations,
    dossierEvidenceEntries: [...game.dossierEvidenceEntries, ...refuseEvidence],
  );
  g = logDiplomaticEvent(
    g,
    turn,
    DiplomaticEventType.callToArmsRefused,
    {allyGpId, defenderGpId},
    fromFactionId: allyGpId,
    toFactionId: defenderGpId,
    wasAiInitiator: isAiControlledForEvidence(g, allyGpId),
    eventTally: eventTally,
    logMessage:
        'diplomacy call to arms refuse $allyGpId breaks alliance with $defenderGpId',
  );
  g = logDiplomaticEvent(
    g,
    turn,
    DiplomaticEventType.allianceBroken,
    {allyGpId, defenderGpId},
    fromFactionId: allyGpId,
    toFactionId: defenderGpId,
    wasAiInitiator: isAiControlledForEvidence(g, allyGpId),
    eventTally: eventTally,
    logMessage:
        'diplomacy alliance broken $allyGpId-$defenderGpId on call to arms refuse',
  );
  return g;
}
