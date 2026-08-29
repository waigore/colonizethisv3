// Shared fixtures for COLONIAL-lite naval ALLOW orchestrator pins (Refs #2509).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import '../support/domain_planner_test_fake_api.dart';

const String kColonialLiteNavalAllowNationId = kOrchestratorGp1NationId;
const String kColonialLiteNavalAllowTribeId = kOrchestratorTribeId;
const String kColonialLiteNavalAllowNwTribeProvince = kOrchestratorTribeNwProvince;
const String kColonialLiteNavalAllowFleetId = 'f_nw';
const String kColonialLiteNavalAllowNwSeaZoneId = 'newWorld|sea_priority';

const FakeOrderSuggestionAPIForDomainPlannerTests
    kColonialLiteNavalAllowCandidateApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [
    NavalMoveOrder(
      fleetId: kColonialLiteNavalAllowFleetId,
      destinationSeaZoneId: kColonialLiteNavalAllowNwSeaZoneId,
    ),
  ],
  navalMission: [],
);

const EconomyPlan kColonialLiteNavalAllowEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig kColonialLiteNavalAllowAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot colonialLiteNavalAllowNearQuotaSnapshot() {
  return const AIWorldSnapshot(
    playerId: kColonialLiteNavalAllowNationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
      provincesToVictory: 22,
    ),
    colonial: ColonialSummary(
      newWorldProvincesOwned: 0,
      invadableNewWorldProvinceIdsSorted: [kColonialLiteNavalAllowNwTribeProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [kColonialLiteNavalAllowTribeId],
      preferredColonialTargetFactionIdsSorted: [kColonialLiteNavalAllowTribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 9),
    relations: {},
  );
}

List<NavalMoveOrder> colonialLiteNavalAllowNavalMoves(Orders orders) =>
    orders.navalMoveOrdersByPlayerId[kColonialLiteNavalAllowNationId] ??
    const [];
