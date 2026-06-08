// Growth-stage planner (Refs #3371). SPEC/ai/growth-stage-planner.md.
// Economy, scoring, and recruitment ACs. Builder relocation / anti-thrash ACs
// live in growth_stage_planner_relocation_test.dart to respect per-file limits.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/growth_stage_work_priorities.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'growth_stage_planner_test_support.dart';

void main() {
  group('GrowthStage.compute — AC10 determinism', () {
    test('identical inputs yield identical priorities', () {
      final game = bootstrapFabricGame();
      final a = GrowthStage.compute(game, 'gp1');
      final b = GrowthStage.compute(game, 'gp1');
      expect(a.workerGrowthPriority, b.workerGrowthPriority);
      expect(a.infrastructurePriority, b.infrastructurePriority);
      expect(a.resourceProductionPriority, b.resourceProductionPriority);
      expect(a.militaryPriority, b.militaryPriority);
    });
  });

  group('runEconomyPlanner growth-stage — AC1 bootstrap worker growth', () {
    test('fabric recipe receives the most labour', () {
      final game = bootstrapFabricGame();
      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: kTestConfig,
        seeds: kTestSeeds,
        growthStagePlannerEnabled: true,
      );

      final fabricLabour = labourForRecipe(
        plan,
        ProductionRecipesCatalog.fabricFromWool.id,
      );
      expect(fabricLabour, greaterThan(0));
      for (final assignment in plan.productionAssignments) {
        if (assignment.recipeId ==
            ProductionRecipesCatalog.fabricFromWool.id) {
          continue;
        }
        expect(
          fabricLabour,
          greaterThan(assignment.assignedLabour),
          reason:
              'fabric should receive more labour than ${assignment.recipeId}',
        );
      }
    });
  });

  group('runEconomyPlanner growth-stage — AC2 infrastructure', () {
    test('assigns labour to castIron when mature and inputs on hand', () {
      final game = matureCastIronGame();
      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: kTestConfig,
        seeds: kTestSeeds,
        growthStagePlannerEnabled: true,
      );

      expect(
        labourForRecipe(
          plan,
          ProductionRecipesCatalog.castIronFromTimberIronCoal.id,
        ),
        greaterThan(0),
      );
    });
  });

  group('stageScaledRecipeScore — AC5 stockpile damping', () {
    test('high castIron stockpile dampens castIron recipe score', () {
      const workers = WorkerPool(peasants: 12);
      const agenda = 'peacemaker';
      final matureStage = GrowthStage.compute(matureCastIronGame(), 'gp1');
      final stockLow = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 80)
          .applyDelta(CommodityCatalog.timber.id, 30)
          .applyDelta(CommodityCatalog.iron.id, 10);
      final stockHigh = stockLow.applyDelta(CommodityCatalog.castIron.id, 25);

      final scoreLow = stageScaledRecipeScore(
        recipe: ProductionRecipesCatalog.castIronFromTimberIronCoal,
        stockpile: stockLow,
        workers: workers,
        agendaId: agenda,
        stage: matureStage,
      );
      final scoreHigh = stageScaledRecipeScore(
        recipe: ProductionRecipesCatalog.castIronFromTimberIronCoal,
        stockpile: stockHigh,
        workers: workers,
        agendaId: agenda,
        stage: matureStage,
      );
      expect(scoreHigh, lessThan(scoreLow));
    });
  });

  group('GrowthStage — AC6 at-war military floor', () {
    test('at-war GP with 4 labour has militaryPriority 0.3', () {
      final game = bootstrapFabricGame();
      final stage = GrowthStage.compute(
        game,
        'gp1',
        snapshot: atWarSnapshot('gp1'),
      );
      expect(stage.militaryPriority, kAtWarMilitaryFloor);
    });

    test('military-input recipe receives labour under at-war floor', () {
      final game = Game(
        id: 'g-3371-ac6',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            capitalProvinceId: 'oldWorld|p0',
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.grain.id, 40)
                .applyDelta(CommodityCatalog.copper.id, 5)
                .applyDelta(CommodityCatalog.tin.id, 5),
            workerPool: const WorkerPool(peasants: 4),
          ),
        ],
      );
      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: kTestConfig,
        seeds: kTestSeeds,
        snapshot: atWarSnapshot('gp1'),
        growthStagePlannerEnabled: true,
      );

      final bronzeLabour = labourForRecipe(
        plan,
        ProductionRecipesCatalog.bronzeFromCopperTin.id,
      );
      expect(bronzeLabour, greaterThan(0));
    });
  });

  group('stageScaledRecipeScore — AC11 shortage dominance', () {
    test('fabric stageScaledScore beats military input in bootstrap', () {
      final game = Game(
        id: 'g-3371-ac11',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|p0', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {'oldWorld|p0|1|0': 'wool'},
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            capitalProvinceId: 'oldWorld|p0',
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.grain.id, 40)
                .applyDelta(CommodityCatalog.wool.id, 10)
                .applyDelta(CommodityCatalog.copper.id, 5)
                .applyDelta(CommodityCatalog.tin.id, 5),
            workerPool: const WorkerPool(peasants: 2),
          ),
        ],
      );
      final stage = GrowthStage.compute(game, 'gp1');
      expect(stage.workerGrowthPriority, greaterThan(0.8));

      const workers = WorkerPool(peasants: 2);
      final stockpile = game.players.first.stockpile;

      final fabricScore = stageScaledRecipeScore(
        recipe: ProductionRecipesCatalog.fabricFromWool,
        stockpile: stockpile,
        workers: workers,
        agendaId: 'peacemaker',
        stage: stage,
      );
      final militaryScore = stageScaledRecipeScore(
        recipe: ProductionRecipesCatalog.bronzeFromCopperTin,
        stockpile: stockpile,
        workers: workers,
        agendaId: 'peacemaker',
        stage: stage,
      );
      expect(fabricScore, greaterThan(militaryScore));
    });
  });

  group('runRecruitmentPlanner growth-stage — AC4 bootstrap build suppression',
      () {
    test('suppresses regiment builds when military priority is low', () {
      final game = gameWithPlayer(
        Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: const WorkerPool(peasants: 3),
          stockpile: const Stockpile().applyDelta(CommodityCatalog.grain.id, 30),
        ),
      );
      final view = buildPlayerView(game, kTestTopology, 'gp1');
      final api = buildFakeApi(
        build: const [
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: 'oldWorld|P1',
          ),
        ],
      );

      final plan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: kTestConfig,
        seeds: kTestSeeds,
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api,
        growthStagePlannerEnabled: true,
      );

      expect(plan.buildUnitOrders, isEmpty);
      expect(plan.rejected, hasLength(1));
      expect(
        plan.rejected.first.reason,
        kRecruitmentRejectMilitaryBuildSuppressed,
      );
    });
  });

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
        config: kTestConfig,
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

      final recruitPlan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: kTestConfig,
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
      );
      expect(recruitPlan.buildUnitOrders, isNotEmpty);
    });
  });

  group('peasantRecruitScoreScale — AC12 recruitment modulation', () {
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

      final plan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: kTestConfig,
        seeds: kTestSeeds,
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api(),
        growthStagePlannerEnabled: true,
        snapshot: snapshot,
      );

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

      final plan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: kTestConfig,
        seeds: kTestSeeds,
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api(),
        growthStagePlannerEnabled: true,
        snapshot: snapshot,
      );

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

      final plan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: kTestConfig,
        seeds: kTestSeeds,
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api(),
        growthStagePlannerEnabled: false,
        snapshot: snapshot,
      );

      expect(
        plan.rejected.map((r) => r.reason),
        isNot(contains(kRecruitmentRejectMilitaryFabricReservation)),
      );
    });
  });
}
