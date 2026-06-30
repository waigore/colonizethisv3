// Tests for the shared paper budget ledger in runRecruitmentPlanner
// (Refs #3793 AC7). SPEC/ai/civilian-build-planner.md § Paper budget.
//
// Uses a deterministic fake [OrderSuggestionAPI] so the planner-side paper
// reservation + running ledger are testable independently of the
// suggestion-validation chain. growthStagePlannerEnabled is pinned `false`
// to isolate the paper gate from the growth-stage suppression / fabric
// reservation rules.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';

const _config = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

const _topology = MapTopology(nodes: [], edges: []);

final _paperId = CommodityCatalog.paper.id;
final _cigarsId = CommodityCatalog.cigars.id;
final _refinedSugarId = CommodityCatalog.refinedSugar.id;

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

BuildUnitOrder _civilianBuild(String unitType) => BuildUnitOrder(
  unitType: unitType,
  isMilitary: false,
  spawnProvinceId: 'oldWorld|P1',
);

void main() {
  group('researchReservedPaper — reservation math', () {
    test('floors the share and clamps to [0, currentPaper]', () {
      // Default share 0.5.
      expect(researchReservedPaper(10), 5);
      expect(researchReservedPaper(9), 4); // floor(4.5)
      expect(researchReservedPaper(1), 0); // floor(0.5)
      expect(researchReservedPaper(0), 0);
      expect(researchReservedPaper(-3), 0);
    });
  });

  group('runRecruitmentPlanner — shared paper ledger (AC7)', () {
    test('reserves research paper then accepts only what the remaining budget '
        'funds; over-budget trained recruits are paper-rejected', () {
      final game = _gameWith(
        Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: const WorkerPool(peasants: 5),
          // 10 paper → reserve floor(10×0.5)=5 → allocatable budget 5.
          // Plenty of cigars so the journeyman soft-luxury cap never binds.
          stockpile: Stockpile(quantities: {_paperId: 10, _cigarsId: 100}),
        ),
      );
      final view = buildPlayerView(game, _topology, 'gp1');
      // Two journeyman recruits, 5 paper each. Budget 5 funds exactly one.
      final api = _fakeApi(
        recruit: const [
          RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
          RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
        ],
      );

      final plan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: _config,
        seeds: AISeedBundle.fromTurnSeed(42),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
        growthStagePlannerEnabled: false,
        paperBudgetLedgerEnabled: true,
      );

      expect(plan.recruitOrders, hasLength(1));
      expect(plan.recruitOrders.single.targetTier, WorkerTier.journeyman);
      expect(
        plan.rejected
            .where((r) => r.reason == kRecruitmentRejectPaperBudget)
            .map((r) => r.targetTier),
        ['journeyman'],
      );
    });

    test('civilian builds compete for the same paper budget (recruit-first '
        'phase wins, build is paper-rejected)', () {
      final game = _gameWith(
        Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: const WorkerPool(peasants: 5),
          // 4 paper → reserve 2 → budget 2. Refined sugar covers the
          // apprentice soft cap.
          stockpile: Stockpile(quantities: {_paperId: 4, _refinedSugarId: 100}),
        ),
      );
      final view = buildPlayerView(game, _topology, 'gp1');
      final api = _fakeApi(
        // Apprentice costs 2 paper; Builder civilian build costs 2 paper.
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        build: [_civilianBuild(kUnitTypeBuilder)],
      );

      final plan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: _config,
        seeds: AISeedBundle.fromTurnSeed(1),
        // DEVELOP processes recruit/train before builds.
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
        growthStagePlannerEnabled: false,
        paperBudgetLedgerEnabled: true,
        includeCivilianBuilds: true,
      );

      expect(plan.recruitOrders, hasLength(1));
      expect(plan.recruitOrders.single.targetTier, WorkerTier.apprentice);
      expect(plan.buildUnitOrders, isEmpty);
      expect(
        plan.rejected
            .where((r) => r.reason == kRecruitmentRejectPaperBudget)
            .map((r) => r.targetTier),
        [kUnitTypeBuilder],
      );
    });

    test('build-first phase spends the budget on the civilian build; the '
        'trained recruit is paper-rejected (phase emit order respected)', () {
      final game = _gameWith(
        Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: const WorkerPool(peasants: 5),
          stockpile: Stockpile(quantities: {_paperId: 4, _refinedSugarId: 100}),
        ),
      );
      final view = buildPlayerView(game, _topology, 'gp1');
      final api = _fakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        build: [_civilianBuild(kUnitTypeBuilder)],
      );

      final plan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: _config,
        seeds: AISeedBundle.fromTurnSeed(1),
        // EXPAND processes builds before recruit/train.
        goalPhase: ObserverGoalPhase.expand,
        suggestionApi: api,
        growthStagePlannerEnabled: false,
        paperBudgetLedgerEnabled: true,
        includeCivilianBuilds: true,
      );

      expect(plan.buildUnitOrders, hasLength(1));
      expect(plan.buildUnitOrders.single.unitType, kUnitTypeBuilder);
      expect(plan.recruitOrders, isEmpty);
      expect(
        plan.rejected
            .where((r) => r.reason == kRecruitmentRejectPaperBudget)
            .map((r) => r.targetTier),
        ['apprentice'],
      );
    });

    test('pending paper orders shrink the allocatable budget', () {
      final game = _gameWith(
        Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: const WorkerPool(peasants: 5),
          // 10 paper → reserve 5 → raw budget 5. A pending apprentice recruit
          // (2 paper) already committed leaves 3 — too little for a journeyman
          // (5 paper).
          stockpile: Stockpile(quantities: {_paperId: 10, _cigarsId: 100}),
        ),
      );
      final view = buildPlayerView(game, _topology, 'gp1');
      const currentOrders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'gp1': [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        },
      );
      final api = _fakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.journeyman)],
      );

      final plan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: currentOrders,
        config: _config,
        seeds: AISeedBundle.fromTurnSeed(3),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
        growthStagePlannerEnabled: false,
        paperBudgetLedgerEnabled: true,
      );

      expect(plan.recruitOrders, isEmpty);
      expect(plan.rejected.single.reason, kRecruitmentRejectPaperBudget);
      expect(plan.rejected.single.targetTier, 'journeyman');
    });

    test('determinism: identical inputs yield identical plans', () {
      Player player() => Player(
        id: 'gp1',
        displayName: 'A',
        isHuman: false,
        workerPool: const WorkerPool(peasants: 5),
        stockpile: Stockpile(quantities: {_paperId: 7, _cigarsId: 100}),
      );
      final game = _gameWith(player());
      final view = buildPlayerView(game, _topology, 'gp1');
      List<RecruitWorkerOrder> recruits() => const [
        RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
        RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
      ];

      RecruitmentPlan run() => runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: _config,
        seeds: AISeedBundle.fromTurnSeed(99),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: _fakeApi(recruit: recruits()),
        growthStagePlannerEnabled: false,
        paperBudgetLedgerEnabled: true,
      );

      final plan1 = run();
      final plan2 = run();
      expect(
        plan1.recruitOrders.map((r) => r.targetTier),
        plan2.recruitOrders.map((r) => r.targetTier),
      );
      expect(plan1.rejected, plan2.rejected);
    });
  });

  group('runRecruitmentPlanner — paper ledger disabled is inert (AC7c)', () {
    test('default flag: no paper rejections; both candidates emit', () {
      final game = _gameWith(
        Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
          workerPool: const WorkerPool(peasants: 5),
          // Only 4 paper — would bind the ledger if enabled — but the default
          // path applies no paper gate.
          stockpile: Stockpile(quantities: {_paperId: 4, _refinedSugarId: 100}),
        ),
      );
      final view = buildPlayerView(game, _topology, 'gp1');
      final api = _fakeApi(
        recruit: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        build: [_civilianBuild(kUnitTypeBuilder)],
      );

      final plan = runRecruitmentPlanner(
        game: game,
        view: view,
        currentOrders: const Orders(),
        config: _config,
        seeds: AISeedBundle.fromTurnSeed(2),
        goalPhase: ObserverGoalPhase.develop,
        suggestionApi: api,
        growthStagePlannerEnabled: false,
        // paperBudgetLedgerEnabled omitted → default false.
        includeCivilianBuilds: true,
      );

      expect(plan.recruitOrders.single.targetTier, WorkerTier.apprentice);
      expect(plan.buildUnitOrders.single.unitType, kUnitTypeBuilder);
      expect(
        plan.rejected.where((r) => r.reason == kRecruitmentRejectPaperBudget),
        isEmpty,
      );
    });
  });
}
