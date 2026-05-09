import 'dart:math' show Random;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../ai/ai_control.dart';
import '../combat/conflict_detection.dart';
import '../constants.dart';
import '../dossier/evidence_rules.dart';
import '../turn/turn_resolution_result.dart';
import '../world/province_lookup.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_resolver.dart';
import 'overture_resolver.dart';

class InterventionResolutionResult {
  InterventionResolutionResult(this.game, {this.pendingInterventions});

  final Game game;
  final List<InterventionPrompt>? pendingInterventions;
}

bool _gpHasEmbassyOrPurchasedLandInMinorTribe(
  Game game,
  String gpId,
  String minorOrTribeId,
) {
  final o = getOverture(game, gpId, minorOrTribeId);
  final hasEmbassy = o != null && o.hasEmbassy;
  final hasInvestment = _gpHasPurchasedLandInFactionProvinces(
    game,
    gpId,
    minorOrTribeId,
  );
  return hasEmbassy || hasInvestment;
}

bool _interventionChoiceRecordedForTurn(
  Game game,
  int turn,
  String interveningGpId,
  String aggressorGpId,
) {
  for (final e in game.diplomaticHistoryEvents) {
    if (e.turn != turn) continue;
    if (e.fromFactionId != interveningGpId || e.toFactionId != aggressorGpId) {
      continue;
    }
    if (e.type == DiplomaticEventType.interventionIntervene ||
        e.type == DiplomaticEventType.interventionDoNothing ||
        e.type == DiplomaticEventType.interventionProtest) {
      return true;
    }
  }
  return false;
}

bool _interventionsOutstanding(
  Game game,
  int turn,
  String aggressorGpId,
  String defenderMinorOrTribeId,
  DiplomacyFactionMembership factionMembership,
) {
  for (final p in game.players) {
    if (!factionMembership.isGreatPower(p.id) || p.id == aggressorGpId) {
      continue;
    }
    if (!_gpHasEmbassyOrPurchasedLandInMinorTribe(
      game,
      p.id,
      defenderMinorOrTribeId,
    )) {
      continue;
    }
    if (!_interventionChoiceRecordedForTurn(game, turn, p.id, aggressorGpId)) {
      return true;
    }
  }
  return false;
}

InterventionDecision? _findInterventionDecision(
  List<InterventionDecision>? list,
  String aggressorGpId,
  String defenderMinorOrTribeId,
  String interveningGpId,
) {
  if (list == null) return null;
  for (final d in list) {
    if (d.aggressorGpId == aggressorGpId &&
        d.defenderMinorOrTribeId == defenderMinorOrTribeId &&
        d.interveningGpId == interveningGpId) {
      return d;
    }
  }
  return null;
}

class CallToArmsResult {
  CallToArmsResult(this.game, {this.pendingCallToArms});
  final Game game;
  final List<CallToArmsPending>? pendingCallToArms;
}

CallToArmsDecision? _findCallToArmsDecision(
  List<CallToArmsDecision>? decisions,
  String allyGpId,
  String defenderGpId,
  String aggressorGpId,
) {
  if (decisions == null) return null;
  for (final d in decisions) {
    if (d.allyGpId == allyGpId &&
        d.defenderGpId == defenderGpId &&
        d.aggressorGpId == aggressorGpId) {
      return d;
    }
  }
  return null;
}

/// Relation score 0–25 → 0%, 26–50 → 25%, 51–75 → 50%, 76–100 → 80%.
double _aiInterventionProbability(int relationScore) {
  if (relationScore <= relationScoreLevelHostileMax) return 0;
  if (relationScore <= relationScoreLevelNeutralMax) {
    return kInterventionProbabilityNeutral;
  }
  if (relationScore <= relationScoreLevelFriendlyMax) {
    return kInterventionProbabilityFriendly;
  }
  return kInterventionProbabilityAllied;
}

