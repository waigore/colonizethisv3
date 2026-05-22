/// Resolver-level coverage for `runWorkerPoolPhase` inside the
/// Build / work phase pipeline (Refs #2692 S4) — tier ACs and rejection
/// cases.
///
/// Verifies that `applyBuildAndWorkOrders` resolves queued
/// [RecruitWorkerOrder] entries per
/// `SPEC/game/workers-and-population.md` § Recruiting, Training, and
/// Disbanding (cost table, tech gates).
///
/// Phase ordering / determinism / multi-player isolation live in
/// `run_worker_pool_phase_ordering_test.dart`. Shared fixtures live in
/// `run_worker_pool_phase_test_support.dart`.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'run_worker_pool_phase_test_support.dart';

void main() {
  suppressLogsForTests();

  group('runWorkerPoolPhase via applyBuildAndWorkOrders (Refs #2692 S4)', () {
    test('no recruit orders -> game unchanged (no-op short-circuit)', () {
      final game = gameWithPlayer(
        workerPool: const WorkerPool(peasants: 1),
        stockpile: stockpileOf(fabric: 2),
        treasury: 0,
      );

      final next = applyBuildAndWorkOrders(game, const Orders());

      expect(identical(next, game), isTrue);
    });

    test(
      'AC: peasant recruit deducts 2 fabric and increments peasants by 1',
      () {
        final game = gameWithPlayer(
          workerPool: const WorkerPool(peasants: 0),
          stockpile: stockpileOf(fabric: 2),
          treasury: 0,
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            recruitTestPlayerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final player = playerOf(next, recruitTestPlayerId);

        expect(player.workerPool.peasants, 1);
        expect(player.stockpile.quantityOf(CommodityCatalog.fabric.id), 0);
        expect(player.treasury, 0);
      },
    );

    test(
      'AC: apprentice recruit deducts 200 ducats + 2 paper, consumes 1 peasant',
      () {
        final game = gameWithPlayer(
          workerPool: const WorkerPool(peasants: 1),
          stockpile: stockpileOf(paper: 2),
          treasury: 200,
          techUnlocked: const {
            kTechIdApprenticeWorkers: true,
            kTechIdSugarRefining: true,
          },
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            recruitTestPlayerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final player = playerOf(next, recruitTestPlayerId);

        expect(player.workerPool.peasants, 0);
        expect(player.workerPool.apprentices, 1);
        expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 0);
        expect(player.treasury, 0);
      },
    );

    test(
      'AC: journeyman recruit deducts 500 ducats + 5 paper, consumes 1 peasant',
      () {
        final game = gameWithPlayer(
          workerPool: const WorkerPool(peasants: 1),
          stockpile: stockpileOf(paper: 5),
          treasury: 500,
          techUnlocked: const {
            kTechIdTrainedJourneymen: true,
            kTechIdCigarProduction: true,
          },
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            recruitTestPlayerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final player = playerOf(next, recruitTestPlayerId);

        expect(player.workerPool.peasants, 0);
        expect(player.workerPool.journeymen, 1);
        expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 0);
        expect(player.treasury, 0);
      },
    );

    test(
      'AC: master recruit deducts 1000 ducats + 10 paper, consumes 1 peasant',
      () {
        final game = gameWithPlayer(
          workerPool: const WorkerPool(peasants: 1),
          stockpile: stockpileOf(paper: 10),
          treasury: 1000,
          techUnlocked: const {
            kTechIdMasterArtisans: true,
            kTechIdHatProduction: true,
          },
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            recruitTestPlayerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.master),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final player = playerOf(next, recruitTestPlayerId);

        expect(player.workerPool.peasants, 0);
        expect(player.workerPool.masters, 1);
        expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 0);
        expect(player.treasury, 0);
      },
    );

    test('Tech-locked trained recruit is skipped (no state mutation)', () {
      final game = gameWithPlayer(
        workerPool: const WorkerPool(peasants: 1),
        stockpile: stockpileOf(paper: 2),
        treasury: 200,
        // apprentice_workers + sugar_refining NOT unlocked
        techUnlocked: const {},
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          recruitTestPlayerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final player = playerOf(next, recruitTestPlayerId);

      expect(player.workerPool.peasants, 1);
      expect(player.workerPool.apprentices, 0);
      expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
      expect(player.treasury, 200);
    });

    test('Insufficient peasant (consumes flag) -> recruit skipped', () {
      final game = gameWithPlayer(
        workerPool: const WorkerPool(peasants: 0),
        stockpile: stockpileOf(paper: 2),
        treasury: 200,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          recruitTestPlayerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final player = playerOf(next, recruitTestPlayerId);

      expect(player.workerPool.peasants, 0);
      expect(player.workerPool.apprentices, 0);
      expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
      expect(player.treasury, 200);
    });

    test('Insufficient material -> recruit skipped (no partial deduction)', () {
      final game = gameWithPlayer(
        workerPool: const WorkerPool(peasants: 0),
        stockpile: stockpileOf(fabric: 1),
        treasury: 0,
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          recruitTestPlayerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.peasant),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final player = playerOf(next, recruitTestPlayerId);

      expect(player.workerPool.peasants, 0);
      expect(player.stockpile.quantityOf(CommodityCatalog.fabric.id), 1);
    });

    test('Insufficient treasury -> trained recruit skipped', () {
      final game = gameWithPlayer(
        workerPool: const WorkerPool(peasants: 1),
        stockpile: stockpileOf(paper: 2),
        treasury: 199,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          recruitTestPlayerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final player = playerOf(next, recruitTestPlayerId);

      expect(player.workerPool.peasants, 1);
      expect(player.workerPool.apprentices, 0);
      expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
      expect(player.treasury, 199);
    });
  });
}
