// Table-driven worker recruit/train cost scenarios (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'worker_action_cost_expectations.dart';

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

/// Canonical scenarios for [canAffordRecruitWorker].
List<WorkerActionCostScenario> canAffordRecruitWorkerScenarios() => [
  canAffordRecruitWorkerScenario(
    label:
        'peasant recruit needs only fabric (no tech, no peasant, no treasury)',
    pins: (
      tech: null,
      targetTier: WorkerTier.peasant,
      workers: WorkerPool.empty,
      stockpileDeltas: {'fabric': 2},
      treasury: 0,
      expectedCanAfford: true,
      expectedReason: null,
    ),
  ),
  canAffordRecruitWorkerScenario(
    label: 'peasant recruit rejected when fabric below cost',
    pins: (
      tech: null,
      targetTier: WorkerTier.peasant,
      workers: WorkerPool.empty,
      stockpileDeltas: {'fabric': 1},
      treasury: 0,
      expectedCanAfford: false,
      expectedReason: kRecruitWorkerInsufficientMaterials,
    ),
  ),
  canAffordRecruitWorkerScenario(
    label: 'apprentice rejected with tech-locked when required tech missing',
    pins: (
      tech: {kTechIdApprenticeWorkers: true},
      targetTier: WorkerTier.apprentice,
      workers: const WorkerPool(peasants: 1),
      stockpileDeltas: {'paper': 10},
      treasury: 1000,
      expectedCanAfford: false,
      expectedReason: kRecruitWorkerTechLocked,
    ),
  ),
  canAffordRecruitWorkerScenario(
    label: 'tech gate is checked before the worker gate (canonical order)',
    pins: (
      tech: null,
      targetTier: WorkerTier.apprentice,
      workers: WorkerPool.empty,
      stockpileDeltas: {},
      treasury: 0,
      expectedCanAfford: false,
      expectedReason: kRecruitWorkerTechLocked,
    ),
  ),
  canAffordRecruitWorkerScenario(
    label: 'apprentice rejected when no peasant available to consume',
    pins: (
      tech: {kTechIdApprenticeWorkers: true, kTechIdSugarRefining: true},
      targetTier: WorkerTier.apprentice,
      workers: WorkerPool.empty,
      stockpileDeltas: {'paper': 10},
      treasury: 1000,
      expectedCanAfford: false,
      expectedReason: kRecruitWorkerInsufficientWorkers,
    ),
  ),
  canAffordRecruitWorkerScenario(
    label: 'apprentice rejected when treasury below cost',
    pins: (
      tech: {kTechIdApprenticeWorkers: true, kTechIdSugarRefining: true},
      targetTier: WorkerTier.apprentice,
      workers: const WorkerPool(peasants: 1),
      stockpileDeltas: {'paper': 10},
      treasury: 199,
      expectedCanAfford: false,
      expectedReason: kRecruitWorkerInsufficientTreasury,
    ),
  ),
  canAffordRecruitWorkerScenario(
    label: 'apprentice rejected when materials below cost',
    pins: (
      tech: {kTechIdApprenticeWorkers: true, kTechIdSugarRefining: true},
      targetTier: WorkerTier.apprentice,
      workers: const WorkerPool(peasants: 1),
      stockpileDeltas: {'paper': 1},
      treasury: 1000,
      expectedCanAfford: false,
      expectedReason: kRecruitWorkerInsufficientMaterials,
    ),
  ),
  canAffordRecruitWorkerScenario(
    label:
        'apprentice allowed when tech, peasant, treasury, and materials meet '
        'the cost row exactly',
    pins: (
      tech: {kTechIdApprenticeWorkers: true, kTechIdSugarRefining: true},
      targetTier: WorkerTier.apprentice,
      workers: const WorkerPool(peasants: 1),
      stockpileDeltas: {'paper': 2},
      treasury: 200,
      expectedCanAfford: true,
      expectedReason: null,
    ),
  ),
];

/// Canonical scenarios for [applyRecruitWorkerCostDeduction].
List<WorkerActionCostScenario> applyRecruitWorkerCostDeductionScenarios() => [
  applyRecruitWorkerCostScenario(
    label: 'peasant recruit adds a peasant and deducts only fabric',
    pins: (
      targetTier: WorkerTier.peasant,
      initialWorkers: const WorkerPool(peasants: 3),
      stockpileDeltas: {'fabric': 5},
      treasury: 100,
      expectedWorkers: const WorkerPool(peasants: 4),
      expectedStockpileQuantities: {'fabric': 3},
      expectedTreasury: 100,
    ),
  ),
  applyRecruitWorkerCostScenario(
    label: 'apprentice train consumes a peasant, paper, and treasury',
    pins: (
      targetTier: WorkerTier.apprentice,
      initialWorkers: const WorkerPool(peasants: 2, apprentices: 1),
      stockpileDeltas: {'paper': 5},
      treasury: 1000,
      expectedWorkers: const WorkerPool(peasants: 1, apprentices: 2),
      expectedStockpileQuantities: {'paper': 3},
      expectedTreasury: 800,
    ),
  ),
  applyRecruitWorkerCostScenario(
    label: 'journeyman train consumes a peasant, paper, and treasury',
    pins: (
      targetTier: WorkerTier.journeyman,
      initialWorkers: const WorkerPool(peasants: 1, journeymen: 4),
      stockpileDeltas: {'paper': 10},
      treasury: 1000,
      expectedWorkers: const WorkerPool(journeymen: 5),
      expectedStockpileQuantities: {'paper': 5},
      expectedTreasury: 500,
    ),
  ),
  applyRecruitWorkerCostScenario(
    label: 'master train consumes a peasant, paper, and treasury',
    pins: (
      targetTier: WorkerTier.master,
      initialWorkers: const WorkerPool(peasants: 1),
      stockpileDeltas: {'paper': 12},
      treasury: 1000,
      expectedWorkers: const WorkerPool(masters: 1),
      expectedStockpileQuantities: {'paper': 2},
      expectedTreasury: 0,
    ),
  ),
  apprenticeTechConsistencyScenario(
    label: 'consistency: apprentice tech is honoured across both helpers',
  ),
];
