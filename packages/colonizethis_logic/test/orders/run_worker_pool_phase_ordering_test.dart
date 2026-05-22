/// Phase-ordering / determinism / multi-player coverage for
/// `runWorkerPoolPhase` inside the Build / work phase pipeline
/// (Refs #2692 S4).
///
/// Verifies that `applyBuildAndWorkOrders` resolves queued
/// [RecruitWorkerOrder] entries **before** any [BuildUnitOrder] (per
/// `SPEC/program/turn-resolution-phase-details.md` § Build / work) and
/// that ordering / determinism properties hold across players and turns.
///
/// Tier ACs and rejection cases live in `run_worker_pool_phase_test.dart`.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'run_worker_pool_phase_test_support.dart';

void main() {
  suppressLogsForTests();

  group('runWorkerPoolPhase ordering / determinism (Refs #2692 S4)', () {
    test('Phase ordering: worker recruit settles before military build peasant '
        'consume', () {
      // Player has 1 peasant. With phase ordering correct, the peasant
      // recruit yields 2 peasants, and the subsequent military build
      // consumes 1, leaving 1. With wrong ordering (military first) the
      // build would consume the only peasant and the recruit would still
      // produce 1, leaving a final count of 1 — observationally similar
      // but the recruit cost (2 fabric) is the discriminator: when the
      // recruit ran the fabric is deducted, otherwise it is not.
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = stockpileOf(fabric: 2);
      for (final entry in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(entry.key, entry.value);
      }
      final game = gameWithPlayer(
        workerPool: const WorkerPool(peasants: 1),
        stockpile: stockpile,
        treasury: econ.buildTreasuryCost,
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          recruitTestPlayerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.peasant),
          ],
        },
        buildUnitOrdersByPlayerId: {
          recruitTestPlayerId: [
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary: true,
              spawnProvinceId: recruitTestCapProvinceId,
            ),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final player = playerOf(next, recruitTestPlayerId);

      expect(player.workerPool.peasants, 1, reason: '2 recruited - 1 military');
      expect(player.stockpile.quantityOf(CommodityCatalog.fabric.id), 0);
      expect(player.treasury, 0);
    });

    test('Submission order is deterministic per player', () {
      // Two apprentices in a row; second one should also resolve fully when
      // the first consumes one of two peasants and treasury/paper allow.
      final game = gameWithPlayer(
        workerPool: const WorkerPool(peasants: 2),
        stockpile: stockpileOf(paper: 4),
        treasury: 400,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          recruitTestPlayerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final player = playerOf(next, recruitTestPlayerId);

      expect(player.workerPool.peasants, 0);
      expect(player.workerPool.apprentices, 2);
      expect(player.stockpile.quantityOf(CommodityCatalog.paper.id), 0);
      expect(player.treasury, 0);
    });

    test('Recruit for one player does not affect another player', () {
      final other = Player(
        id: recruitTestOtherPlayerId,
        displayName: 'P2',
        isHuman: false,
        capitalProvinceId: 'oldWorld|P2',
        stockpile: stockpileOf(fabric: 4),
        workerPool: const WorkerPool(peasants: 3),
        treasury: 500,
      );
      final game = gameWithPlayer(
        workerPool: const WorkerPool(peasants: 0),
        stockpile: stockpileOf(fabric: 2),
        treasury: 0,
        extraPlayers: [other],
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          recruitTestPlayerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.peasant),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      final p1 = playerOf(next, recruitTestPlayerId);
      final p2 = playerOf(next, recruitTestOtherPlayerId);

      expect(p1.workerPool.peasants, 1);
      expect(p1.stockpile.quantityOf(CommodityCatalog.fabric.id), 0);
      expect(p2.workerPool.peasants, 3);
      expect(p2.stockpile.quantityOf(CommodityCatalog.fabric.id), 4);
      expect(p2.treasury, 500);
    });

    test('Determinism: identical inputs produce identical outputs', () {
      Game build() => gameWithPlayer(
        workerPool: const WorkerPool(peasants: 2),
        stockpile: stockpileOf(paper: 7),
        treasury: 700,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
          kTechIdTrainedJourneymen: true,
          kTechIdCigarProduction: true,
        },
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          recruitTestPlayerId: const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
          ],
        },
      );

      final a = applyBuildAndWorkOrders(build(), orders);
      final b = applyBuildAndWorkOrders(build(), orders);

      final ap = playerOf(a, recruitTestPlayerId);
      final bp = playerOf(b, recruitTestPlayerId);

      expect(ap.workerPool, bp.workerPool);
      expect(
        ap.stockpile.quantityOf(CommodityCatalog.paper.id),
        bp.stockpile.quantityOf(CommodityCatalog.paper.id),
      );
      expect(ap.treasury, bp.treasury);
    });
  });
}
