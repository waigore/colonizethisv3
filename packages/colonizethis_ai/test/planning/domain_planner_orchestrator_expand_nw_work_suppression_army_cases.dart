// Army-move / determinism cases for expand NW work suppression (Refs #4602).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_expand_nw_work_suppression_support.dart';

void registerDomainPlannerOrchestratorExpandNwWorkSuppressionArmyCases() {
  group('runDomainPlanners EXPAND-phase NW army-move filter', () {
    test(
      'EXPAND conquest army move prefers OW invadable minor over NW tribe',
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
          threats: const ThreatSummary(atWarWith: ['tribe1', 'minor1']),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 7,
            invadableProvinceIdsSorted: [
              expandNwWorkSuppressionOwMinorProvince,
            ],
          ),
          colonial: const ColonialSummary(
            invadableNewWorldProvinceIdsSorted: [
              expandNwWorkSuppressionNwTribeProvince,
            ],
            adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
          ),
          // Non-zero treasury keeps this fixture out of the NW
          // treasury-recovery override (isNwTreasuryRecoveryOverrideActive
          // requires treasury == 0); this pins the *default* EXPAND
          // OW-preference, not the lock-recovery NW prioritisation path
          // (Refs #2924 Path E), which is covered separately in
          // test/planning/phase_planner_conquest_wiring_test.dart.
          economy: const EconomySummary(ownProvinceCount: 1, treasury: 500),
          relations: const {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
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
            seeds: AISeedBundle.fromTurnSeed(2509004),
            suggestionAPI: expandNwWorkSuppressionMixedOwNwArmyMoveApi,
            economyPlan: expandNwWorkSuppressionEconomyPlan,
          ),
        );

        final armyMoves =
            orders.armyMoveOrdersByPlayerId[expandNwWorkSuppressionNationId] ??
            const [];
        expect(armyMoves, isNotEmpty);
        expect(
          armyMoves.any(
            (m) =>
                m.destinationProvinceId ==
                expandNwWorkSuppressionNwTribeProvince,
          ),
          isFalse,
          reason:
              'When OW and NW army-move candidates are both suggested, EXPAND '
              'must score NW invasion to zero and prefer the OW invadable path.',
        );
        expect(
          armyMoves.any(
            (m) =>
                m.destinationProvinceId ==
                expandNwWorkSuppressionOwMinorProvince,
          ),
          isTrue,
          reason: 'OW invadable minor must remain the chosen conquest move.',
        );
      },
    );

    test(
      'COLONIAL keeps NW army move the EXPAND conquest path would suppress',
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
          threats: const ThreatSummary(atWarWith: ['tribe1']),
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
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: expandNwWorkSuppressionNationId,
            view: view,
            snapshot: snapshot,
            config: expandNwWorkSuppressionAiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(2509005),
            suggestionAPI: expandNwWorkSuppressionNwOnlyArmyMoveApi,
            economyPlan: expandNwWorkSuppressionEconomyPlan,
          ),
        );

        final armyMoves =
            orders.armyMoveOrdersByPlayerId[expandNwWorkSuppressionNationId] ??
            const [];
        expect(
          armyMoves.any(
            (m) =>
                m.destinationProvinceId ==
                expandNwWorkSuppressionNwTribeProvince,
          ),
          isTrue,
          reason:
              'COLONIAL must allow NW invasion army moves toward visible '
              'colonial targets.',
        );
      },
    );

    test('EXPAND filter outcome is deterministic for identical inputs', () {
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
      final seeds = AISeedBundle.fromTurnSeed(2509003);

      final first = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: expandNwWorkSuppressionNationId,
          view: view,
          snapshot: snapshot,
          config: expandNwWorkSuppressionAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: seeds,
          suggestionAPI: expandNwWorkSuppressionMixedRegionWorkApi,
          economyPlan: expandNwWorkSuppressionEconomyPlan,
        ),
      );
      final second = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: expandNwWorkSuppressionNationId,
          view: view,
          snapshot: snapshot,
          config: expandNwWorkSuppressionAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: seeds,
          suggestionAPI: expandNwWorkSuppressionMixedRegionWorkApi,
          economyPlan: expandNwWorkSuppressionEconomyPlan,
        ),
      );

      List<String> describe(Orders orders) =>
          (orders.workOrdersByPlayerId[expandNwWorkSuppressionNationId] ??
                  const [])
              .map((w) => '${w.unitId}|${w.target}|${w.targetTileKey}')
              .toList();
      expect(describe(first), describe(second));
    });
  });
}
