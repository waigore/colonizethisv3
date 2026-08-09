// Table-driven unit tests for worker recruit/train costs (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
Player _playerWithTech(Map<String, bool>? tech) => corePlayer(techUnlocked: tech ?? const {});

const _journeymanTech = <String, bool>{kTechIdTrainedJourneymen: true, kTechIdCigarProduction: true};
const _masterTech = <String, bool>{kTechIdMasterArtisans: true, kTechIdHatProduction: true};

void runCanAffordRecruitWorkerExpectation(CanAffordRecruitWorkerPins pins) {
  final stockpile = stockpileWithDeltas(pins.stockpileDeltas);
  final result = canAffordRecruitWorker(_playerWithTech(pins.tech), RecruitWorkerOrder(targetTier: pins.targetTier), pins.workers, stockpile, pins.treasury);
  expect(result.canAfford, pins.expectedCanAfford);
  expect(result.reason, pins.expectedReason);
}

void runApplyRecruitWorkerCostExpectation(ApplyRecruitWorkerCostPins pins) {
  final stockpile = stockpileWithDeltas(pins.stockpileDeltas);
  final next = applyRecruitWorkerCostDeduction(RecruitWorkerOrder(targetTier: pins.targetTier), pins.initialWorkers, stockpile, pins.treasury);
  expect(next.workers.peasants, pins.expectedWorkers.peasants);
  expect(next.workers.apprentices, pins.expectedWorkers.apprentices);
  expect(next.workers.journeymen, pins.expectedWorkers.journeymen);
  expect(next.workers.masters, pins.expectedWorkers.masters);
  for (final entry in pins.expectedStockpileQuantities.entries) {
    expect(next.stockpile.quantityOf(entry.key), entry.value);
  }
  expect(next.treasury, pins.expectedTreasury);
}

void runApprenticeTechConsistencyExpectation() {
  const order = RecruitWorkerOrder(targetTier: WorkerTier.apprentice);
  final stockpile = const Stockpile().applyDelta('paper', 2);
  expect(canAffordRecruitWorker(_playerWithTech(_journeymanTech), order, const WorkerPool(peasants: 1), stockpile, 200).reason, kRecruitWorkerTechLocked, reason: 'journeyman tech does not satisfy the apprentice gate');
  expect(canAffordRecruitWorker(_playerWithTech(_masterTech), order, const WorkerPool(peasants: 1), stockpile, 200).reason, kRecruitWorkerTechLocked, reason: 'master tech does not satisfy the apprentice gate');
}

void runWorkerActionCostScenario(WorkerActionCostScenario scenario) {
  final canAfford = scenario.canAfford;
  if (canAfford != null) {
    runCanAffordRecruitWorkerExpectation(canAfford);
    return;
  }
  final applyCost = scenario.applyCost;
  if (applyCost != null) {
    runApplyRecruitWorkerCostExpectation(applyCost);
    return;
  }
  runApprenticeTechConsistencyExpectation();
}
// dart format on

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
  group('canAffordRecruitWorker', () {
    runLabeledScenarios(canAffordRecruitWorkerScenarios(), (scenario) {
      runWorkerActionCostScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('applyRecruitWorkerCostDeduction', () {
    runLabeledScenarios(applyRecruitWorkerCostDeductionScenarios(), (scenario) {
      runWorkerActionCostScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
