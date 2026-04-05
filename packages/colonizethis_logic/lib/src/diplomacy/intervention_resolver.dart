part of 'diplomacy_resolver.dart';

class _InterventionResolutionResult {
  _InterventionResolutionResult(this.game, {this.pendingInterventions});

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
) {
  for (final p in game.players) {
    if (!isGreatPower(game, p.id) || p.id == aggressorGpId) continue;
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

class _CallToArmsResult {
  _CallToArmsResult(this.game, {this.pendingCallToArms});
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
  if (relationScore <= relationScoreLevelNeutralMax) return 0.25;
  if (relationScore <= relationScoreLevelFriendlyMax) return 0.5;
  return 0.8;
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

_InterventionResolutionResult _processInterventionsForAggressorDefender(
  Game game, {
  required String aggressorGpId,
  required String defenderMinorOrTribeId,
  required int turn,
  List<InterventionDecision>? interventionDecisions,
}) {
  final eligible = <String>[];
  for (final p in game.players) {
    if (!isGreatPower(game, p.id) || p.id == aggressorGpId) continue;
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
    );
  }
  if (pending.isNotEmpty) {
    return _InterventionResolutionResult(g, pendingInterventions: pending);
  }
  return _InterventionResolutionResult(g);
}

_InterventionResolutionResult _resolveOutstandingInterventionsForMinorTribeWars(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  List<InterventionDecision>? interventionDecisions,
}) {
  final seen = <String>{};
  var g = game;
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.declareWar) continue;
      final targetId = order.targetFactionId;
      if (!isGreatPower(g, gpId) || !isMinorOrTribe(g, targetId)) continue;
      final rel = getRelation(g, gpId, targetId);
      if (rel == null || !rel.atWar) continue;
      final key = '$gpId|$targetId';
      if (seen.contains(key)) continue;
      seen.add(key);
      if (!_interventionsOutstanding(g, turn, gpId, targetId)) continue;
      final pass = _processInterventionsForAggressorDefender(
        g,
        aggressorGpId: gpId,
        defenderMinorOrTribeId: targetId,
        turn: turn,
        interventionDecisions: interventionDecisions,
      );
      g = pass.game;
      if (pass.pendingInterventions != null &&
          pass.pendingInterventions!.isNotEmpty) {
        return pass;
      }
    }
  }
  return _InterventionResolutionResult(g);
}

/// GP–GP war pairs from declare-war orders that are at war after step 5.
List<({String aggressor, String defender})> _gpGpWarPairsFromOrders(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
) {
  final seen = <String>{};
  final out = <({String aggressor, String defender})>[];
  for (final e in diploByPlayer.entries) {
    final aggressor = e.key;
    if (!isGreatPower(game, aggressor)) continue;
    for (final o in e.value) {
      if (o.type != DiplomaticOrderType.declareWar) continue;
      final defender = o.targetFactionId;
      if (!isGreatPower(game, defender)) continue;
      if (!factionsAtWar(game, aggressor, defender)) continue;
      final key = '$aggressor|$defender';
      if (seen.add(key)) {
        out.add((aggressor: aggressor, defender: defender));
      }
    }
  }
  return out;
}

Game _cancelSubsidiesBetweenGps(Game game, String id1, String id2, int turn) {
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
    _diploLog.i(
      'diplomacy subsidies cancelled due to war ${s.payerId} vs ${s.targetId}',
    );
    g = _appendDiplomaticEvent(
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
  g = _cancelSubsidiesBetweenGps(g, allyGpId, aggressorGpId, turn);
  g = _appendDiplomaticEvent(
    g,
    turn,
    DiplomaticEventType.callToArmsAccepted,
    {allyGpId, aggressorGpId},
    fromFactionId: allyGpId,
    toFactionId: aggressorGpId,
    wasAiInitiator: isAiControlledForEvidence(g, allyGpId),
  );
  _diploLog.i(
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
  var g = game.copyWith(diplomacyRelations: relations);
  g = _appendDiplomaticEvent(
    g,
    turn,
    DiplomaticEventType.callToArmsRefused,
    {allyGpId, defenderGpId},
    fromFactionId: allyGpId,
    toFactionId: defenderGpId,
    wasAiInitiator: isAiControlledForEvidence(g, allyGpId),
  );
  _diploLog.i(
    'diplomacy call to arms refuse $allyGpId breaks alliance with $defenderGpId',
  );
  return g;
}

_CallToArmsResult _processCallToArms(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  List<CallToArmsDecision>? callToArmsDecisions,
}) {
  var state = game;
  final warPairs = _gpGpWarPairsFromOrders(state, diploByPlayer);
  final pending = <CallToArmsPending>[];

  for (final pair in warPairs) {
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
      } else if (decision.accepted) {
        state = _applyCallToArmsAccept(state, allyGpId, aggressorGpId, turn);
      } else {
        state = _applyCallToArmsRefuse(state, allyGpId, defenderGpId, turn);
      }
    }
  }

  pending.sort((a, b) {
    final c1 = a.allyGpId.compareTo(b.allyGpId);
    if (c1 != 0) return c1;
    final c2 = a.defenderGpId.compareTo(b.defenderGpId);
    if (c2 != 0) return c2;
    return a.aggressorGpId.compareTo(b.aggressorGpId);
  });

  if (pending.isNotEmpty) {
    return _CallToArmsResult(state, pendingCallToArms: pending);
  }
  return _CallToArmsResult(state);
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
    final province = tryGetProvince(worldState, provinceId);
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
}) {
  final turn = game.worldState.turnState.turnNumber;
  if (!isGreatPower(game, aggressorGpId)) return game;

  if (choice == InterventionChoice.doNothing) {
    var g = _clearOverturesBetweenGpAndMinorTribe(
      game,
      interveningGpId,
      defenderMinorOrTribeId,
    );
    g = _appendDiplomaticEvent(
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
  g = _appendDiplomaticEvent(
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
