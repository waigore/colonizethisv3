// Case bodies for `growth_stage_planner_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/growth_stage_work_priorities.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/growth_stage_planner_test_support.dart';
import '../support/planner_test_helpers.dart';
import 'growth_stage_planner_routing_cases_tail_cases.dart';

void registerGrowthStagePlannerRoutingCases() {
  group('prioritizeWorkOrdersForGrowthStage — bootstrap feedstock', () {
    test('wool build_improvement sorts before build_port', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g-3371-work',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: '$ow|p0', regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {
            '$ow|p0|1|0': 'wool',
            '$ow|p0|2|0': 'timber',
          },
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            capitalProvinceId: '$ow|p0',
            stockpile: const Stockpile(),
            workerPool: const WorkerPool(peasants: 4),
          ),
        ],
      );
      final stage = GrowthStage.compute(game, 'gp1');
      const candidates = [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildPort,
          targetTileKey: '$ow|p0|2|0',
        ),
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: '$ow|p0|1|0',
        ),
      ];
      final ordered = prioritizeWorkOrdersForGrowthStage(
        workCandidates: candidates,
        game: game,
        playerId: 'gp1',
        stage: stage,
        growthStagePlannerEnabled: true,
      );
      expect(ordered.first.target, kWorkTargetBuildImprovement);
      expect(ordered.first.targetTileKey, '$ow|p0|1|0');
    });
  });

  group('growthStageFeedstockPreference — bootstrap routing (AC1/AC2)', () {
    Game gameFor({
      required int peasants,
      int fabric = 0,
    }) {
      const ow = 'oldWorld';
      return Game(
        id: 'g-3371-feedstock',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [Province(id: '$ow|p0', regionId: ow, ownerId: 'gp1')],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            capitalProvinceId: '$ow|p0',
            stockpile: Stockpile(
              quantities: {CommodityCatalog.fabric.id: fabric},
            ),
            workerPool: WorkerPool(peasants: peasants),
          ),
        ],
      );
    }

    test('bootstrap GP requests fabric feedstock (wool/cotton)', () {
      final game = gameFor(peasants: 4);
      final stage = GrowthStage.compute(game, 'gp1');
      final pref = growthStageFeedstockPreference(
        game: game,
        playerId: 'gp1',
        stage: stage,
        growthStagePlannerEnabled: true,
      );
      expect(pref.fabricFeedstockResourceIds, containsAll(['wool', 'cotton']));
      expect(
        pref.infraFeedstockResourceIds,
        containsAll(['timber', 'iron', 'coal']),
      );
    });

    test('fabric-saturated GP no longer requests fabric feedstock', () {
      final game = gameFor(peasants: 4, fabric: kReserveTarget);
      final stage = GrowthStage.compute(game, 'gp1');
      final pref = growthStageFeedstockPreference(
        game: game,
        playerId: 'gp1',
        stage: stage,
        growthStagePlannerEnabled: true,
      );
      expect(pref.fabricFeedstockResourceIds, isEmpty);
    });

    test('disabled flag yields no feedstock preference', () {
      final game = gameFor(peasants: 4);
      final stage = GrowthStage.compute(game, 'gp1');
      final pref = growthStageFeedstockPreference(
        game: game,
        playerId: 'gp1',
        stage: stage,
        growthStagePlannerEnabled: false,
      );
      expect(pref.fabricFeedstockResourceIds, isEmpty);
      expect(pref.infraFeedstockResourceIds, isEmpty);
    });
  });

  group('runEconomyPlanner growth-stage — AC3 military unlocks at maturity', () {
    test('assigns military-input labour and does not suppress builds', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g-3371-ac3',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: '$ow|p0', regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {
            '$ow|p0|1|0': 'timber',
            '$ow|p0|2|0': 'iron',
          },
          tileState: const TileMapState(
            improvementByTile: {
              '$ow|p0|1|0': 1,
              '$ow|p0|2|0': 1,
            },
          ),
          playerProspectedTiles: const {
            'gp1': {'$ow|p0|2|0'},
          },
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            capitalProvinceId: '$ow|p0',
            treasury: 2500,
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.grain.id, 80)
                .applyDelta(CommodityCatalog.fabric.id, 6)
                .applyDelta(CommodityCatalog.castIron.id, 6)
                .applyDelta(CommodityCatalog.copper.id, 10)
                .applyDelta(CommodityCatalog.tin.id, 10),
            workerPool: const WorkerPool(peasants: 12),
          ),
        ],
      );
      final snapshot = atWarSnapshot('gp1');
      final stage = GrowthStage.compute(game, 'gp1', snapshot: snapshot);
      expect(growthStageSuppressesMilitaryBuilds(stage), isFalse);

      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: kTestAiConfig,
        seeds: kTestSeeds,
        snapshot: snapshot,
        growthStagePlannerEnabled: true,
      );

      expect(
        labourForRecipe(
          plan,
          ProductionRecipesCatalog.bronzeFromCopperTin.id,
        ),
        greaterThan(0),
        reason: 'mature at-war GP should assign military-input labour',
      );

      final recruitPlan = runRecruitmentPlanner(RecruitmentPlannerInput(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: kTestAiConfig,
        seeds: kTestSeeds,
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: buildFakeApi(
          build: const [
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary: true,
              spawnProvinceId: '$ow|p0',
            ),
          ],
        ),
        growthStagePlannerEnabled: true,
        snapshot: snapshot,
      ));
      expect(recruitPlan.buildUnitOrders, isNotEmpty);
    });
  });

  registerGrowthStagePlannerRoutingCasesTail();
}
