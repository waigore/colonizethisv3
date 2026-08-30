// Shared fixtures for COLONIAL-lite NW invasion army-move orchestrator pins
// (Refs #2509 S10, #4602).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import '../support/domain_planner_test_fake_api.dart';

const String kColonialLiteInvasionArmyMoveNationId = kOrchestratorGp1NationId;
const String kColonialLiteInvasionArmyMoveTribeId = kOrchestratorTribeId;
const String kColonialLiteInvasionArmyMoveMinorId = kOrchestratorMinorId;
const String kColonialLiteInvasionArmyMoveOwMinorProvince =
    kOrchestratorColonialLiteInvasionOwMinorProvince;
const String kColonialLiteInvasionArmyMoveNwTribeProvince =
    kOrchestratorTribeNwProvince;
const String kColonialLiteInvasionArmyMoveFieldArmyId =
    kOrchestratorColonialLiteInvasionFieldArmyId;

/// Fake suggestion API surfacing the two phase-distinguishing army-move
/// candidates: one OW invadable minor (must survive in COLONIAL-lite) and one
/// NW tribe invadable (must be dropped in COLONIAL-lite, kept in COLONIAL).
const FakeOrderSuggestionAPIForDomainPlannerTests
    kColonialLiteInvasionMixedOwNwArmyMoveApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
  armyMove: [
    ArmyMoveOrder(
      armyId: kColonialLiteInvasionArmyMoveFieldArmyId,
      destinationProvinceId: kColonialLiteInvasionArmyMoveNwTribeProvince,
    ),
    ArmyMoveOrder(
      armyId: kColonialLiteInvasionArmyMoveFieldArmyId,
      destinationProvinceId: kColonialLiteInvasionArmyMoveOwMinorProvince,
    ),
  ],
);

const EconomyPlan kColonialLiteInvasionArmyMoveEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig kColonialLiteInvasionArmyMoveAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot colonialLiteInvasionArmyMoveSnapshotFor({
  required int oldWorldProvincesOwned,
}) {
  return AIWorldSnapshot(
    playerId: kColonialLiteInvasionArmyMoveNationId,
    threats: ThreatSummary(
      atWarWith: [
        kColonialLiteInvasionArmyMoveMinorId,
        kColonialLiteInvasionArmyMoveTribeId,
      ],
    ),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: const [kColonialLiteInvasionArmyMoveOwMinorProvince],
    ),
    colonial: const ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [kColonialLiteInvasionArmyMoveNwTribeProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [kColonialLiteInvasionArmyMoveTribeId],
      preferredColonialTargetFactionIdsSorted: [kColonialLiteInvasionArmyMoveTribeId],
    ),
    economy: const EconomySummary(ownProvinceCount: 9),
    relations: {
      kColonialLiteInvasionArmyMoveTribeId: DiplomacyRelation(
        factionId1: kColonialLiteInvasionArmyMoveNationId,
        factionId2: kColonialLiteInvasionArmyMoveTribeId,
        state: RelationState.atWar,
        score: -20,
      ),
      kColonialLiteInvasionArmyMoveMinorId: DiplomacyRelation(
        factionId1: kColonialLiteInvasionArmyMoveNationId,
        factionId2: kColonialLiteInvasionArmyMoveMinorId,
        state: RelationState.atWar,
        score: -20,
      ),
    },
  );
}

List<ArmyMoveOrder> colonialLiteInvasionArmyMoves(Orders orders) =>
    orders.armyMoveOrdersByPlayerId[kColonialLiteInvasionArmyMoveNationId] ??
    const [];
