import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_relation_lookup.dart';

/// Canonical faction pair IDs for a pair key.
({String id1, String id2}) canonicalPairIds(String a, String b) {
  final key = pairKey(a, b);
  final parts = key.split('|');
  return (id1: parts[0], id2: parts[1]);
}

List<DiplomacyRelation> setWarStateForPair({
  required List<DiplomacyRelation> relations,
  required String gpId,
  required String targetId,
  required int turn,
}) {
  final ids = canonicalPairIds(gpId, targetId);
  return upsertRelation(relations, gpId, targetId, (existing) {
    if (existing == null) {
      return DiplomacyRelation(
        factionId1: ids.id1,
        factionId2: ids.id2,
        score: 20,
        level: RelationLevel.hostile,
        state: RelationState.atWar,
        sinceTurn: turn,
        lastInteractionTurn: turn,
      );
    }
    // War invariant (SPEC/game/diplomacy.md § Alliances): entering war clears
    // any formal alliance for the pair — a treaty can never coexist with war.
    return existing.copyWith(
      state: RelationState.atWar,
      sinceTurn: turn,
      lastInteractionTurn: turn,
      score: 20,
      level: RelationLevel.hostile,
      formalAlliance: false,
    );
  });
}

List<DiplomacyRelation> applyPeaceForPair({
  required List<DiplomacyRelation> relations,
  required String gpId,
  required String targetId,
  required int turn,
}) {
  return upsertRelation(relations, gpId, targetId, (existing) {
    return existing!.copyWith(
      state: RelationState.atPeace,
      sinceTurn: turn,
      lastInteractionTurn: turn,
    );
  });
}

/// Updater applying a fixed Grant Aid relation modifier (+5, clamped). Shared by
/// [applyGrantAidModifier] and the batched [RelationUpsertIndex] path so the
/// relation-construction logic lives in one place (Refs #3419 step 5).
DiplomacyRelation Function(DiplomacyRelation?) grantAidRelationUpdater(
  String gpId,
  String targetId,
  int turn,
) => _scoreDeltaUpdater(gpId, targetId, 5, turn);

/// Updater applying a [boost] to the relation score (clamped). Shared by
/// [applySubsidyBoost] and the batched [RelationUpsertIndex] path.
DiplomacyRelation Function(DiplomacyRelation?) subsidyBoostRelationUpdater(
  String payerId,
  String targetId,
  int boost,
  int turn,
) => _scoreDeltaUpdater(payerId, targetId, boost, turn);

DiplomacyRelation Function(DiplomacyRelation?) _scoreDeltaUpdater(
  String factionA,
  String factionB,
  int delta,
  int turn,
) {
  final ids = canonicalPairIds(factionA, factionB);
  return (existing) {
    final newScore = ((existing?.score ?? relationScoreNeutral) + delta).clamp(
      relationScoreMin,
      relationScoreMax,
    );
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
  };
}

List<DiplomacyRelation> applyGrantAidModifier({
  required List<DiplomacyRelation> relations,
  required String gpId,
  required String targetId,
  required int turn,
}) {
  return upsertRelation(
    relations,
    gpId,
    targetId,
    grantAidRelationUpdater(gpId, targetId, turn),
  );
}

List<DiplomacyRelation> applySubsidyBoost({
  required List<DiplomacyRelation> relations,
  required String payerId,
  required String targetId,
  required int boost,
  required int turn,
}) {
  return upsertRelation(
    relations,
    payerId,
    targetId,
    subsidyBoostRelationUpdater(payerId, targetId, boost, turn),
  );
}

/// Every Great Power (other than [breakerId] itself and any id in [exclude])
/// for which [breakerId] holds a [DiplomacyRelation], sorted ascending for
/// deterministic application order. Used by the unified alliance-break penalty
/// (R11) to find the "every other GP" cascade targets. SPEC/game/diplomacy.md.
List<String> otherRelatedGreatPowerIds(
  Game game,
  String breakerId,
  Set<String> exclude,
) {
  final gpIds = {for (final p in game.players) p.id};
  final out = <String>{};
  for (final r in game.diplomacyRelations) {
    if (!r.involvesNation(breakerId)) continue;
    final other = r.factionId1 == breakerId ? r.factionId2 : r.factionId1;
    if (other == breakerId) continue;
    if (exclude.contains(other)) continue;
    if (!gpIds.contains(other)) continue;
    out.add(other);
  }
  final sorted = out.toList()..sort();
  return sorted;
}

/// Applies the unified alliance-break relation penalty (R11): subtracts
/// [allianceBreakAllyScorePenalty] from the [breakerId]↔[brokenWithAllyId] pair
/// and clears that pair's `formalAlliance`, then subtracts
/// [allianceBreakOtherGpScorePenalty] from [breakerId]↔every id in [otherGpIds]
/// (which the caller has already filtered/sorted, excluding the broken-with ally
/// and any non-cascade ids). Scores clamp to
/// `[relationScoreMin, relationScoreMax]`; levels are recomputed.
/// SPEC/game/diplomacy.md § Alliances.
List<DiplomacyRelation> applyAllianceBreakPenalties({
  required List<DiplomacyRelation> relations,
  required String breakerId,
  required String brokenWithAllyId,
  required List<String> otherGpIds,
  required int turn,
}) {
  final index = RelationUpsertIndex(relations);
  index.upsert(
    breakerId,
    brokenWithAllyId,
    _allianceBreakAllyUpdater(breakerId, brokenWithAllyId, turn),
  );
  for (final other in otherGpIds) {
    index.upsert(
      breakerId,
      other,
      _scoreDeltaUpdater(
        breakerId,
        other,
        -allianceBreakOtherGpScorePenalty,
        turn,
      ),
    );
  }
  return index.toList();
}

DiplomacyRelation Function(DiplomacyRelation?) _allianceBreakAllyUpdater(
  String breakerId,
  String brokenWithAllyId,
  int turn,
) {
  final ids = canonicalPairIds(breakerId, brokenWithAllyId);
  return (existing) {
    final base = existing?.score ?? relationScoreNeutral;
    final newScore = (base - allianceBreakAllyScorePenalty).clamp(
      relationScoreMin,
      relationScoreMax,
    );
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
      formalAlliance: false,
    );
  };
}

/// Applies the spy-caught diplomacy penalty between [spyOwnerId] and
/// [territoryOwnerId]. SPEC/game/diplomacy.md; Refs #3834 R8.
({List<DiplomacyRelation> relations, int penaltiesApplied})
applySpyDeathDiplomacyPenalty({
  required List<DiplomacyRelation> relations,
  required String spyOwnerId,
  required String territoryOwnerId,
  required int turn,
  int penalty = -8,
}) {
  if (spyOwnerId == territoryOwnerId) {
    return (relations: relations, penaltiesApplied: 0);
  }
  final next = upsertRelation(
    relations,
    spyOwnerId,
    territoryOwnerId,
    _scoreDeltaUpdater(spyOwnerId, territoryOwnerId, penalty, turn),
  );
  return (relations: next, penaltiesApplied: 1);
}
