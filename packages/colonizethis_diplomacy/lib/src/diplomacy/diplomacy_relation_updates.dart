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
  return upsertRelation(
    relations,
    gpId,
    targetId,
    (existing) {
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
      return existing.copyWith(
        state: RelationState.atWar,
        sinceTurn: turn,
        lastInteractionTurn: turn,
        score: 20,
        level: RelationLevel.hostile,
      );
    },
  );
}

List<DiplomacyRelation> applyPeaceForPair({
  required List<DiplomacyRelation> relations,
  required String gpId,
  required String targetId,
  required int turn,
}) {
  return upsertRelation(
    relations,
    gpId,
    targetId,
    (existing) {
      return existing!.copyWith(
        state: RelationState.atPeace,
        sinceTurn: turn,
        lastInteractionTurn: turn,
      );
    },
  );
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