InterventionChoice _chooseAiIntervention(
  Game game,
  String aiGpId,
  String aggressorGpId,
  String defenderMinorOrTribeId,
  int turn,
) {
  final rel = getRelation(game, aiGpId, defenderMinorOrTribeId);
  final score = rel?.score ?? relationScoreNeutral;
  final p = _aiInterventionProbability(score);
  final seed = Object.hash(turn, aiGpId, aggressorGpId, defenderMinorOrTribeId);
  final roll = Random(seed).nextDouble();
  return roll < p ? InterventionChoice.intervene : InterventionChoice.doNothing;
}

Game _clearOverturesBetweenGpAndMinorTribe(
  Game game,
  String gpId,
  String minorOrTribeId,
) {
  final overtures = game.overtureStates
      .where((o) => !(o.gpId == gpId && o.targetId == minorOrTribeId))
      .toList();
  if (overtures.length == game.overtureStates.length) return game;
  return game.copyWith(overtureStates: overtures);
}

InterventionResolutionResult _processInterventionsForAggressorDefender(
  Game game, {
  required String aggressorGpId,
  required String defenderMinorOrTribeId,
  required int turn,
  required DiplomacyFactionMembership factionMembership,
  List<InterventionDecision>? interventionDecisions,
}) {
  final eligible = <String>[];
  for (final p in game.players) {
    if (!factionMembership.isGreatPower(p.id) || p.id == aggressorGpId) {
      continue;
    }
    if (!_gpHasEmbassyOrPurchasedLandInMinorTribe(
      game,
      p.id,
      defenderMinorOrTribeId,
    )) {
      continue;
    }
    eligible.add(p.id);
  }
  eligible.sort();
  var g = game;
  final pending = <InterventionPrompt>[];
  for (final interveningId in eligible) {
    if (_interventionChoiceRecordedForTurn(
      g,
      turn,
      interveningId,
      aggressorGpId,
    )) {
      continue;
    }
    final player = g.playerById(interveningId);
    if (player == null) continue;
    if (player.isHuman) {
      final d = _findInterventionDecision(
        interventionDecisions,
        aggressorGpId,
        defenderMinorOrTribeId,
        interveningId,
      );
      if (d == null) {
        pending.add(
          InterventionPrompt(
            aggressorGpId: aggressorGpId,
            defenderMinorOrTribeId: defenderMinorOrTribeId,
            interveningGpId: interveningId,
          ),
        );
        continue;
      }
      g = applyInterventionAgainstAggressor(
        g,
        aggressorGpId: aggressorGpId,
        defenderMinorOrTribeId: defenderMinorOrTribeId,
        interveningGpId: interveningId,
        choice: d.choice,
        factionMembership: factionMembership,
      );
      continue;
    }
    final aiChoice = _chooseAiIntervention(
      g,
      interveningId,
      aggressorGpId,
      defenderMinorOrTribeId,
      turn,
    );
    g = applyInterventionAgainstAggressor(
      g,
      aggressorGpId: aggressorGpId,
      defenderMinorOrTribeId: defenderMinorOrTribeId,
      interveningGpId: interveningId,
      choice: aiChoice,
      factionMembership: factionMembership,
    );
  }
  if (pending.isNotEmpty) {
    return InterventionResolutionResult(g, pendingInterventions: pending);
  }
  return InterventionResolutionResult(g);
}

InterventionResolutionResult resolveOutstandingInterventionsForMinorTribeWars(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  List<InterventionDecision>? interventionDecisions,
}) {
  final seen = <String>{};
  var g = game;
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.declareWar) continue;
      final targetId = order.targetFactionId;
      if (!factionMembership.isGreatPower(gpId) ||
          !factionMembership.isMinorOrTribe(targetId)) {
        continue;
      }
      final rel = getRelation(g, gpId, targetId);
      if (rel == null || !rel.atWar) continue;
      final key = '$gpId|$targetId';
      if (seen.contains(key)) continue;
      seen.add(key);
      if (!_interventionsOutstanding(
            g,
            turn,
            gpId,
            targetId,
            factionMembership,
          )) {
        continue;
      }
      final pass = _processInterventionsForAggressorDefender(
        g,
        aggressorGpId: gpId,
        defenderMinorOrTribeId: targetId,
        turn: turn,
        factionMembership: factionMembership,
        interventionDecisions: interventionDecisions,
      );
      g = pass.game;
      if (pass.pendingInterventions != null &&
          pass.pendingInterventions!.isNotEmpty) {
        return pass;
      }
    }
  }
  return InterventionResolutionResult(g);
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

