import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// #2692 S9 resolver tier coverage and ordering / multi-player pins for
/// `applyBuildAndWorkOrders` worker-pool sub-phase (see
/// SPEC/program/turn-resolution-phase-details.md and
/// SPEC/game/workers-and-population.md § Recruiting, Training, and
/// Disbanding). Baseline S4 cases live in
/// `orders_application_worker_pool_phase_test.dart`; this sibling file is
/// kept separate to honor the colonizethis_logic 400-line per-test-file
/// policy enforced by `repo.logic_test_file_size`.
void main() {
  group('applyBuildAndWorkOrders worker pool sub-phase — S9 tier coverage '
      'and ordering (#2692 S9)', () {
    test('accepted journeyman train consumes peasant, paper, and treasury '
        '(#2692 S9 tier coverage)', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 8}),
            workerPool: const WorkerPool(peasants: 2),
            treasury: 700,
            techUnlocked: const {
              kTechIdTrainedJourneymen: true,
              kTechIdCigarProduction: true,
            },
          ),
        ],
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.journeyman)],
        },
      );

      final result = applyBuildAndWorkOrders(game, orders);

      final p = result.players.single;
      expect(p.workerPool.peasants, 1, reason: 'one peasant consumed');
      expect(p.workerPool.journeymen, 1, reason: 'one journeyman added');
      expect(
        p.stockpile.quantityOf(CommodityCatalog.paper.id),
        3,
        reason: '5 paper deducted per SPEC § Recruiting cost table',
      );
      expect(
        p.treasury,
        200,
        reason: '500 ducats deducted per SPEC § Recruiting cost table',
      );
    });

    test('accepted master train consumes peasant, paper, and treasury '
        '(#2692 S9 tier coverage; AC #3 master tail)', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 12}),
            workerPool: const WorkerPool(peasants: 1),
            treasury: 1200,
            techUnlocked: const {
              kTechIdMasterArtisans: true,
              kTechIdHatProduction: true,
            },
          ),
        ],
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.master)],
        },
      );

      final result = applyBuildAndWorkOrders(game, orders);

      final p = result.players.single;
      expect(p.workerPool.peasants, 0, reason: 'one peasant consumed');
      expect(p.workerPool.masters, 1, reason: 'one master added');
      expect(
        p.stockpile.quantityOf(CommodityCatalog.paper.id),
        2,
        reason: '10 paper deducted per SPEC § Recruiting cost table',
      );
      expect(
        p.treasury,
        200,
        reason: '1000 ducats deducted per SPEC § Recruiting cost table',
      );
    });

    test('master recruit with required tech locked is silently skipped '
        '(#2692 S9 tech-gate coverage)', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 12}),
            workerPool: const WorkerPool(peasants: 1),
            treasury: 1200,
            techUnlocked: const {
              kTechIdMasterArtisans: true,
              // kTechIdHatProduction intentionally missing.
            },
          ),
        ],
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.master)],
        },
      );

      final result = applyBuildAndWorkOrders(game, orders);

      final p = result.players.single;
      expect(p.workerPool.peasants, 1, reason: 'peasant not consumed');
      expect(p.workerPool.masters, 0, reason: 'master not added');
      expect(
        p.stockpile.quantityOf(CommodityCatalog.paper.id),
        12,
        reason: 'no paper deducted',
      );
      expect(p.treasury, 1200, reason: 'no treasury deducted');
    });

    test('later recruit order observes the running state of earlier accepted '
        'order in the same submission list (#2692 S9 ordering semantics)', () {
      // First order recruits a peasant (no peasant required); second order then
      // trains that newly recruited peasant into an apprentice. The resolver
      // must thread the running WorkerPool/Stockpile/Treasury across orders.
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 2,
                CommodityCatalog.paper.id: 2,
              },
            ),
            workerPool: const WorkerPool(peasants: 0),
            treasury: 200,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
        ],
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [
            RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ],
        },
      );

      final result = applyBuildAndWorkOrders(game, orders);

      final p = result.players.single;
      expect(
        p.workerPool.peasants,
        0,
        reason:
            'recruited peasant immediately consumed by the apprentice train',
      );
      expect(p.workerPool.apprentices, 1, reason: 'one apprentice added');
      expect(
        p.stockpile.quantityOf(CommodityCatalog.fabric.id),
        0,
        reason: 'peasant recruit consumed 2 fabric',
      );
      expect(
        p.stockpile.quantityOf(CommodityCatalog.paper.id),
        0,
        reason: 'apprentice train consumed 2 paper',
      );
      expect(p.treasury, 0, reason: 'apprentice train consumed 200 ducats');
    });

    test('middle order silently skips when peasants are exhausted; later '
        'orders still resolve against the running state (#2692 S9; AC #4 '
        'resolver behavior)', () {
      // Submission order: [apprentice, apprentice, peasant]. With only 1
      // peasant in the pool, the first apprentice consumes it; the second
      // apprentice is silently skipped (`Insufficient workers`); the trailing
      // peasant recruit still resolves because it does not consume a peasant.
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 4,
                CommodityCatalog.paper.id: 4,
              },
            ),
            workerPool: const WorkerPool(peasants: 1),
            treasury: 400,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
        ],
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            RecruitWorkerOrder(targetTier: WorkerTier.peasant),
          ],
        },
      );

      final result = applyBuildAndWorkOrders(game, orders);

      final p = result.players.single;
      expect(
        p.workerPool.peasants,
        1,
        reason: 'apprentice consumed initial peasant; peasant recruit added 1',
      );
      expect(
        p.workerPool.apprentices,
        1,
        reason: 'only the first apprentice train fired; second skipped',
      );
      expect(
        p.stockpile.quantityOf(CommodityCatalog.paper.id),
        2,
        reason: 'one apprentice consumed 2 paper; second order did not',
      );
      expect(
        p.stockpile.quantityOf(CommodityCatalog.fabric.id),
        2,
        reason: 'trailing peasant recruit still consumed 2 fabric',
      );
      expect(
        p.treasury,
        200,
        reason: 'only one apprentice train deducted treasury',
      );
    });

    test('per-player order lists apply in isolation (#2692 S9 multi-player '
        'pin)', () {
      // p1 and p2 each queue one apprentice train. Their treasury, stockpile,
      // and worker pool deductions stay scoped to the order owner.
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'A',
            isHuman: true,
            stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 4}),
            workerPool: const WorkerPool(peasants: 2),
            treasury: 300,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
          Player(
            id: 'p2',
            displayName: 'B',
            isHuman: false,
            stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 4}),
            workerPool: const WorkerPool(peasants: 2),
            treasury: 300,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
        ],
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
          'p2': const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        },
      );

      final result = applyBuildAndWorkOrders(game, orders);

      final p1 = result.players.firstWhere((p) => p.id == 'p1');
      final p2 = result.players.firstWhere((p) => p.id == 'p2');
      expect(p1.workerPool.peasants, 1);
      expect(p1.workerPool.apprentices, 1);
      expect(p1.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
      expect(p1.treasury, 100);
      expect(p2.workerPool.peasants, 1);
      expect(p2.workerPool.apprentices, 1);
      expect(p2.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
      expect(p2.treasury, 100);
    });
  });
}
