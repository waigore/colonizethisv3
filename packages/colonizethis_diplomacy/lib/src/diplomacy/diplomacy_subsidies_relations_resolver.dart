import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_resolver.dart';
import 'diplomacy_shared_helpers.dart';
import 'overture_resolver.dart';

String _subsidyPairKey(String payerId, String targetId) =>
    '$payerId\x1F$targetId';

Game terminateAgreementsOnWar(Game game, {IntraTurnEventTally? eventTally}) {
  final turn = game.worldState.turnState.turnNumber;
  final membership = DiplomacyFactionMembership.from(game);
  final clearedForEvents = <OvertureState>[];

  for (final rel in game.diplomacyRelations) {
    if (!rel.atWar) continue;
    final f1 = rel.factionId1;
    final f2 = rel.factionId2;
    final bothGp =
        membership.isGreatPower(f1) && membership.isGreatPower(f2);
    if (bothGp) {
      final result = applyGpGpWarOvertureRules(game, f1, f2);
      game = result.game;
      clearedForEvents.addAll(result.changed);
    } else {
      final result = clearOverturesBetweenGpAndFaction(
        game,
        f1,
        f2,
        bidirectional: true,
      );
      game = result.game;
      clearedForEvents.addAll(result.removed);
    }
  }

  if (clearedForEvents.isNotEmpty) {
    for (final o in clearedForEvents) {
      game = appendDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.agreementsClearedOnWar,
        {o.gpId, o.targetId},
        fromFactionId: o.gpId,
        toFactionId: o.targetId,
        reason: 'war',
        eventTally: eventTally,
      );
    }
    diploLog.i('diplomacy agreements terminated (war)');
  }
  return game;
}

Game applyRelationModifiersAndUpdateScores(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  var players = game.players;
  // Stable id → row index while [players] order/count is unchanged (Refs #2394).
  final playerIndexById = indexByKey(players, (p) => p.id);
  // Pair-key index built once for the phase; grant-aid upserts are amortized
  // O(1) instead of rebuilding the index per order (Refs #3419 step 5).
  final relationsIndex = RelationUpsertIndex(game.diplomacyRelations);

  // GrantAid: deduct treasury, add relation modifier (+5 per grant). Requires Embassy.
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    final player = game.playerById(gpId);
    if (player == null) continue;

    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.grantAid) continue;
      final amount = order.amount ?? 0;
      if (amount > 0 && amount % grantAidAmountStep != 0) {
        throw StateError(
          'GrantAid at resolution must be a positive multiple of '
          '£$grantAidAmountStep (was $amount)',
        );
      }
      if (amount <= 0 || player.treasury < amount) continue;
      if (amount < grantAidAmountStep || amount % grantAidAmountStep != 0) {
        continue;
      }

      final targetId = order.targetFactionId;
      final overture = getOverture(game, gpId, targetId);
      if (overture == null || !overture.hasEmbassy) continue;

      players = debitPlayerTreasury(
        players,
        playerIndexById[gpId] ?? -1,
        amount,
      );

      relationsIndex.upsert(
        gpId,
        targetId,
        grantAidRelationUpdater(gpId, targetId, turn),
      );
      game = game.copyWith(
        players: players,
        diplomacyRelations: relationsIndex.toList(),
      );
      game = logDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.grantAidApplied,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        amount: amount,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
        eventTally: eventTally,
        logMessage: 'diplomacy GrantAid $gpId -> $targetId amount $amount',
      );
    }
  }

  // SetSubsidy: Create or update ongoing subsidy. Requires an Embassy
  // (Refs #3753 R2 — Consulate alone is insufficient for economic actions).
  // Deducts initial payment immediately; ongoing payments processed each turn.
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);
  var subsidyIndexByPair = indexByKey(
    subsidyStates,
    (s) => _subsidyPairKey(s.payerId, s.targetId),
  );
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;

    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.setSubsidy) continue;
      final amount = order.amount ?? 0;
      final player = game.playerById(gpId);
      if (amount > 0 && amount % setSubsidyAmountStep != 0) {
        throw StateError(
          'SetSubsidy at resolution must be a positive multiple of '
          '£$setSubsidyAmountStep (was $amount)',
        );
      }
      if (player == null || amount <= 0 || player.treasury < amount) continue;
      if (amount < setSubsidyAmountStep || amount % setSubsidyAmountStep != 0) {
        continue;
      }

      final targetId = order.targetFactionId;
      final overture = getOverture(game, gpId, targetId);
      if (overture == null || !overture.hasEmbassy) continue;

      // Deduct initial payment
      players = debitPlayerTreasury(
        players,
        playerIndexById[gpId] ?? -1,
        amount,
      );

      // Store/update ongoing subsidy state
      final pairKey = _subsidyPairKey(gpId, targetId);
      final existingSubsidyIdx = subsidyIndexByPair[pairKey] ?? -1;
      final isUpdate = existingSubsidyIdx >= 0;
      if (isUpdate) {
        subsidyStates[existingSubsidyIdx] = subsidyStates[existingSubsidyIdx]
            .copyWith(amountPerTurn: amount);
      } else {
        subsidyStates.add(
          SubsidyState(
            payerId: gpId,
            targetId: targetId,
            amountPerTurn: amount,
          ),
        );
        subsidyIndexByPair[pairKey] = subsidyStates.length - 1;
      }

      game = game.copyWith(players: players, subsidyStates: subsidyStates);
      final subsidyTargetIsPlayer = game.playerById(targetId) != null;
      final subsidyLogSuffix = subsidyTargetIsPlayer
          ? '(ongoing)'
          : '(ongoing relation boost)';
      game = logDiplomaticEvent(
        game,
        turn,
        isUpdate
            ? DiplomaticEventType.subsidyUpdated
            : DiplomaticEventType.subsidySet,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        amount: amount,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
        eventTally: eventTally,
        logMessage:
            'diplomacy SetSubsidy $gpId -> $targetId amount $amount/turn $subsidyLogSuffix',
      );
    }
  }

  return game;
}

