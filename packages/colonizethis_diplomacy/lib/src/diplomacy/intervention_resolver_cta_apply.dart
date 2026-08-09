import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../dossier/evidence_rules.dart'
    show evidenceForIsolationistCallToArmsRefuse;
import 'diplomacy_event_logging.dart';
import 'diplomacy_phase_result.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_shared_helpers.dart';

Game cancelSubsidiesBetweenGps(
  Game game,
  String id1,
  String id2,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);
  final cancelled = subsidyStates
      .where(
        (s) =>
            (s.payerId == id1 && s.targetId == id2) ||
            (s.payerId == id2 && s.targetId == id1),
      )
      .toList();
  if (cancelled.isEmpty) return game;
  subsidyStates = subsidyStates
      .where(
        (s) =>
            !((s.payerId == id1 && s.targetId == id2) ||
                (s.payerId == id2 && s.targetId == id1)),
      )
      .toList();
  var g = game.copyWith(subsidyStates: subsidyStates);
  for (final s in cancelled) {
    g = logDiplomaticEvent(
      g,
      turn,
      DiplomaticEventType.subsidyCancelled,
      {s.payerId, s.targetId},
      fromFactionId: s.payerId,
      toFactionId: s.targetId,
      reason: 'war',
      wasAiInitiator: isAiControlledForEvidence(g, s.payerId),
      eventTally: eventTally,
      logMessage:
          'diplomacy subsidies cancelled due to war ${s.payerId} vs ${s.targetId}',
    );
  }
  return g;
}

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

Game processCallToArmsForWarPair(
  Game state,
  ({String aggressor, String defender}) pair,
  int turn,
  List<CallToArmsDecision>? callToArmsDecisions,
  List<CallToArmsPending> pending,
  DiplomacyFactionMembership factionMembership,
  Set<String> formalAlliancePairKeysAtPhaseStart, {
  IntraTurnEventTally? eventTally,
}) {
  final aggressorGpId = pair.aggressor;
  final defenderGpId = pair.defender;
  for (final p in state.players) {
    final allyGpId = p.id;
    if (allyGpId == defenderGpId || allyGpId == aggressorGpId) continue;
    if (factionsAtWar(state, allyGpId, aggressorGpId)) continue;
    final rel = getRelation(state, allyGpId, defenderGpId);
    // Mutual defence requires a persisted FORMAL alliance that existed at the
    // end of the preceding turn (snapshot taken at phase start, before this
    // turn's alliance orders resolve). The informal Allied relation band must
    // not trigger Call to Arms on its own. SPEC/game/diplomacy.md § Alliances.
    final hadFormalAlliance = formalAlliancePairKeysAtPhaseStart.contains(
      pairKey(allyGpId, defenderGpId),
    );
    if (rel == null || !rel.atPeace || !hadFormalAlliance) {
      continue;
    }

    // Canonical pending-human-decision flow (diplomacy_shared_helpers.dart):
    // human ally applies a supplied decision or suspends pending; otherwise the
    // AI rule resolves immediately. Call-to-arms intentionally keys the split on
    // the override-aware isAiControlled (negated) rather than isTargetHumanGp,
    // preserving the existing aiControlByGpId-aware behaviour.
    state = resolveHumanGatedDecision<CallToArmsDecision, Game>(
      isHumanControlled: !isAiControlled(state, allyGpId),
      decisions: callToArmsDecisions,
      matches: (d) =>
          d.allyGpId == allyGpId &&
          d.defenderGpId == defenderGpId &&
          d.aggressorGpId == aggressorGpId,
      onAiResolve: () {
        final aggressorOw = provinceCountOwnedBy(state, aggressorGpId);
        final aiTurn = state.worldState.turnState.turnNumber;
        if (isBelowObserverConquestQuota(aggressorOw)) {
          return applyCallToArmsRefuse(
            state,
            allyGpId,
            defenderGpId,
            aiTurn,
            aggressorGpId: aggressorGpId,
            factionMembership: factionMembership,
            eventTally: eventTally,
          );
        }
        if (atWarGreatPowerCount(state, allyGpId, factionMembership) >= 1) {
          return applyCallToArmsRefuse(
            state,
            allyGpId,
            defenderGpId,
            aiTurn,
            aggressorGpId: aggressorGpId,
            factionMembership: factionMembership,
            eventTally: eventTally,
          );
        }
        final accept = rel.score >= callToArmsAiAcceptMinRelationScore;
        if (accept) {
          return applyCallToArmsAccept(
            state,
            allyGpId,
            aggressorGpId,
            aiTurn,
            eventTally: eventTally,
          );
        }
        return applyCallToArmsRefuse(
          state,
          allyGpId,
          defenderGpId,
          aiTurn,
          aggressorGpId: aggressorGpId,
          factionMembership: factionMembership,
          eventTally: eventTally,
        );
      },
      onPending: () {
        pending.add(
          CallToArmsPending(
            allyGpId: allyGpId,
            defenderGpId: defenderGpId,
            aggressorGpId: aggressorGpId,
          ),
        );
        return state;
      },
      onHumanDecision: (decision) {
        if (decision.accepted) {
          return applyCallToArmsAccept(
            state,
            allyGpId,
            aggressorGpId,
            turn,
            eventTally: eventTally,
          );
        }
        return applyCallToArmsRefuse(
          state,
          allyGpId,
          defenderGpId,
          turn,
          aggressorGpId: aggressorGpId,
          factionMembership: factionMembership,
          eventTally: eventTally,
        );
      },
    );
  }
  return state;
}
