import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Unit tests for `lib/src/economy/worker_action_cost.dart`.
///
/// Pins the shared recruit/train affordability gate
/// (`canAffordRecruitWorker`) and the cost deduction
/// (`applyRecruitWorkerCostDeduction`) used by submission, validation,
/// resolution, and projection so the single source of truth keeps the
/// canonical rejection order and per-tier deltas.
///
/// SPEC/game/workers-and-population.md § Recruiting, Training, and Disbanding.
/// Tied to the colonizethis_economy leaf-package coverage gate (Refs #3290).
void main() {
  Player playerWithTech(Map<String, bool>? tech) =>
      corePlayer(techUnlocked: tech ?? const {});

  const apprenticeTech = <String, bool>{
    kTechIdApprenticeWorkers: true,
    kTechIdSugarRefining: true,
  };
  const journeymanTech = <String, bool>{
    kTechIdTrainedJourneymen: true,
    kTechIdCigarProduction: true,
  };
  const masterTech = <String, bool>{
    kTechIdMasterArtisans: true,
    kTechIdHatProduction: true,
  };

  group('canAffordRecruitWorker', () {
    test(
      'peasant recruit needs only fabric (no tech, no peasant, no treasury)',
      () {
        final stockpile = stockpileWithDeltas({
          CommodityCatalog.fabric.id: 2,
        });

        final result = canAffordRecruitWorker(
          playerWithTech(null),
          const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
          WorkerPool.empty,
          stockpile,
          0,
        );

        expect(result.canAfford, isTrue);
        expect(result.reason, isNull);
      },
    );

    test('peasant recruit rejected when fabric below cost', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.fabric.id,
        1,
      );

      final result = canAffordRecruitWorker(
        playerWithTech(null),
        const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
        WorkerPool.empty,
        stockpile,
        0,
      );

      expect(result.canAfford, isFalse);
      expect(result.reason, kRecruitWorkerInsufficientMaterials);
    });

    test('apprentice rejected with tech-locked when required tech missing', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        10,
      );

      final result = canAffordRecruitWorker(
        playerWithTech(const {kTechIdApprenticeWorkers: true}),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        const WorkerPool(peasants: 1),
        stockpile,
        1000,
      );

      expect(result.canAfford, isFalse);
      expect(result.reason, kRecruitWorkerTechLocked);
    });

    test('tech gate is checked before the worker gate (canonical order)', () {
      final result = canAffordRecruitWorker(
        playerWithTech(null),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        WorkerPool.empty,
        const Stockpile(),
        0,
      );

      expect(result.reason, kRecruitWorkerTechLocked);
    });

    test('apprentice rejected when no peasant available to consume', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        10,
      );

      final result = canAffordRecruitWorker(
        playerWithTech(apprenticeTech),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        WorkerPool.empty,
        stockpile,
        1000,
      );

      expect(result.canAfford, isFalse);
      expect(result.reason, kRecruitWorkerInsufficientWorkers);
    });

    test('apprentice rejected when treasury below cost', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        10,
      );

      final result = canAffordRecruitWorker(
        playerWithTech(apprenticeTech),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        const WorkerPool(peasants: 1),
        stockpile,
        199,
      );

      expect(result.canAfford, isFalse);
      expect(result.reason, kRecruitWorkerInsufficientTreasury);
    });

    test('apprentice rejected when materials below cost', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        1,
      );

      final result = canAffordRecruitWorker(
        playerWithTech(apprenticeTech),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        const WorkerPool(peasants: 1),
        stockpile,
        1000,
      );

      expect(result.canAfford, isFalse);
      expect(result.reason, kRecruitWorkerInsufficientMaterials);
    });

    test('apprentice allowed when tech, peasant, treasury, and materials meet '
        'the cost row exactly', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        2,
      );

      final result = canAffordRecruitWorker(
        playerWithTech(apprenticeTech),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        const WorkerPool(peasants: 1),
        stockpile,
        200,
      );

      expect(result.canAfford, isTrue);
      expect(result.reason, isNull);
    });
  });

  group('applyRecruitWorkerCostDeduction', () {
    test('peasant recruit adds a peasant and deducts only fabric', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.fabric.id,
        5,
      );

      final next = applyRecruitWorkerCostDeduction(
        const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
        const WorkerPool(peasants: 3),
        stockpile,
        100,
      );

      expect(next.workers.peasants, 4);
      expect(next.stockpile.quantityOf(CommodityCatalog.fabric.id), 3);
      expect(next.treasury, 100);
    });

    test('apprentice train consumes a peasant, paper, and treasury', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        5,
      );

      final next = applyRecruitWorkerCostDeduction(
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        const WorkerPool(peasants: 2, apprentices: 1),
        stockpile,
        1000,
      );

      expect(next.workers.peasants, 1);
      expect(next.workers.apprentices, 2);
      expect(next.stockpile.quantityOf(CommodityCatalog.paper.id), 3);
      expect(next.treasury, 800);
    });

    test('journeyman train consumes a peasant, paper, and treasury', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        10,
      );

      final next = applyRecruitWorkerCostDeduction(
        const RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
        const WorkerPool(peasants: 1, journeymen: 4),
        stockpile,
        1000,
      );

      expect(next.workers.peasants, 0);
      expect(next.workers.journeymen, 5);
      expect(next.stockpile.quantityOf(CommodityCatalog.paper.id), 5);
      expect(next.treasury, 500);
    });

    test('master train consumes a peasant, paper, and treasury', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        12,
      );

      final next = applyRecruitWorkerCostDeduction(
        const RecruitWorkerOrder(targetTier: WorkerTier.master),
        const WorkerPool(peasants: 1, masters: 0),
        stockpile,
        1000,
      );

      expect(next.workers.peasants, 0);
      expect(next.workers.masters, 1);
      expect(next.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
      expect(next.treasury, 0);
    });

    test('consistency: apprentice tech is honoured across both helpers', () {
      const order = RecruitWorkerOrder(targetTier: WorkerTier.apprentice);
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        2,
      );

      expect(
        canAffordRecruitWorker(
          playerWithTech(journeymanTech),
          order,
          const WorkerPool(peasants: 1),
          stockpile,
          200,
        ).reason,
        kRecruitWorkerTechLocked,
        reason: 'journeyman tech does not satisfy the apprentice gate',
      );
      expect(
        canAffordRecruitWorker(
          playerWithTech(masterTech),
          order,
          const WorkerPool(peasants: 1),
          stockpile,
          200,
        ).reason,
        kRecruitWorkerTechLocked,
        reason: 'master tech does not satisfy the apprentice gate',
      );
    });
  });
}
