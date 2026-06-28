import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

const _nationId = 'gp_seller';

Game _sellerGame({int fabricHeld = 2}) {
  return Game(
    id: 'g-peasant-recruit',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 5; i++)
            Province(
              id: 'oldWorld|p$i',
              regionId: kRegionOldWorld,
              ownerId: _nationId,
            ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: _nationId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: Stockpile(quantities: {'fabric': fabricHeld}),
      ),
    ],
  );
}

void main() {
  group(
    'runDomainPlannersWithOutcome castIron labour peasant recruit (Refs #2847)',
    () {
      const topology = MapTopology(nodes: [], edges: []);
      const peasantRecruit = RecruitWorkerOrder(targetTier: WorkerTier.peasant);
      const regimentBuild = BuildUnitOrder(
        unitType: 'peasant_levies',
        isMilitary: true,
        spawnProvinceId: 'oldWorld|p0',
      );

      test(
        'emits peasant recruit when expand economy flag is set',
        () {
          final game = _sellerGame();
          final view = buildPlayerView(game, topology, _nationId);
          final snapshot = AIWorldSnapshot.fromPlayerView(
            view,
            topology: topology,
          );
          final phasePlan = PhasePlanOutcome(
            phase: ObserverGoalPhase.expand,
            expandEconomyPlan: const ExpandEconomyPlan(
              forceCheapestRegimentBuild: true,
              boostTreasuryRecoveryCargo: false,
              boostCastIronLabourPeasantRecruitment: true,
            ),
          );
          final outcome = runDomainPlannersWithOutcome(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: kTestAiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(284702),
            suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
              work: [],
              build: [regimentBuild],
              move: [],
              research: [],
              navalMove: [],
              navalMission: [],
              recruitWorker: [peasantRecruit, peasantRecruit],
            ),
            economyPlan: kTestEconomyPlan,
            phasePlan: phasePlan,
          );
          final recruits =
              outcome.orders.recruitWorkerOrdersByPlayerId[_nationId] ?? [];
          expect(recruits, equals(const [peasantRecruit]));
        },
      );

      test(
        'does not emit peasant recruit when fabric is below recruit cost',
        () {
          final game = _sellerGame(fabricHeld: 0);
          final view = buildPlayerView(game, topology, _nationId);
          final snapshot = AIWorldSnapshot.fromPlayerView(
            view,
            topology: topology,
          );
          final phasePlan = PhasePlanOutcome(
            phase: ObserverGoalPhase.expand,
            expandEconomyPlan: const ExpandEconomyPlan(
              forceCheapestRegimentBuild: true,
              boostTreasuryRecoveryCargo: false,
              boostCastIronLabourPeasantRecruitment: true,
            ),
          );
          final outcome = runDomainPlannersWithOutcome(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: kTestAiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(284704),
            suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
              work: [],
              build: [regimentBuild],
              move: [],
              research: [],
              navalMove: [],
              navalMission: [],
              recruitWorker: [peasantRecruit, peasantRecruit],
            ),
            economyPlan: kTestEconomyPlan,
            phasePlan: phasePlan,
          );
          expect(
            outcome.orders.recruitWorkerOrdersByPlayerId[_nationId],
            isNull,
          );
        },
      );

      test(
        'does not emit peasant recruit when flag is false',
        () {
          final game = _sellerGame();
          final view = buildPlayerView(game, topology, _nationId);
          final snapshot = AIWorldSnapshot.fromPlayerView(
            view,
            topology: topology,
          );
          final outcome = runDomainPlannersWithOutcome(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: kTestAiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(284703),
            suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
              work: [],
              build: [regimentBuild],
              move: [],
              research: [],
              navalMove: [],
              navalMission: [],
              recruitWorker: [peasantRecruit],
            ),
            economyPlan: kTestEconomyPlan,
            phasePlan: const PhasePlanOutcome(
              phase: ObserverGoalPhase.expand,
            ),
          );
          expect(
            outcome.orders.recruitWorkerOrdersByPlayerId[_nationId],
            isNull,
          );
        },
      );
    },
  );
}