/// Process ongoing subsidies each turn.
/// Deducts amount from payer treasury and improves relation by +2 per 500 ducats (max +8).
/// Per SPEC/game/diplomacy.md.
Game processOngoingSubsidies(
  Game game,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  IntraTurnEventTally? eventTally,
}) {
  var players = game.players;
  final playerIndexById = indexByKey(players, (p) => p.id);
  // Single index built once for the whole phase; each boost is amortized O(1)
  // and the list is copied only at the end (Refs #3419 step 5).
  final relationsIndex = RelationUpsertIndex(game.diplomacyRelations);
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);

  for (final subsidy in subsidyStates) {
    final payerId = subsidy.payerId;
    final targetId = subsidy.targetId;
    final amount = subsidy.amountPerTurn;

    // Check if payer can afford subsidy
    final payer = game.playerById(payerId);
    if (payer == null || payer.treasury < amount) {
      game = logDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.subsidyCancelled,
        {payerId, targetId},
        fromFactionId: payerId,
        toFactionId: targetId,
        reason: 'insufficient funds',
        wasAiInitiator: isAiControlledForEvidence(game, payerId),
        eventTally: eventTally,
        logMessage:
            'diplomacy subsidy cancelled $payerId -> $targetId (insufficient funds)',
      );
      subsidyStates = subsidyStates
          .where((s) => s.payerId != payerId || s.targetId != targetId)
          .toList();
      continue;
    }

    // Check if still at peace (subsidies cancel on war)
    final rel = getRelation(game, payerId, targetId);
    if (rel != null && rel.atWar) {
      game = logDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.subsidyCancelled,
        {payerId, targetId},
        fromFactionId: payerId,
        toFactionId: targetId,
        reason: 'war declared',
        wasAiInitiator: isAiControlledForEvidence(game, payerId),
        eventTally: eventTally,
        logMessage:
            'diplomacy subsidy cancelled $payerId -> $targetId (war declared)',
      );
      subsidyStates = subsidyStates
          .where((s) => s.payerId != payerId || s.targetId != targetId)
          .toList();
      continue;
    }

    // Deduct subsidy payment
    players = debitPlayerTreasury(
      players,
      playerIndexById[payerId] ?? -1,
      amount,
    );

    // Calculate relation boost: +subsidyBoostRelationPerStep per subsidyBoostDucatsPerStep ducats, max subsidyBoostMax
    final boost =
        ((amount ~/ subsidyBoostDucatsPerStep) * subsidyBoostRelationPerStep)
            .clamp(0, subsidyBoostMax);

    // Apply relation boost (only for Minors/Tribes - GPs get treasury transfer)
    if (factionMembership.isMinorOrTribe(targetId)) {
      relationsIndex.upsert(
        payerId,
        targetId,
        subsidyBoostRelationUpdater(payerId, targetId, boost, turn),
      );
      diploLog.i(
        'diplomacy subsidy processed $payerId -> $targetId amount=$amount boost=+$boost',
      );
    } else {
      // GP target: transfer treasury
      final targetIdx = playerIndexById[targetId] ?? -1;
      if (targetIdx >= 0) {
        players[targetIdx] = players[targetIdx].copyWith(
          treasury: players[targetIdx].treasury + amount,
        );
      }
      diploLog.i(
        'diplomacy subsidy processed $payerId -> $targetId amount=$amount (treasury transfer)',
      );
    }
  }

  return game.copyWith(
    players: players,
    diplomacyRelations: relationsIndex.toList(),
    subsidyStates: subsidyStates,
  );
}

/// Snapshot each relation pair's score at the start of the Diplomacy phase,
/// keyed by [pairKey]. Used by [applyRelationDecay] to detect which pairs were
/// modified by an event this turn (skip-on-event). SPEC/game/diplomacy.md.
Map<String, num> snapshotRelationScores(Game game) => {
  for (final r in game.diplomacyRelations)
    pairKey(r.factionId1, r.factionId2): r.score,
};

