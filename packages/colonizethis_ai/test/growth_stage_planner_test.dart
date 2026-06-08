// Growth-stage planner (Refs #3371). SPEC/ai/growth-stage-planner.md.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/perception/summary_models.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'domain_planner_test_fake_api.dart';

const _topology = MapTopology(nodes: [], edges: []);
const _config = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);
final _seeds = AISeedBundle.fromTurnSeed(3371);

Game _gameWith(Player player) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(provinces: [], units: []),
    newWorld: const RegionData(provinces: [], units: []),
  ),
  players: [player],
);

OrderSuggestionAPI _fakeApi({
  List<RecruitWorkerOrder> recruit = const [],
  List<BuildUnitOrder> build = const [],
}) {
  return FakeOrderSuggestionAPIForDomainPlannerTests(
    work: const [],
    build: build,
    move: const [],
    research: const [],
    navalMove: const [],
    navalMission: const [],
    recruitWorker: recruit,
  );
}

int _labourForRecipe(EconomyPlan plan, String recipeId) {
  for (final a in plan.productionAssignments) {
    if (a.recipeId == recipeId) return a.assignedLabour;
  }
  return 0;
}

Game _bootstrapFabricGame() {
  const ow = 'oldWorld';
  return Game(
    id: 'g-3371-ac1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(id: '$ow|p0', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {'$ow|p0|1|0': 'wool'},
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p0',
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 40)
            .applyDelta(CommodityCatalog.wool.id, 10),
        workerPool: const WorkerPool(peasants: 4),
      ),
    ],
  );
}

Game _matureCastIronGame({int castIronHeld = 0}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-3371-ac2',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(id: '$ow|p0', regionId: ow, ownerId: 'gp1'),
          Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {
        '$ow|p0|1|0': 'timber',
        '$ow|p1|1|0': 'iron',
      },
      tileState: const TileMapState(
        improvementByTile: {
          '$ow|p0|1|0': 1,
          '$ow|p1|1|0': 1,
        },
      ),
      playerProspectedTiles: const {
        'gp1': {'$ow|p1|1|0'},
      },
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p0',
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 80)
            .applyDelta(CommodityCatalog.timber.id, 30)
            .applyDelta(CommodityCatalog.iron.id, 10)
            .applyDelta(CommodityCatalog.castIron.id, castIronHeld),
        workerPool: const WorkerPool(peasants: 12),
      ),
    ],
  );
}

AIWorldSnapshot _atWarSnapshot(String playerId) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(
      atWarWith: ['gp2'],
      neighborProvincesHostile: 1,
      capitalThreatened: false,
    ),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: 2,
      provincesToVictory: 29,
      invadableProvinceIdsSorted: ['oldWorld|enemy'],
    ),
    economy: const EconomySummary(
      workerCount: 4,
      treasury: 100,
      ownProvinceCount: 2,
    ),
    relations: const {},
  );
}

void main() {
  group('GrowthStage.compute — AC10 determinism', () {
    test('identical inputs yield identical priorities', () {
      final game = _bootstrapFabricGame();
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
      final game = _bootstrapFabricGame();
      final view = buildPlayerView(game, _topology, 'gp1');
      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: _config,
        seeds: _seeds,
        growthStagePlannerEnabled: true,
      );

      final fabricLabour = _labourForRecipe(
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
      final game = _matureCastIronGame();
      final view = buildPlayerView(game, _topology, 'gp1');
      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: _config,
        seeds: _seeds,
        growthStagePlannerEnabled: true,
      );

      expect(
        _labourForRecipe(
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
      final matureStage = GrowthStage.compute(_matureCastIronGame(), 'gp1');
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
      final game = _bootstrapFabricGame();
      final stage = GrowthStage.compute(
        game,
        'gp1',
        snapshot: _atWarSnapshot('gp1'),
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
      final view = buildPlayerView(game, _topology, 'gp1');
      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: _config,
        seeds: _seeds,
        snapshot: _atWarSnapshot('gp1'),
        growthStagePlannerEnabled: true,
      );

      final bronzeLabour = _labourForRecipe(
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
      final game = _gameWith(
        Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: const WorkerPool(peasants: 3),
          stockpile: const Stockpile().applyDelta(CommodityCatalog.grain.id, 30),
        ),
      );
      final view = buildPlayerView(game, _topology, 'gp1');
      final api = _fakeApi(
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
        config: _config,
        seeds: _seeds,
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

  group('peasantRecruitScoreScale — AC12 recruitment modulation', () {
    test('bootstrap scale exceeds mature scale; mature respects floor', () {
      final bootstrap = GrowthStage.compute(_bootstrapFabricGame(), 'gp1');
      final mature = GrowthStage.compute(_matureCastIronGame(), 'gp1');

      final bootstrapScale = peasantRecruitScoreScale(bootstrap);
      final matureScale = peasantRecruitScoreScale(mature);

      expect(bootstrapScale, greaterThan(matureScale));
      expect(matureScale, greaterThanOrEqualTo(kRecruitmentFloor));
    });
  });
}
