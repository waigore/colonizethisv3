// Tests for runRecruitmentPlanner (Refs #2692 S8). SPEC/ai/economy-planner.md
// § Recruitment planner. Uses a deterministic fake [OrderSuggestionAPI] so
// planner-side rules (peasant reservation, soft luxury cap, phase emit order,
// determinism) are testable independently of the suggestion-validation chain.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'domain_planner_test_fake_api.dart';

const _config = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

const _topology = MapTopology(nodes: [], edges: []);

Game _gameWith(Player player) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: [], units: []),
    newWorld: RegionData(provinces: [], units: []),
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

void main() {
  group('runRecruitmentPlanner — peasant reservation (AC-RP-1)', () {
    test(
      'drops both candidates when pending consumes already exhaust peasants',
      () {
        final game = _gameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 1),
          ),
        );
        final view = buildPlayerView(game, _topology, 'gp1');
        final currentOrders = const Orders(
          buildUnitOrdersByPlayerId: {
            'gp1': [
              BuildUnitOrder(
                unitType: 'peasant_levies',
                isMilitary: true,
                spawnProvinceId: 'oldWorld|P1',
              ),
            ],
          },
        );
        final api = _fakeApi(
          recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
          build: const [
            BuildUnitOrder(
              unitType: 'pikemen',
              isMilitary: true,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        );

        final plan = runRecruitmentPlanner(
          game: game,
          view: view,
          currentOrders: currentOrders,
          config: _config,
          seeds: AISeedBundle.fromTurnSeed(42),
          goalPhase: ObserverGoalPhase.develop,
          suggestionApi: api,
        );

        expect(plan.recruitOrders, isEmpty);
        expect(plan.buildUnitOrders, isEmpty);
        expect(plan.rejected, hasLength(2));
        expect(
          plan.rejected.every(
            (r) => r.reason == kRecruitmentRejectInsufficientWorkers,
          ),
          isTrue,
        );
        final tierLabels = plan.rejected.map((r) => r.targetTier).toSet();
        expect(tierLabels, containsAll(<String>{'apprentice', 'pikemen'}));
      },
    );

    test('peasant recruit consumes no peasant (free to emit)', () {
      final game = _gameWith(
        const Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: WorkerPool(peasants: 0),
        ),
      );
      final view = buildPlayerView(game, _topology, 'gp1');
      final api = _fakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.peasant)],
      );

      final plan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: _config,
        seeds: AISeedBundle.fromTurnSeed(7),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
      );

      expect(plan.recruitOrders, hasLength(1));
      expect(plan.recruitOrders.single.targetTier, WorkerTier.peasant);
      expect(plan.rejected, isEmpty);
    });

    test(
      'civilian builds do not draw on peasant budget; trained recruit still '
      'fits a single peasant',
      () {
        final game = _gameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 1, apprentices: 5),
            stockpile: Stockpile(quantities: {'refinedSugar': 10}),
          ),
        );
        final view = buildPlayerView(game, _topology, 'gp1');
        final api = _fakeApi(
          recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
          build: const [
            BuildUnitOrder(
              unitType: 'builder',
              isMilitary: false,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        );

        final plan = runRecruitmentPlanner(
          game: game,
          view: view,
          currentOrders: const Orders(),
          config: _config,
          seeds: AISeedBundle.fromTurnSeed(0),
          goalPhase: ObserverGoalPhase.develop,
          suggestionApi: api,
        );

        expect(plan.recruitOrders, hasLength(1));
        expect(plan.recruitOrders.single.targetTier, WorkerTier.apprentice);
        expect(plan.buildUnitOrders, hasLength(1));
        expect(plan.buildUnitOrders.single.unitType, 'builder');
        expect(plan.rejected, isEmpty);
      },
    );
  });

  group('runRecruitmentPlanner — soft luxury cap', () {
    test(
      'AC-RP-2: rejects apprentice when sustainableTrainedCount == 0 and '
      'no deficit override',
      () {
        // sustainable[apprentice] = stockpile.refinedSugar + projected = 0 + 0 = 0
        // projected after emit = 0 + 1 = 1 > 0 → reject.
        final game = _gameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 5, apprentices: 0),
          ),
        );
        final view = buildPlayerView(game, _topology, 'gp1');
        final api = _fakeApi(
          recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        );

        final plan = runRecruitmentPlanner(
          game: game,
          view: view,
          currentOrders: const Orders(),
          config: _config,
          seeds: AISeedBundle.fromTurnSeed(0),
          goalPhase: ObserverGoalPhase.develop,
          suggestionApi: api,
        );

        expect(plan.recruitOrders, isEmpty);
        expect(plan.rejected, hasLength(1));
        expect(plan.rejected.single.reason, kRecruitmentRejectSoftLuxuryCap);
        expect(plan.rejected.single.targetTier, 'apprentice');
      },
    );

    test(
      'AC-RP-3: deficit override caps journeyman recruit at 1.2 × sustainable '
      '(floor)',
      () {
        // sustainable[journeyman] = stockpile.cigars + projected = 1 + 0 = 1.
        // deficit limit floor(1 * 12 / 10) = 1.
        // current = 1, projected after one emit = 2 > 1 → reject.
        final game = _gameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 5, journeymen: 1),
            stockpile: Stockpile(quantities: {'cigars': 1}),
          ),
        );
        final view = buildPlayerView(game, _topology, 'gp1');
        final api = _fakeApi(
          recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.journeyman)],
        );
        // Deficit hint: target labour 100, effective labour from workers
        // (5 peasants × 1 + 1 journeyman × 6 = 11) → 11 × 10 < 100 × 8 → deficit.
        const hint = EconomyPlan(
          productionAssignments: [
            AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 100),
          ],
          cargoPreference: CargoPreference.none,
        );

        final plan = runRecruitmentPlanner(
          game: game,
          view: view,
          currentOrders: const Orders(),
          config: _config,
          seeds: AISeedBundle.fromTurnSeed(0),
          goalPhase: ObserverGoalPhase.develop,
          suggestionApi: api,
          economyPlanHint: hint,
        );

        expect(plan.recruitOrders, isEmpty);
        expect(plan.rejected, hasLength(1));
        expect(plan.rejected.single.reason, kRecruitmentRejectSoftLuxuryCap);
        expect(plan.rejected.single.targetTier, 'journeyman');
      },
    );

    test(
      'accepts apprentice when projected count fits sustainableTrainedCount',
      () {
        // sustainable[apprentice] = 3 (stockpile) + 0 (no hint) = 3.
        // current = 0, projected after one emit = 1 ≤ 3 → accept.
        final game = _gameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 1, apprentices: 0),
            stockpile: Stockpile(quantities: {'refinedSugar': 3}),
          ),
        );
        final view = buildPlayerView(game, _topology, 'gp1');
        final api = _fakeApi(
          recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        );

        final plan = runRecruitmentPlanner(
          game: game,
          view: view,
          currentOrders: const Orders(),
          config: _config,
          seeds: AISeedBundle.fromTurnSeed(0),
          goalPhase: ObserverGoalPhase.develop,
          suggestionApi: api,
        );

        expect(plan.recruitOrders, hasLength(1));
        expect(plan.recruitOrders.single.targetTier, WorkerTier.apprentice);
        expect(plan.rejected, isEmpty);
      },
    );

    test(
      'economyPlanHint projected refinedSugar output raises sustainable for '
      'apprentice tier',
      () {
        // sustainable[apprentice] = 0 (stockpile) + 2 (projected: 4 labour at
        // 2 labour/run × 1 output = 2). projected after one emit = 1 ≤ 2 → accept.
        final game = _gameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 1, apprentices: 0),
          ),
        );
        final view = buildPlayerView(game, _topology, 'gp1');
        final api = _fakeApi(
          recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        );
        const hint = EconomyPlan(
          productionAssignments: [
            AssignedRecipe(
              recipeId: 'refinedSugar_from_sugarCane',
              assignedLabour: 4,
            ),
          ],
          cargoPreference: CargoPreference.none,
        );

        final plan = runRecruitmentPlanner(
          game: game,
          view: view,
          currentOrders: const Orders(),
          config: _config,
          seeds: AISeedBundle.fromTurnSeed(0),
          goalPhase: ObserverGoalPhase.develop,
          suggestionApi: api,
          economyPlanHint: hint,
        );

        expect(plan.recruitOrders, hasLength(1));
        expect(plan.rejected, isEmpty);
      },
    );
  });

  group('runRecruitmentPlanner — emit order by phase (AC-RP-5)', () {
    Player playerWithOnePeasant() => const Player(
      id: 'gp1',
      displayName: 'A',
      isHuman: false,
      workerPool: WorkerPool(peasants: 1, apprentices: 5),
      stockpile: Stockpile(quantities: {'refinedSugar': 10}),
    );

    test('DEVELOP processes recruit before build (recruit wins peasant)', () {
      final game = _gameWith(playerWithOnePeasant());
      final view = buildPlayerView(game, _topology, 'gp1');
      final api = _fakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
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
        seeds: AISeedBundle.fromTurnSeed(0),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
      );

      expect(plan.recruitOrders, hasLength(1));
      expect(plan.recruitOrders.single.targetTier, WorkerTier.apprentice);
      expect(plan.buildUnitOrders, isEmpty);
      expect(plan.rejected, hasLength(1));
      expect(plan.rejected.single.reason, kRecruitmentRejectInsufficientWorkers);
      expect(plan.rejected.single.targetTier, 'peasant_levies');
    });

    test('EXPAND processes build before recruit (military wins peasant)', () {
      final game = _gameWith(playerWithOnePeasant());
      final view = buildPlayerView(game, _topology, 'gp1');
      final api = _fakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
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
        seeds: AISeedBundle.fromTurnSeed(0),
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api,
      );

      expect(plan.buildUnitOrders, hasLength(1));
      expect(plan.buildUnitOrders.single.unitType, 'peasant_levies');
      expect(plan.recruitOrders, isEmpty);
      expect(plan.rejected, hasLength(1));
      expect(plan.rejected.single.reason, kRecruitmentRejectInsufficientWorkers);
      expect(plan.rejected.single.targetTier, 'apprentice');
    });

    test('COLONIAL also processes build before recruit (matches EXPAND)', () {
      final game = _gameWith(playerWithOnePeasant());
      final view = buildPlayerView(game, _topology, 'gp1');
      final api = _fakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
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
        seeds: AISeedBundle.fromTurnSeed(0),
        goalPhase: ObserverGoalPhase.colonial,
        suggestionApi: api,
      );

      expect(plan.buildUnitOrders, hasLength(1));
      expect(plan.recruitOrders, isEmpty);
    });
  });

  group('runRecruitmentPlanner — determinism (AC-RP-4)', () {
    test('two identical invocations return equal plans', () {
      final game = _gameWith(
        const Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: WorkerPool(peasants: 2, apprentices: 1),
          stockpile: Stockpile(quantities: {'refinedSugar': 5}),
        ),
      );
      final view = buildPlayerView(game, _topology, 'gp1');
      final api = _fakeApi(
        recruit: const [
          RecruitWorkerOrder(targetTier: WorkerTier.peasant),
          RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        ],
        build: const [
          BuildUnitOrder(
            unitType: 'pikemen',
            isMilitary: true,
            spawnProvinceId: 'oldWorld|P1',
          ),
        ],
      );

      final plan1 = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: _config,
        seeds: AISeedBundle.fromTurnSeed(42),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
      );
      final plan2 = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: _config,
        seeds: AISeedBundle.fromTurnSeed(42),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
      );

      expect(
        plan1.recruitOrders.map((o) => o.targetTier).toList(),
        plan2.recruitOrders.map((o) => o.targetTier).toList(),
      );
      expect(
        plan1.buildUnitOrders.map((o) => o.unitType).toList(),
        plan2.buildUnitOrders.map((o) => o.unitType).toList(),
      );
      expect(plan1.rejected, plan2.rejected);
    });
  });

  group('runRecruitmentPlanner — edge cases', () {
    test('returns empty plan when player view targets unknown player', () {
      final game = _gameWith(
        const Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: WorkerPool(peasants: 1),
        ),
      );
      // Reuse gp1's view but resolve against a game without that player.
      final view = buildPlayerView(game, _topology, 'gp1');
      final emptyGame = Game(
        id: 'empty',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: const [],
      );
      final api = _fakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.peasant)],
      );

      final plan = runRecruitmentPlanner(
        game: emptyGame,
        view: view,
        currentOrders: const Orders(),
        config: _config,
        seeds: AISeedBundle.fromTurnSeed(0),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
      );

      expect(plan.recruitOrders, isEmpty);
      expect(plan.buildUnitOrders, isEmpty);
      expect(plan.rejected, isEmpty);
    });

    test('returns empty plan when suggestion API returns nothing', () {
      final game = _gameWith(
        const Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: WorkerPool(peasants: 5),
        ),
      );
      final view = buildPlayerView(game, _topology, 'gp1');
      final api = _fakeApi();

      final plan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: _config,
        seeds: AISeedBundle.fromTurnSeed(0),
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api,
      );

      expect(plan.recruitOrders, isEmpty);
      expect(plan.buildUnitOrders, isEmpty);
      expect(plan.rejected, isEmpty);
    });

    test(
      'multiple peasant-consuming recruits draw down the budget in order',
      () {
        // 3 peasants, no pending consumes. Three recruit candidates:
        // peasant (free), apprentice (consumes 1), journeyman (consumes 1).
        // sustainable: refinedSugar=10, cigars=10 → both fit.
        // Result: all 3 emitted, budget after = 1 peasant remaining.
        final game = _gameWith(
          const Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            workerPool: WorkerPool(peasants: 3),
            stockpile: Stockpile(
              quantities: {'refinedSugar': 10, 'cigars': 10},
            ),
          ),
        );
        final view = buildPlayerView(game, _topology, 'gp1');
        final api = _fakeApi(
          recruit: const [
            RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
          ],
        );

        final plan = runRecruitmentPlanner(
          game: game,
          view: view,
          currentOrders: const Orders(),
          config: _config,
          seeds: AISeedBundle.fromTurnSeed(0),
          goalPhase: ObserverGoalPhase.develop,
          suggestionApi: api,
        );

        expect(
          plan.recruitOrders.map((o) => o.targetTier).toList(),
          const [
            WorkerTier.peasant,
            WorkerTier.apprentice,
            WorkerTier.journeyman,
          ],
        );
        expect(plan.rejected, isEmpty);
      },
    );
  });
}
