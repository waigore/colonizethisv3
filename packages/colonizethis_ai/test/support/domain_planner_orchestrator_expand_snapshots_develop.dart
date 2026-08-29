/// DEVELOP-family snapshot builders for orchestrator pins (Refs #3941 / #4602 Slice E).
library;

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_quota_consts.dart';

/// DEVELOP past-quota snapshot with GP-owned NW and no colonial acquisition
/// targets — used by DEVELOP `declareWar` suppression pins (Refs #3997).
///
/// When [tribeRelationScore] is non-null, embeds a tribe relation so the
/// declare-war candidate remains structurally valid while DEVELOP drops it.
AIWorldSnapshot buildOrchestratorDevelopNoColonialTargetsSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String tribeId = kOrchestratorTribeId,
  int oldWorldProvincesOwned = 11,
  int provincesToVictory = 20,
  int newWorldProvincesOwned = 1,
  List<String> atWarWith = const <String>[],
  int? tribeRelationScore,
  RelationState tribeRelationState = RelationState.atWar,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: provincesToVictory,
    ),
    colonial: ColonialSummary(newWorldProvincesOwned: newWorldProvincesOwned),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: tribeRelationScore == null
        ? const <String, DiplomacyRelation>{}
        : <String, DiplomacyRelation>{
            tribeId: DiplomacyRelation(
              factionId1: playerId,
              factionId2: tribeId,
              state: tribeRelationState,
              score: tribeRelationScore,
            ),
          },
  );
}

/// EXPAND below-quota snapshot with an adjacent invadable OW minor.
AIWorldSnapshot buildOrchestratorExpandAdjacentMinorSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String minorId = kOrchestratorAdjacentMinorId,
  String owMinorProvince = kOrchestratorAdjacentMinorOwProvince,
  int oldWorldProvincesOwned = 7,
  int provincesToVictory = 24,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: provincesToVictory,
      invadableProvinceIdsSorted: <String>[owMinorProvince],
      adjacentOwnerFactionIdsSorted: <String>[minorId],
    ),
    colonial: const ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: const <String, DiplomacyRelation>{},
  );
}

/// DEVELOP past-quota snapshot with the same adjacent invadable OW minor.
AIWorldSnapshot buildOrchestratorDevelopAdjacentMinorSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String minorId = kOrchestratorAdjacentMinorId,
  String owMinorProvince = kOrchestratorAdjacentMinorOwProvince,
  int oldWorldProvincesOwned = 12,
  int provincesToVictory = 19,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: provincesToVictory,
      invadableProvinceIdsSorted: <String>[owMinorProvince],
      adjacentOwnerFactionIdsSorted: <String>[minorId],
    ),
    colonial: const ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: const <String, DiplomacyRelation>{},
  );
}
