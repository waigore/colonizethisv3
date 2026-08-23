// Case bodies for `domain_planner_orchestrator_expand_nw_work_suppression_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'domain_planner_orchestrator_expand_nw_work_suppression_support.dart';

void registerDomainPlannerOrchestratorExpandNwWorkSuppressionCases() {
  group('runDomainPlanners EXPAND-phase NW work filter', () {
    test(
      'EXPAND with soft-phase NW weight keeps NW civilian work, keeps OW build_improvement',
      () {
        final game = expandNwWorkSuppressionScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(
          game,
          topology,
          expandNwWorkSuppressionNationId,
        );
        final snapshot = AIWorldSnapshot(
          playerId: expandNwWorkSuppressionNationId,
          threats: const ThreatSummary(),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(oldWorldProvincesOwned: 7),
          colonial: const ColonialSummary(
            invadableNewWorldProvinceIdsSorted: [
              expandNwWorkSuppressionNwTribeProvince,
            ],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: const EconomySummary(ownProvinceCount: 1),
          relations: const {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
          reason:
              'Fixture must place GP in EXPAND so the suppression contract '
              'is exercised, not the COLONIAL fall-through.',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: expandNwWorkSuppressionNationId,
            view: view,
            snapshot: snapshot,
            config: expandNwWorkSuppressionAiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(2509001),
            suggestionAPI: expandNwWorkSuppressionMixedRegionWorkApi,
            economyPlan: expandNwWorkSuppressionEconomyPlan,
          ),
        );

        final work =
            orders.workOrdersByPlayerId[expandNwWorkSuppressionNationId] ??
            const [];
        expect(
          work.any(
            (w) =>
                (w.target == kWorkTargetBuildImprovement &&
                    w.targetTileKey == expandNwWorkSuppressionNwOwnedTile) ||
                (w.target == kWorkTargetPurchaseLand &&
                    w.targetTileKey == expandNwWorkSuppressionNwTribeTile),
          ),
          isTrue,
          reason:
              'EXPAND with default soft-phase NW weight must keep at least one '
              'NW civilian work candidate.',
        );
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetBuildImprovement &&
                w.targetTileKey == expandNwWorkSuppressionOwTile,
          ),
          isTrue,
          reason:
              'OW build_improvement is not a New World colonial order and must '
              'survive the EXPAND filter (control).',
        );
      },
    );

    test(
      'EXPAND with zero NW weight drops NW civilian work (legacy guard)',
      () {
        final game = expandNwWorkSuppressionScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(
          game,
          topology,
          expandNwWorkSuppressionNationId,
        );
        final snapshot = AIWorldSnapshot(
          playerId: expandNwWorkSuppressionNationId,
          threats: const ThreatSummary(),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(oldWorldProvincesOwned: 7),
          colonial: const ColonialSummary(
            invadableNewWorldProvinceIdsSorted: [
              expandNwWorkSuppressionNwTribeProvince,
            ],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: const EconomySummary(ownProvinceCount: 1),
          relations: const {},
        );
        final phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: expandNwWorkSuppressionNwAcquisitionZeroExpand,
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: expandNwWorkSuppressionNationId,
            view: view,
            snapshot: snapshot,
            config: expandNwWorkSuppressionAiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(2509006),
            suggestionAPI: expandNwWorkSuppressionMixedRegionWorkApi,
            economyPlan: expandNwWorkSuppressionEconomyPlan,
            options: OrchestratorOptions(phasePlan: phasePlan),
          ),
        );

        final work =
            orders.workOrdersByPlayerId[expandNwWorkSuppressionNationId] ??
            const [];
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetBuildImprovement &&
                w.targetTileKey == expandNwWorkSuppressionNwOwnedTile,
          ),
          isFalse,
          reason:
              'Zero NW weight must restore legacy NW build_improvement drop.',
        );
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetPurchaseLand &&
                w.targetTileKey == expandNwWorkSuppressionNwTribeTile,
          ),
          isFalse,
          reason: 'Zero NW weight must restore legacy NW purchase_land drop.',
        );
      },
    );

    test(
      'COLONIAL keeps NW civilian work candidates under full colonial imperative',
      () {
        final game = expandNwWorkSuppressionScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(
          game,
          topology,
          expandNwWorkSuppressionNationId,
        );
        final snapshot = AIWorldSnapshot(
          playerId: expandNwWorkSuppressionNationId,
          threats: const ThreatSummary(),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(oldWorldProvincesOwned: 11),
          colonial: const ColonialSummary(
            newWorldProvincesOwned: 1,
            invadableNewWorldProvinceIdsSorted: [
              expandNwWorkSuppressionNwTribeProvince,
            ],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: const EconomySummary(ownProvinceCount: 2),
          relations: const {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
          reason:
              'Negative-control fixture must place GP in COLONIAL so the '
              'EXPAND filter is verified to **not** fire here.',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: expandNwWorkSuppressionNationId,
            view: view,
            snapshot: snapshot,
            config: expandNwWorkSuppressionAiConfig,
            primaryGoal: StrategicGoal.diplomacy,
            seeds: AISeedBundle.fromTurnSeed(2509002),
            suggestionAPI: expandNwWorkSuppressionMixedRegionWorkApi,
            economyPlan: expandNwWorkSuppressionEconomyPlan,
          ),
        );

        final work =
            orders.workOrdersByPlayerId[expandNwWorkSuppressionNationId] ??
            const [];
        // selectFullAiCivilianWorkOrders may pick a single per-unit best
        // target, so we don't assert all three remain; the key contract is
        // that NW build_improvement / NW purchase_land are not unconditionally
        // suppressed (at least one survives the orchestrator's filter pass).
        expect(
          work.any(
            (w) =>
                (w.target == kWorkTargetBuildImprovement &&
                    w.targetTileKey == expandNwWorkSuppressionNwOwnedTile) ||
                (w.target == kWorkTargetPurchaseLand &&
                    w.targetTileKey == expandNwWorkSuppressionNwTribeTile),
          ),
          isTrue,
          reason:
              'COLONIAL must not apply the EXPAND NW work-order filter; at '
              'least one NW civilian work order must survive.',
        );
      },
    );
  });
}
