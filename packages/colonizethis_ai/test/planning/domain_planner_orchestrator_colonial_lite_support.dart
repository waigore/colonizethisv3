// Shared fixtures for COLONIAL-lite orchestrator pins (Refs #4602).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String colonialLiteOrchestratorNationId = kOrchestratorGp1NationId;
const String colonialLiteOrchestratorTribeId = kOrchestratorTribeId;

/// Fake API surfaces the three phase-distinguishing candidates:
///   - NW `build_improvement` on the GP-owned NW grain tile;
///   - NW `purchase_land` on the tribe NW grain tile;
///   - `establishOverture(tribe1, joinEmpire)` (Join Empire candidate).
///
/// `suggestDeclareWarOrders` filters by `type == declareWar`, so this fixture
/// only feeds the non-declareWar diplomacy pass — i.e. exactly the pass the
/// COLONIAL-lite vs EXPAND overture contract gates.
const FakeOrderSuggestionAPIForDomainPlannerTests
colonialLiteOrchestratorPhasePhasingApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
      work: [
        WorkOrder(
          unitId: 'b_nw',
          target: kWorkTargetBuildImprovement,
          targetTileKey: kOrchestratorColonialLiteNwGpTile,
        ),
        WorkOrder(
          unitId: 'm_nw',
          target: kWorkTargetPurchaseLand,
          targetTileKey: kOrchestratorColonialLiteNwTribeTile,
        ),
      ],
      build: [],
      move: [],
      research: [],
      navalMove: [],
      navalMission: [],
      diplomatic: [
        DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: colonialLiteOrchestratorTribeId,
          overtureStage: OvertureStage.joinEmpire,
        ),
      ],
    );

const EconomyPlan colonialLiteOrchestratorEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

// `henry` + `merchant` matches the personality/agenda used by the EXPAND NW
// overture suppression sibling pin
// (`domain_planner_orchestrator_expand_nw_overture_suppression_test.dart`)
// and the COLONIAL personality scoring test in
// `observer_goal_phase_test.dart`. `peacemaker` is intentionally avoided —
// that agenda zeroes declareWar candidates and can confound a regression
// that would otherwise show in the diplomatic-order suppression contract.
const AIConfig colonialLiteOrchestratorAiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot colonialLiteOrchestratorNearQuotaSnapshot() {
  return const AIWorldSnapshot(
    playerId: colonialLiteOrchestratorNationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 9 OW provinces -> below quota; phase is decided by turn number
    // (>= 120 enters COLONIAL-lite; otherwise EXPAND).
    conquest: ConquestSummary(
      oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
      provincesToVictory: 22,
    ),
    // Tribe is both a visible NW invadable owner and a preferred colonial
    // target. The same fixture exercises the EXPAND overture suppression
    // (`shouldSuppressNewWorldColonialOrders` branch) when reused at turn
    // 90 in the negative control.
    colonial: ColonialSummary(
      newWorldProvincesOwned: 1,
      invadableNewWorldProvinceIdsSorted: [
        kOrchestratorColonialLiteNwTribeProvince,
      ],
      adjacentNewWorldOwnerFactionIdsSorted: [colonialLiteOrchestratorTribeId],
      preferredColonialTargetFactionIdsSorted: [
        colonialLiteOrchestratorTribeId,
      ],
    ),
    economy: EconomySummary(ownProvinceCount: 9),
    relations: {
      colonialLiteOrchestratorTribeId: DiplomacyRelation(
        factionId1: colonialLiteOrchestratorNationId,
        factionId2: colonialLiteOrchestratorTribeId,
        state: RelationState.atPeace,
        score: 60,
      ),
    },
  );
}

List<String> colonialLiteOrchestratorOvertureTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[colonialLiteOrchestratorNationId] ??
          const [])
    if (order.type == DiplomaticOrderType.establishOverture)
      order.targetFactionId,
];

List<WorkOrder> colonialLiteOrchestratorWorkOrders(Orders orders) =>
    orders.workOrdersByPlayerId[colonialLiteOrchestratorNationId] ?? const [];
