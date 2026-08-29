/// EXPAND-family snapshot builders for orchestrator pins (Refs #3941 / #4291).
library;

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_quota_consts.dart';

/// Shared EXPAND snapshot: gp1 below OW quota, at war with the OW minor
/// frontier used by [buildOrchestratorExpandMinorWarScenarioGame].
///
/// Used by domain-gates / phase-plan / trade-wiring / pending-cost pins
/// (Refs #3997 fixture consolidation).
AIWorldSnapshot buildOrchestratorExpandMinorWarAtWarSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String minorId = kOrchestratorMinorId,
  String owMinorProvince = kOrchestratorOwMinorProvince,
  int oldWorldProvincesOwned = 7,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: [minorId]),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: [owMinorProvince],
      adjacentOwnerFactionIdsSorted: [minorId],
    ),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: {
      minorId: DiplomacyRelation(
        factionId1: playerId,
        factionId2: minorId,
        state: RelationState.atWar,
        score: -100,
      ),
    },
  );
}

/// EXPAND below-quota snapshot with visible NW tribe acquisition targets.
///
/// Shared by NW `declareWar` / `establishOverture` suppression and COLONIAL
/// tribe declare-war EXPAND negative controls (Refs #3997).
///
/// When [tribePeaceRelationScore] is non-null, embeds an at-peace tribe
/// relation at that score; otherwise [relations] is empty.
AIWorldSnapshot buildOrchestratorExpandNwTribeTargetSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String tribeId = kOrchestratorTribeId,
  String tribeNwProvince = kOrchestratorTribeNwProvince,
  int oldWorldProvincesOwned = 7,
  int provincesToVictory = 24,
  int? tribePeaceRelationScore,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: provincesToVictory,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [tribeId],
      preferredColonialTargetFactionIdsSorted: [tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: tribePeaceRelationScore == null
        ? const <String, DiplomacyRelation>{}
        : <String, DiplomacyRelation>{
            tribeId: DiplomacyRelation(
              factionId1: playerId,
              factionId2: tribeId,
              state: RelationState.atPeace,
              score: tribePeaceRelationScore,
            ),
          },
  );
}

/// COLONIAL at-/past-quota snapshot with visible NW tribe acquisition targets.
///
/// Shared by NW suppression COLONIAL controls, COLONIAL tribe declare-war
/// positive pins, and diplomatic-scoring COLONIAL tribe pins (Refs #3997).
///
/// When [adjacentNewWorldOwnerFactionIdsSorted] is omitted, defaults to
/// `[tribeId]` (orchestrator adjacency geometry). Pass an empty list for
/// scoring pins that historically omitted adjacent NW owners.
AIWorldSnapshot buildOrchestratorColonialNwTribeTargetSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String tribeId = kOrchestratorTribeId,
  String tribeNwProvince = kOrchestratorTribeNwProvince,
  int oldWorldProvincesOwned = 11,
  int provincesToVictory = 20,
  int newWorldProvincesOwned = 0,
  List<String> atWarWith = const <String>[],
  List<String>? adjacentNewWorldOwnerFactionIdsSorted,
  int? tribeRelationScore,
  RelationState tribeRelationState = RelationState.atPeace,
}) {
  final adjacentOwners =
      adjacentNewWorldOwnerFactionIdsSorted ?? <String>[tribeId];
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: provincesToVictory,
    ),
    colonial: ColonialSummary(
      newWorldProvincesOwned: newWorldProvincesOwned,
      invadableNewWorldProvinceIdsSorted: [tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: adjacentOwners,
      preferredColonialTargetFactionIdsSorted: [tribeId],
    ),
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

/// EXPAND below-quota snapshot with a GP-only invadable OW frontier.
AIWorldSnapshot buildOrchestratorExpandGpOnlyBlockerSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String blockerGpId = kOrchestratorBlockerGpId,
  List<String> invadableProvinceIdsSorted = kOrchestratorBlockerOwProvinces,
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
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
      adjacentOwnerFactionIdsSorted: <String>[blockerGpId],
    ),
    colonial: const ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: const <String, DiplomacyRelation>{},
  );
}

/// DEVELOP past-quota snapshot with the same GP-only invadable frontier.
AIWorldSnapshot buildOrchestratorDevelopGpOnlyBlockerSnapshot({
  String playerId = kOrchestratorGp1NationId,
  String blockerGpId = kOrchestratorBlockerGpId,
  List<String> invadableProvinceIdsSorted = kOrchestratorBlockerOwProvinces,
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
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
      adjacentOwnerFactionIdsSorted: <String>[blockerGpId],
    ),
    colonial: const ColonialSummary(),
    economy: EconomySummary(ownProvinceCount: oldWorldProvincesOwned),
    relations: const <String, DiplomacyRelation>{},
  );
}

export 'domain_planner_orchestrator_expand_snapshots_develop.dart';
