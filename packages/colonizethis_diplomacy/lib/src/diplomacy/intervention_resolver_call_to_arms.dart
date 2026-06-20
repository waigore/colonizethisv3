import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../dossier/evidence_rules.dart'
    show evidenceForIsolationistCallToArmsRefuse;
import 'diplomacy_logging.dart';
import 'diplomacy_phase_result.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_shared_helpers.dart';
import 'overture_resolver.dart';

class CallToArmsResult {
  CallToArmsResult(this.game, {this.pendingCallToArms});
  final Game game;
  final List<CallToArmsPending>? pendingCallToArms;
}

/// GP–GP war pairs from declare-war orders that are at war after step 5.
List<({String aggressor, String defender})> _gpGpWarPairsFromOrders(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  DiplomacyFactionMembership factionMembership,
) {
  final seen = <String>{};
  final out = <({String aggressor, String defender})>[];
  for (final e in diploByPlayer.entries) {
    final aggressor = e.key;
    if (!factionMembership.isGreatPower(aggressor)) continue;
    for (final o in e.value) {
      if (o.type != DiplomaticOrderType.declareWar) continue;
      final defender = o.targetFactionId;
      if (!factionMembership.isGreatPower(defender)) continue;
      if (!factionsAtWar(game, aggressor, defender)) continue;
      final key = '$aggressor|$defender';
      if (seen.add(key)) {
        out.add((aggressor: aggressor, defender: defender));
      }
    }
  }
  return out;
}

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
    diploLog.i(
      'diplomacy subsidies cancelled due to war ${s.payerId} vs ${s.targetId}',
    );
    g = appendDiplomaticEvent(
      g,
      turn,
      DiplomaticEventType.subsidyCancelled,
      {s.payerId, s.targetId},
      fromFactionId: s.payerId,
      toFactionId: s.targetId,
      reason: 'war',
      wasAiInitiator: isAiControlledForEvidence(g, s.payerId),
      eventTally: eventTally,
    );
  }
  return g;
}

