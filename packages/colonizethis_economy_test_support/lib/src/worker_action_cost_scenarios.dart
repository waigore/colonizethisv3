// Table-driven worker recruit/train cost scenarios (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';

/// One row in a worker-action-cost scenario table.
class WorkerActionCostScenario {
  const WorkerActionCostScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  final String label;
  final void Function() run;
  final String? refs;
}

/// Runs [scenario] (setup + assertions live in [WorkerActionCostScenario.run]).
void runWorkerActionCostScenario(WorkerActionCostScenario scenario) {
  scenario.run();
}

Player _playerWithTech(Map<String, bool>? tech) =>
    corePlayer(techUnlocked: tech ?? const {});

const _apprenticeTech = <String, bool>{
  kTechIdApprenticeWorkers: true,
  kTechIdSugarRefining: true,
};
const _journeymanTech = <String, bool>{
  kTechIdTrainedJourneymen: true,
  kTechIdCigarProduction: true,
};
const _masterTech = <String, bool>{
  kTechIdMasterArtisans: true,
  kTechIdHatProduction: true,
};

/// Canonical scenarios for [canAffordRecruitWorker].
List<WorkerActionCostScenario> canAffordRecruitWorkerScenarios() => [
  WorkerActionCostScenario(
    label: 'peasant recruit needs only fabric (no tech, no peasant, no treasury)',
    run: () {
      final stockpile = stockpileWithDeltas({
        CommodityCatalog.fabric.id: 2,
      });
      final result = canAffordRecruitWorker(
        _playerWithTech(null),
        const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
        WorkerPool.empty,
        stockpile,
        0,
      );
      expect(result.canAfford, isTrue);
      expect(result.reason, isNull);
    },
  ),
  WorkerActionCostScenario(
    label: 'peasant recruit rejected when fabric below cost',
    run: () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.fabric.id,
        1,
      );
      final result = canAffordRecruitWorker(
        _playerWithTech(null),
        const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
        WorkerPool.empty,
        stockpile,
        0,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, kRecruitWorkerInsufficientMaterials);
    },
  ),
  WorkerActionCostScenario(
    label: 'apprentice rejected with tech-locked when required tech missing',
    run: () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        10,
      );
      final result = canAffordRecruitWorker(
        _playerWithTech(const {kTechIdApprenticeWorkers: true}),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        const WorkerPool(peasants: 1),
        stockpile,
        1000,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, kRecruitWorkerTechLocked);
    },
  ),
  WorkerActionCostScenario(
    label: 'tech gate is checked before the worker gate (canonical order)',
    run: () {
      final result = canAffordRecruitWorker(
        _playerWithTech(null),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        WorkerPool.empty,
        const Stockpile(),
        0,
      );
      expect(result.reason, kRecruitWorkerTechLocked);
    },
  ),
  WorkerActionCostScenario(
    label: 'apprentice rejected when no peasant available to consume',
    run: () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        10,
      );
      final result = canAffordRecruitWorker(
        _playerWithTech(_apprenticeTech),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        WorkerPool.empty,
        stockpile,
        1000,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, kRecruitWorkerInsufficientWorkers);
    },
  ),
  WorkerActionCostScenario(
    label: 'apprentice rejected when treasury below cost',
    run: () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        10,
      );
      final result = canAffordRecruitWorker(
        _playerWithTech(_apprenticeTech),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        const WorkerPool(peasants: 1),
        stockpile,
        199,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, kRecruitWorkerInsufficientTreasury);
    },
  ),
  WorkerActionCostScenario(
    label: 'apprentice rejected when materials below cost',
    run: () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        1,
      );
      final result = canAffordRecruitWorker(
        _playerWithTech(_apprenticeTech),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        const WorkerPool(peasants: 1),
        stockpile,
        1000,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, kRecruitWorkerInsufficientMaterials);
    },
  ),
  WorkerActionCostScenario(
    label:
        'apprentice allowed when tech, peasant, treasury, and materials meet '
        'the cost row exactly',
    run: () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        2,
      );
      final result = canAffordRecruitWorker(
        _playerWithTech(_apprenticeTech),
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        const WorkerPool(peasants: 1),
        stockpile,
        200,
      );
      expect(result.canAfford, isTrue);
      expect(result.reason, isNull);
    },
  ),
];

/// Canonical scenarios for [applyRecruitWorkerCostDeduction].
List<WorkerActionCostScenario> applyRecruitWorkerCostDeductionScenarios() => [
  WorkerActionCostScenario(
    label: 'peasant recruit adds a peasant and deducts only fabric',
    run: () {
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
    },
  ),
  WorkerActionCostScenario(
    label: 'apprentice train consumes a peasant, paper, and treasury',
    run: () {
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
    },
  ),
  WorkerActionCostScenario(
    label: 'journeyman train consumes a peasant, paper, and treasury',
    run: () {
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
    },
  ),
  WorkerActionCostScenario(
    label: 'master train consumes a peasant, paper, and treasury',
    run: () {
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
    },
  ),
  WorkerActionCostScenario(
    label: 'consistency: apprentice tech is honoured across both helpers',
    run: () {
      const order = RecruitWorkerOrder(targetTier: WorkerTier.apprentice);
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        2,
      );
      expect(
        canAffordRecruitWorker(
          _playerWithTech(_journeymanTech),
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
          _playerWithTech(_masterTech),
          order,
          const WorkerPool(peasants: 1),
          stockpile,
          200,
        ).reason,
        kRecruitWorkerTechLocked,
        reason: 'master tech does not satisfy the apprentice gate',
      );
    },
  ),
];
