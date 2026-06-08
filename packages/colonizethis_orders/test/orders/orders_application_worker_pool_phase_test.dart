import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Build / work resolution applies RecruitWorkerOrder mutations to the player
/// snapshot before BuildUnitOrder runs (#2692 S4; SPEC/program/turn-resolution-phase-details.md).
///
/// S9 tier / ordering / multi-player coverage lives in the sibling file
/// `orders_application_worker_pool_phase_s9_test.dart` (split to honor the
/// colonizethis_logic 400-line per-test-file policy enforced by
/// `repo.logic_test_file_size`).
void main() {
  group('applyBuildAndWorkOrders worker pool sub-phase (#2692 S4)', () {
    test(
      'accepted recruit peasant order adds 1 peasant and deducts fabric',
      () {
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
              stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 3}),
              workerPool: const WorkerPool(peasants: 0),
            ),
          ],
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.peasant)],
          },
        );

        final result = applyBuildAndWorkOrders(game, orders);

        final p = result.players.single;
        expect(p.workerPool.peasants, 1);
        expect(p.stockpile.quantityOf(CommodityCatalog.fabric.id), 1);
        expect(p.treasury, 0);
      },
    );

    test('accepted apprentice train consumes peasant, paper, and treasury', () {
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
            stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
            workerPool: const WorkerPool(peasants: 3),
            treasury: 500,
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
        },
      );

      final result = applyBuildAndWorkOrders(game, orders);

      final p = result.players.single;
      expect(p.workerPool.peasants, 2);
      expect(p.workerPool.apprentices, 1);
      expect(p.stockpile.quantityOf(CommodityCatalog.paper.id), 3);
      expect(p.treasury, 300);
    });

    test('recruit that fails affordability checks does not mutate the player '
        '(no partial deduction)', () {
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
            stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
            workerPool: const WorkerPool(peasants: 3),
            treasury: 100, // insufficient for apprentice (200)
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
        },
      );

      final result = applyBuildAndWorkOrders(game, orders);

      final p = result.players.single;
      expect(p.workerPool.peasants, 3);
      expect(p.workerPool.apprentices, 0);
      expect(p.stockpile.quantityOf(CommodityCatalog.paper.id), 5);
      expect(p.treasury, 100);
    });
  });
}
