// Case bodies for DEVELOP-phase NW `purchase_land` orchestrator suppression (Refs #2509 / #4669).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_develop_nw_purchase_suppression_test_support.dart';
import 'domain_planner_orchestrator_develop_nw_purchase_suppression_support.dart';

void registerDomainPlannerOrchestratorDevelopNwPurchaseSuppressionCases() {
  group('runDomainPlanners DEVELOP-phase NW purchase_land suppression', () {
    test(
      'DEVELOP drops NW purchase_land but keeps NW + OW build_improvement',
      () {
        final game = developNwPurchaseSuppressionScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(
          game,
          topology,
          kDevelopNwPurchaseSuppressionOrchestratorNationId,
        );
        const snapshot = AIWorldSnapshot(
          playerId: kDevelopNwPurchaseSuppressionOrchestratorNationId,
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(oldWorldProvincesOwned: 11),
          colonial: ColonialSummary(newWorldProvincesOwned: 1),
          economy: EconomySummary(ownProvinceCount: 2),
          relations: {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.develop,
          reason:
              'Fixture must place GP in DEVELOP so the NW acquisition '
              'suppression contract is exercised, not the COLONIAL fall-through.',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kDevelopNwPurchaseSuppressionOrchestratorNationId,
            view: view,
            snapshot: snapshot,
            config: kDevelopNwPurchaseSuppressionAiConfig,
            primaryGoal: StrategicGoal.diplomacy,
            seeds: AISeedBundle.fromTurnSeed(2509101),
            suggestionAPI: kDevelopNwPurchaseSuppressionMixedRegionWorkApi,
            economyPlan: kDevelopNwPurchaseSuppressionEconomyPlan,
          ),
        );

        final work =
            orders.workOrdersByPlayerId[
                    kDevelopNwPurchaseSuppressionOrchestratorNationId] ??
                const [];
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetPurchaseLand &&
                w.targetTileKey ==
                    kDevelopNwPurchaseSuppressionOrchestratorNwTribeTile,
          ),
          isFalse,
          reason:
              'DEVELOP must drop NW purchase_land candidates (SPEC § Observer '
              'goal phases (Full AI) DEVELOP suppression of NW acquisition).',
        );
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetBuildImprovement &&
                w.targetTileKey ==
                    kDevelopNwPurchaseSuppressionOrchestratorNwOwnedTile,
          ),
          isTrue,
          reason:
              'DEVELOP imperative is improvement-first development across both '
              'regions; NW build_improvement on GP-owned tiles must survive '
              'the filter.',
        );
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetBuildImprovement &&
                w.targetTileKey ==
                    kDevelopNwPurchaseSuppressionOrchestratorOwTile,
          ),
          isTrue,
          reason:
              'OW build_improvement is unaffected by the DEVELOP NW '
              'acquisition filter and must remain in merged work orders.',
        );
      },
    );

    test(
      'COLONIAL keeps NW purchase_land the DEVELOP filter would drop',
      () {
        final game = developNwPurchaseSuppressionScenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(
          game,
          topology,
          kDevelopNwPurchaseSuppressionOrchestratorNationId,
        );
        const snapshot = AIWorldSnapshot(
          playerId: kDevelopNwPurchaseSuppressionOrchestratorNationId,
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(oldWorldProvincesOwned: 11),
          colonial: ColonialSummary(
            newWorldProvincesOwned: 1,
            invadableNewWorldProvinceIdsSorted: [
              kDevelopNwPurchaseSuppressionOrchestratorNwTribeProvince,
            ],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          economy: EconomySummary(ownProvinceCount: 2),
          relations: {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
          reason:
              'Negative-control fixture must place GP in COLONIAL so the '
              'DEVELOP NW purchase_land filter is verified to **not** fire here.',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kDevelopNwPurchaseSuppressionOrchestratorNationId,
            view: view,
            snapshot: snapshot,
            config: kDevelopNwPurchaseSuppressionAiConfig,
            primaryGoal: StrategicGoal.diplomacy,
            seeds: AISeedBundle.fromTurnSeed(2509102),
            suggestionAPI: kDevelopNwPurchaseSuppressionMixedRegionWorkApi,
            economyPlan: kDevelopNwPurchaseSuppressionEconomyPlan,
          ),
        );

        final work =
            orders.workOrdersByPlayerId[
                    kDevelopNwPurchaseSuppressionOrchestratorNationId] ??
                const [];
        expect(
          work.any(
            (w) =>
                w.target == kWorkTargetPurchaseLand &&
                w.targetTileKey ==
                    kDevelopNwPurchaseSuppressionOrchestratorNwTribeTile,
          ),
          isTrue,
          reason:
              'COLONIAL must not apply the DEVELOP NW purchase_land filter; '
              'the merchant purchase_land work order must survive when visible '
              'colonial targets are present.',
        );
      },
    );

    test('DEVELOP filter outcome is deterministic for identical inputs', () {
      final game = developNwPurchaseSuppressionScenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(
        game,
        topology,
        kDevelopNwPurchaseSuppressionOrchestratorNationId,
      );
      const snapshot = AIWorldSnapshot(
        playerId: kDevelopNwPurchaseSuppressionOrchestratorNationId,
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 11),
        colonial: ColonialSummary(newWorldProvincesOwned: 1),
        economy: EconomySummary(ownProvinceCount: 2),
        relations: {},
      );
      final seeds = AISeedBundle.fromTurnSeed(2509103);

      DomainPlannerInput input() => DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kDevelopNwPurchaseSuppressionOrchestratorNationId,
            view: view,
            snapshot: snapshot,
            config: kDevelopNwPurchaseSuppressionAiConfig,
            primaryGoal: StrategicGoal.diplomacy,
            seeds: seeds,
            suggestionAPI: kDevelopNwPurchaseSuppressionMixedRegionWorkApi,
            economyPlan: kDevelopNwPurchaseSuppressionEconomyPlan,
          );

      List<String> describe(Orders orders) =>
          (orders.workOrdersByPlayerId[
                      kDevelopNwPurchaseSuppressionOrchestratorNationId] ??
                  const [])
              .map((w) => '${w.unitId}|${w.target}|${w.targetTileKey}')
              .toList();

      expect(describe(runDomainPlanners(input())), describe(runDomainPlanners(input())));
    });
  });
}