Game _applyCallToArmsAccept(
  Game game,
  String allyGpId,
  String aggressorGpId,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
  relations = setWarStateForPair(
    relations: relations,
    gpId: allyGpId,
    targetId: aggressorGpId,
    turn: turn,
  );
  var g = game.copyWith(diplomacyRelations: relations);
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

Game _applyCallToArmsRefuse(
  Game game,
  String allyGpId,
  String defenderGpId,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
  // Single isolated upsert for one call-to-arms refusal (not a loop), so the
  // standalone helper is acceptable here over RelationUpsertIndex (Refs #3562
  // AC5).
  relations = upsertRelation(relations, allyGpId, defenderGpId, (existing) {
    final base = existing?.score ?? relationScoreNeutral;
    var newScore = (base - callToArmsRefusalScorePenalty).clamp(
      relationScoreMin,
      relationScoreMax,
    );
    var newLevel = scoreToLevel(newScore);
    if (newLevel == RelationLevel.allied) {
      newScore = relationScoreLevelFriendlyMax;
      newLevel = RelationLevel.friendly;
    }
    final ids = canonicalPairIds(allyGpId, defenderGpId);
    if (existing == null) {
      return DiplomacyRelation(
        factionId1: ids.id1,
        factionId2: ids.id2,
        score: newScore,
        level: newLevel,
        lastInteractionTurn: turn,
      );
    }
    return existing.copyWith(
      score: newScore,
      level: newLevel,
      lastInteractionTurn: turn,
    );
  });
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
  return g;
}

Game _processCallToArmsForWarPair(
  Game state,
  ({String aggressor, String defender}) pair,
  int turn,
  List<CallToArmsDecision>? callToArmsDecisions,
  List<CallToArmsPending> pending,
  DiplomacyFactionMembership factionMembership, {
  IntraTurnEventTally? eventTally,
}) {
  final aggressorGpId = pair.aggressor;
  final defenderGpId = pair.defender;
  for (final p in state.players) {
    final allyGpId = p.id;
    if (allyGpId == defenderGpId || allyGpId == aggressorGpId) continue;
    if (factionsAtWar(state, allyGpId, aggressorGpId)) continue;
    final rel = getRelation(state, allyGpId, defenderGpId);
    if (rel == null || !rel.atPeace || rel.level != RelationLevel.allied) {
      continue;
    }

    // Canonical pending-human-decision flow (diplomacy_shared_helpers.dart):
    // human ally applies a supplied decision or suspends pending; otherwise the
    // AI rule resolves immediately. Call-to-arms intentionally keys the split on
    // the override-aware isAiControlled (negated) rather than isTargetHumanGp,
    // preserving the existing aiControlByGpId-aware behaviour.
    if (!isAiControlled(state, allyGpId)) {
      final decision = findHumanDecision<CallToArmsDecision>(
        callToArmsDecisions,
        (d) =>
            d.allyGpId == allyGpId &&
            d.defenderGpId == defenderGpId &&
            d.aggressorGpId == aggressorGpId,
      );
      if (decision == null) {
        pending.add(
          CallToArmsPending(
            allyGpId: allyGpId,
            defenderGpId: defenderGpId,
            aggressorGpId: aggressorGpId,
          ),
        );
        continue;
      }
      if (decision.accepted) {
        state = _applyCallToArmsAccept(
          state,
          allyGpId,
          aggressorGpId,
          turn,
          eventTally: eventTally,
        );
      } else {
        state = _applyCallToArmsRefuse(
          state,
          allyGpId,
          defenderGpId,
          turn,
          eventTally: eventTally,
        );
      }
      continue;
    }

    final aggressorOw = provinceCountOwnedBy(state, aggressorGpId);
    final aiTurn = state.worldState.turnState.turnNumber;
    if (isBelowObserverConquestQuota(aggressorOw)) {
      state = _applyCallToArmsRefuse(
        state,
        allyGpId,
        defenderGpId,
        aiTurn,
        eventTally: eventTally,
      );
      continue;
    }
    if (atWarGreatPowerCount(state, allyGpId, factionMembership) >= 1) {
      state = _applyCallToArmsRefuse(
        state,
        allyGpId,
        defenderGpId,
        aiTurn,
        eventTally: eventTally,
      );
      continue;
    }
    final accept = rel.score >= callToArmsAiAcceptMinRelationScore;
    if (accept) {
      state = _applyCallToArmsAccept(
        state,
        allyGpId,
        aggressorGpId,
        aiTurn,
        eventTally: eventTally,
      );
    } else {
      state = _applyCallToArmsRefuse(
        state,
        allyGpId,
        defenderGpId,
        aiTurn,
        eventTally: eventTally,
      );
    }
  }
  return state;
}

CallToArmsResult processCallToArms(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  List<CallToArmsDecision>? callToArmsDecisions,
  IntraTurnEventTally? eventTally,
}) {
  var state = game;
  final warPairs = _gpGpWarPairsFromOrders(
    state,
    diploByPlayer,
    factionMembership,
  );
  final pending = <CallToArmsPending>[];

  for (final pair in warPairs) {
    state = _processCallToArmsForWarPair(
      state,
      pair,
      turn,
      callToArmsDecisions,
      pending,
      factionMembership,
      eventTally: eventTally,
    );
  }

  pending.sort((a, b) {
    final c1 = a.allyGpId.compareTo(b.allyGpId);
    if (c1 != 0) return c1;
    final c2 = a.defenderGpId.compareTo(b.defenderGpId);
    if (c2 != 0) return c2;
    return a.aggressorGpId.compareTo(b.aggressorGpId);
  });

  if (pending.isNotEmpty) {
    return CallToArmsResult(state, pendingCallToArms: pending);
  }
  return CallToArmsResult(state);
}
