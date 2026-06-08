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

List<DiplomacyRelation> applyGrantAidModifier({
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
      final newScore = ((existing?.score ?? relationScoreNeutral) + 5).clamp(relationScoreMin, relationScoreMax);
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
    },
  );
}

List<DiplomacyRelation> applySubsidyBoost({
  required List<DiplomacyRelation> relations,
  required String payerId,
  required String targetId,
  required int boost,
  required int turn,
}) {
  final ids = canonicalPairIds(payerId, targetId);
  return upsertRelation(
    relations,
    payerId,
    targetId,
    (existing) {
      final newScore = ((existing?.score ?? relationScoreNeutral) + boost).clamp(relationScoreMin, relationScoreMax);
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
    },
  );
}

