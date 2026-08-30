// Case bodies for `growth_stage_planner_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/growth_stage_work_priorities.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/growth_stage_planner_test_support.dart';
import '../support/planner_test_helpers.dart';

void registerGrowthStagePlannerRoutingCasesTail() {
  group('prioritizeWorkOrdersForGrowthStage — bootstrap feedstock', () {
    test('bootstrap scale exceeds mature scale; mature respects floor', () {
      final bootstrap = GrowthStage.compute(bootstrapFabricGame(), 'gp1');
      final mature = GrowthStage.compute(matureCastIronGame(), 'gp1');

      final bootstrapScale = peasantRecruitScoreScale(bootstrap);
      final matureScale = peasantRecruitScoreScale(mature);

      expect(bootstrapScale, greaterThan(matureScale));
      expect(matureScale, greaterThanOrEqualTo(kRecruitmentFloor));
    });
  });

  group('runRecruitmentPlanner growth-stage — AC13 military fabric reservation',
      () {
    Game militaryReadyGame({required int fabricHeld}) {
      const ow = 'oldWorld';
      return Game(
        id: 'g-3371-ac13',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: '$ow|p0', regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            capitalProvinceId: '$ow|p0',
            treasury: 2500,
            stockpile: Stockpile()
                .applyDelta(CommodityCatalog.grain.id, 40)
                .applyDelta(CommodityCatalog.fabric.id, fabricHeld),
            workerPool: const WorkerPool(peasants: 4),
          ),
        ],
      );
    }

    OrderSuggestionAPI api() => buildFakeApi(
      recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.peasant)],
      build: const [
        BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p0',
        ),
      ],
    );

    test('reserves scarce fabric: peasant recruit dropped, regiment kept', () {
      final game = militaryReadyGame(fabricHeld: 1);
      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final snapshot = atWarSnapshot('gp1');

      final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: kTestAiConfig,
        seeds: kTestSeeds,
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api(),
        growthStagePlannerEnabled: true,
        snapshot: snapshot,
      ));

      expect(plan.recruitOrders, isEmpty);
      expect(plan.buildUnitOrders, isNotEmpty);
      expect(
        plan.rejected.map((r) => r.reason),
        contains(kRecruitmentRejectMilitaryFabricReservation),
      );
    });

    test('abundant fabric: peasant recruit not reservation-rejected', () {
      final game = militaryReadyGame(fabricHeld: kReserveTarget);
      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final snapshot = atWarSnapshot('gp1');

      final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: kTestAiConfig,
        seeds: kTestSeeds,
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api(),
        growthStagePlannerEnabled: true,
        snapshot: snapshot,
      ));

      expect(plan.recruitOrders, isNotEmpty);
      expect(
        plan.rejected.map((r) => r.reason),
        isNot(contains(kRecruitmentRejectMilitaryFabricReservation)),
      );
    });

    test('flag off: no reservation rejection', () {
      final game = militaryReadyGame(fabricHeld: 1);
      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final snapshot = atWarSnapshot('gp1');

      final plan = runRecruitmentPlanner(RecruitmentPlannerInput(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: kTestAiConfig,
        seeds: kTestSeeds,
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api(),
        growthStagePlannerEnabled: false,
        snapshot: snapshot,
      ));

      expect(
        plan.rejected.map((r) => r.reason),
        isNot(contains(kRecruitmentRejectMilitaryFabricReservation)),
      );
    });
  });
}