/// Apply per-turn relation decay (Refs #3753 R9.3/R9.4): every non-war pair that
/// received **no** relation-score delta event this turn drifts
/// [relationDecayPerTurn] toward equilibrium [relationScoreNeutral] (50),
/// clamped so it never crosses 50 in a single turn. Pairs whose score differs
/// from [phaseStartScores] (any event delta this turn) and pairs created this
/// turn (absent from [phaseStartScores]) are **skipped** — event deltas only, no
/// double-application. `AT_WAR` pairs keep their score frozen at the
/// war-declaration value. SPEC/game/diplomacy.md § Relation Model.
Game applyRelationDecay(
  Game game,
  int turn,
  Map<String, num> phaseStartScores,
) {
  final relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
  var changed = false;

  for (var i = 0; i < relations.length; i++) {
    final rel = relations[i];
    // War relations don't decay; scores stay fixed at war declaration.
    if (rel.atWar) continue;
    if (rel.score == relationScoreNeutral) continue; // already at equilibrium

    // Skip-on-event: a pair modified this turn (or created this turn) does not
    // also decay the same turn.
    final startScore = phaseStartScores[pairKey(rel.factionId1, rel.factionId2)];
    if (startScore == null || startScore != rel.score) continue;

    final num newScore = rel.score < relationScoreNeutral
        ? (rel.score + relationDecayPerTurn)
              .clamp(relationScoreMin, relationScoreNeutral)
        : (rel.score - relationDecayPerTurn)
              .clamp(relationScoreNeutral, relationScoreMax);

    if (newScore == rel.score) continue;
    relations[i] = rel.copyWith(score: newScore, level: scoreToLevel(newScore));
    changed = true;
  }

  if (!changed) return game;
  return game.copyWith(diplomacyRelations: relations);
}

/// Apply the additive trade-deal relation boost (Refs #3753 R10). For every
/// canonical pair key recorded on [Game.worldMarketState.completedTradePairKeys]
/// (set by the previous turn's World Market phase for pairs that completed at
/// least one trade deal involving a Great Power), the pair relation gains
/// [tradeDealRelationBoostBase] plus [tradeDealRelationBoostEmbassyBonus] when an
/// Embassy is in effect between the parties. The boost is **volume-independent**
/// and applied **once per pair per turn**, clamped to
/// `[relationScoreMin, relationScoreMax]`. `AT_WAR` pairs are skipped (war scores
/// are frozen). Applied in the Diplomacy phase **after** the relation snapshot
/// and **before** per-turn decay so boosted pairs are treated as event-modified
/// and skip decay this turn (skip-on-event). The subsidy-percentage modifier
/// (R10) is added when percentage subsidies (R3) land; current behaviour applies
/// the base and embassy terms only. SPEC/game/diplomacy.md § Relation Model.
Game applyTradeDealRelationBoosts(Game game, int turn) {
  final pairKeys = game.worldMarketState.completedTradePairKeys;
  if (pairKeys.isEmpty) return game;

  final relationsIndex = RelationUpsertIndex(game.diplomacyRelations);
  var changed = false;

  for (final key in pairKeys) {
    final parts = key.split('|');
    if (parts.length != 2) continue;
    final id1 = parts[0];
    final id2 = parts[1];
    if (id1.isEmpty || id2.isEmpty || id1 == id2) continue;

    // War scores are frozen and never receive the trade boost.
    if (getRelation(game, id1, id2)?.atWar == true) continue;

    final hasEmbassy =
        hasEmbassyOverture(game, id1, id2) ||
        hasEmbassyOverture(game, id2, id1);
    final boost = tradeDealRelationBoostBase +
        (hasEmbassy ? tradeDealRelationBoostEmbassyBonus : 0.0);

    relationsIndex.upsert(id1, id2, _tradeDealBoostUpdater(id1, id2, boost, turn));
    changed = true;
  }

  if (!changed) return game;
  return game.copyWith(diplomacyRelations: relationsIndex.toList());
}

DiplomacyRelation Function(DiplomacyRelation?) _tradeDealBoostUpdater(
  String id1,
  String id2,
  double boost,
  int turn,
) => (existing) {
  final num base = existing?.score ?? relationScoreNeutral;
  final num newScore = (base + boost).clamp(
    relationScoreMin,
    relationScoreMax,
  );
  final newLevel = scoreToLevel(newScore);
  if (existing == null) {
    return DiplomacyRelation(
      factionId1: id1,
      factionId2: id2,
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
};

/// Commodity slots for trade agreements: 0 without embassy; baseline **3** with
/// embassy; **6** when [kTechIdTradeFairs] is unlocked. SPEC/program/diplomacy-resolution.md.
int tradeSlotsForGp(Game game, String gpId, String targetFactionId) {
  final o = getOverture(game, gpId, targetFactionId);
  if (o == null || !o.hasEmbassy) {
    return 0;
  }
  final p = game.playerById(gpId);
  if (p == null) {
    return 0;
  }
  final u = p.techUnlocked ?? const <String, bool>{};
  return u[kTechIdTradeFairs] == true ? 6 : 3;
}
