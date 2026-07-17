import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_event_logging.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_shared_helpers.dart';
import 'diplomacy_subsidies_resolver.dart';

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
        diplomacyRelations: committedRelations(relationsIndex),
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

  // SetSubsidy order processing lives in the subsidies module (Refs #4037).
  return applySetSubsidyOrders(
    game,
    diploByPlayer,
    turn,
    eventTally: eventTally,
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
/// and skip decay this turn (skip-on-event). When a percentage subsidy is in
/// effect between the parties, `+0.2` per subsidy percentage point is added
/// (Refs #3753 R10). SPEC/game/diplomacy.md § Relation Model.
Game applyTradeDealRelationBoosts(Game game, int turn) {
  final pairKeys = game.worldMarketState.completedTradePairKeys;
  if (pairKeys.isEmpty) return game;

  var changed = false;
  final next = withRelationUpserts(game, (relationsIndex) {
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
      // Subsidy modifier (Refs #3753 R10): +0.2 per subsidy percentage point in
      // effect between the parties (subsidies are GP→Minor/Tribe, counted once).
      final subsidyPercent = subsidyPercentBetween(game, id1, id2);
      final boost = tradeDealRelationBoostBase +
          (hasEmbassy ? tradeDealRelationBoostEmbassyBonus : 0.0) +
          (tradeDealRelationBoostPerSubsidyPercent * subsidyPercent);

      relationsIndex.upsert(
        id1,
        id2,
        _tradeDealBoostUpdater(id1, id2, boost, turn),
      );
      changed = true;
    }
  });

  return changed ? next : game;
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