Game cancelSubsidiesBetweenGps(Game game, String id1, String id2, int turn) {
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
    );
  }
  return g;
}

Game _applyCallToArmsAccept(
  Game game,
  String allyGpId,
  String aggressorGpId,
  int turn,
) {
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
  relations = setWarStateForPair(
    relations: relations,
    gpId: allyGpId,
    targetId: aggressorGpId,
    turn: turn,
  );
  var g = game.copyWith(diplomacyRelations: relations);
  g = cancelSubsidiesBetweenGps(g, allyGpId, aggressorGpId, turn);
  g = appendDiplomaticEvent(
    g,
    turn,
    DiplomaticEventType.callToArmsAccepted,
    {allyGpId, aggressorGpId},
    fromFactionId: allyGpId,
    toFactionId: aggressorGpId,
    wasAiInitiator: isAiControlledForEvidence(g, allyGpId),
  );
  diploLog.i(
    'diplomacy call to arms accept $allyGpId joins war vs $aggressorGpId',
  );
  return g;
}

Game _applyCallToArmsRefuse(
  Game game,
  String allyGpId,
  String defenderGpId,
  int turn,
) {
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
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
    dossierEvidenceEntries: [
      ...game.dossierEvidenceEntries,
      ...refuseEvidence,
    ],
  );
  g = appendDiplomaticEvent(
    g,
    turn,
    DiplomaticEventType.callToArmsRefused,
    {allyGpId, defenderGpId},
    fromFactionId: allyGpId,
    toFactionId: defenderGpId,
    wasAiInitiator: isAiControlledForEvidence(g, allyGpId),
  );
  diploLog.i(
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
) {
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

    if (isAiControlled(state, allyGpId)) {
      final accept = rel.score >= callToArmsAiAcceptMinRelationScore;
      if (accept) {
        state = _applyCallToArmsAccept(state, allyGpId, aggressorGpId, turn);
      } else {
        state = _applyCallToArmsRefuse(state, allyGpId, defenderGpId, turn);
      }
      continue;
    }

    final decision = _findCallToArmsDecision(
      callToArmsDecisions,
      allyGpId,
      defenderGpId,
      aggressorGpId,
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
      state = _applyCallToArmsAccept(state, allyGpId, aggressorGpId, turn);
    } else {
      state = _applyCallToArmsRefuse(state, allyGpId, defenderGpId, turn);
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

bool _gpHasPurchasedLandInFactionProvinces(
  Game game,
  String gpId,
  String factionId,
) {
  if (game.worldState.purchasedTilesByTileKey.isEmpty) return false;
  final worldState = game.worldState;
  for (final entry in worldState.purchasedTilesByTileKey.entries) {
    if (entry.value != gpId) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = worldState.tryGetProvince(provinceId);
    if (province != null && province.ownerId == factionId) {
      return true;
    }
  }
  return false;
}

/// Applies intervention for one aggressor GP (Diplomacy phase when a GP declares
/// war on a Minor/Tribe; legacy combat hook may use [applyInterventionChoice]).
/// SPEC/game/diplomacy.md § Intervention.
Game applyInterventionAgainstAggressor(
  Game game, {
  required String aggressorGpId,
  required String defenderMinorOrTribeId,
  required String interveningGpId,
  required InterventionChoice choice,
  DiplomacyFactionMembership? factionMembership,
}) {
  final turn = game.worldState.turnState.turnNumber;
  final aggressorIsGp = factionMembership?.isGreatPower(aggressorGpId) ??
      isGreatPower(game, aggressorGpId);
  if (!aggressorIsGp) return game;

  if (choice == InterventionChoice.doNothing) {
    var g = _clearOverturesBetweenGpAndMinorTribe(
      game,
      interveningGpId,
      defenderMinorOrTribeId,
    );
    g = appendDiplomaticEvent(
      g,
      turn,
      DiplomaticEventType.interventionDoNothing,
      {interveningGpId, aggressorGpId},
      fromFactionId: interveningGpId,
      toFactionId: aggressorGpId,
    );
    return g;
  }

  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);

  if (choice == InterventionChoice.intervene) {
    final ids = canonicalPairIds(interveningGpId, aggressorGpId);
    relations = upsertRelation(relations, interveningGpId, aggressorGpId, (
      existing,
    ) {
      if (existing == null) {
        return DiplomacyRelation(
          factionId1: ids.id1,
          factionId2: ids.id2,
          score: 40,
          level: RelationLevel.neutral,
          state: RelationState.atWar,
          sinceTurn: turn,
          lastInteractionTurn: turn,
        );
      }
      if (!existing.atPeace) return existing;
      final delta = warDeclarationThirdPartyPenaltyDelta(game, aggressorGpId);
      final newScore = (existing.score - delta).clamp(
        relationScoreMin,
        relationScoreMax,
      );
      return existing.copyWith(
        state: RelationState.atWar,
        sinceTurn: turn,
        lastInteractionTurn: turn,
        score: newScore,
        level: scoreToLevel(newScore),
      );
    });
  } else if (choice == InterventionChoice.protest) {
    final ids = canonicalPairIds(interveningGpId, aggressorGpId);
    relations = upsertRelation(relations, interveningGpId, aggressorGpId, (
      existing,
    ) {
      final delta = warDeclarationThirdPartyPenaltyDelta(game, aggressorGpId);
      final newScore = ((existing?.score ?? relationScoreNeutral) - delta)
          .clamp(relationScoreMin, relationScoreMax);
      final newLevel = scoreToLevel(newScore);
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
  }

  var g = game.copyWith(diplomacyRelations: relations);
  final eventType = choice == InterventionChoice.intervene
      ? DiplomaticEventType.interventionIntervene
      : DiplomaticEventType.interventionProtest;
  g = appendDiplomaticEvent(
    g,
    turn,
    eventType,
    {interveningGpId, aggressorGpId},
    fromFactionId: interveningGpId,
    toFactionId: aggressorGpId,
  );
  return g;
}

/// Returns gpId of a human GP with Embassy or purchased land for the
/// Minor/Tribe defender, or null. Used for tests and legacy combat hooks;
/// primary intervention flow runs in the Diplomacy phase.
String? needsInterventionChoice(Game game, BattleContext ctx) {
  final defenderId = ctx.defenderFactionId;
  final defenderIsMinorOrTribe = isMinorOrTribe(game, defenderId);
  if (!defenderIsMinorOrTribe) return null;

  final attackerIds = ctx.attackers.map((a) => a.factionId).toSet();
  final attackerIsGp = attackerIds.any(
    (id) => game.players.any((p) => p.id == id),
  );
  if (!attackerIsGp) return null;

  for (final p in game.players) {
    if (!p.isHuman) continue;
    if (attackerIds.contains(p.id)) continue;

    final o = getOverture(game, p.id, defenderId);
    final hasEmbassy = o != null && o.hasEmbassy;
    final hasInvestment = _gpHasPurchasedLandInFactionProvinces(
      game,
      p.id,
      defenderId,
    );
    if (hasEmbassy || hasInvestment) return p.id;
  }
  return null;
}

/// Applies intervention for each Great Power attacker in [ctx] (legacy combat hook).
/// Prefer [applyInterventionAgainstAggressor] for Diplomacy-phase declaration flow.
Game applyInterventionChoice(
  Game game,
  BattleContext ctx,
  String gpIdWithEmbassy,
  InterventionChoice choice,
) {
  var g = game;
  for (final a in ctx.attackers) {
    final attackerId = a.factionId;
    if (!isGreatPower(game, attackerId)) continue;
    g = applyInterventionAgainstAggressor(
      g,
      aggressorGpId: attackerId,
      defenderMinorOrTribeId: ctx.defenderFactionId,
      interveningGpId: gpIdWithEmbassy,
      choice: choice,
    );
  }
  return g;
}
