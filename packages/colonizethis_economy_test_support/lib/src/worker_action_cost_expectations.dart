// dart format off
// Compact worker recruit/train cost assertions (Refs #3939 phase 3 slice 36).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'worker_action_cost_scenarios.dart';

Player _playerWithTech(Map<String, bool>? tech) => corePlayer(techUnlocked: tech ?? const {});

const _journeymanTech = <String, bool>{kTechIdTrainedJourneymen: true, kTechIdCigarProduction: true};
const _masterTech = <String, bool>{kTechIdMasterArtisans: true, kTechIdHatProduction: true};

/// Pins for [canAffordRecruitWorker] rows.
typedef CanAffordRecruitWorkerPins = ({Map<String, bool>? tech, WorkerTier targetTier, WorkerPool workers, Map<String, int> stockpileDeltas, int treasury, bool expectedCanAfford, String? expectedReason});

void runCanAffordRecruitWorkerExpectation(CanAffordRecruitWorkerPins pins) {
  final stockpile = stockpileWithDeltas(pins.stockpileDeltas);
  final result = canAffordRecruitWorker(_playerWithTech(pins.tech), RecruitWorkerOrder(targetTier: pins.targetTier), pins.workers, stockpile, pins.treasury);
  expect(result.canAfford, pins.expectedCanAfford);
  expect(result.reason, pins.expectedReason);
}

WorkerActionCostScenario canAffordRecruitWorkerScenario({required String label, required CanAffordRecruitWorkerPins pins, String? refs}) => (label: label, run: () => runCanAffordRecruitWorkerExpectation(pins), refs: refs);

/// Pins for [applyRecruitWorkerCostDeduction] rows.
typedef ApplyRecruitWorkerCostPins = ({WorkerTier targetTier, WorkerPool initialWorkers, Map<String, int> stockpileDeltas, int treasury, WorkerPool expectedWorkers, Map<String, int> expectedStockpileQuantities, int expectedTreasury});

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

WorkerActionCostScenario applyRecruitWorkerCostScenario({required String label, required ApplyRecruitWorkerCostPins pins, String? refs}) => (label: label, run: () => runApplyRecruitWorkerCostExpectation(pins), refs: refs);

void runApprenticeTechConsistencyExpectation() {
  const order = RecruitWorkerOrder(targetTier: WorkerTier.apprentice);
  final stockpile = const Stockpile().applyDelta('paper', 2);
  expect(canAffordRecruitWorker(_playerWithTech(_journeymanTech), order, const WorkerPool(peasants: 1), stockpile, 200).reason, kRecruitWorkerTechLocked, reason: 'journeyman tech does not satisfy the apprentice gate');
  expect(canAffordRecruitWorker(_playerWithTech(_masterTech), order, const WorkerPool(peasants: 1), stockpile, 200).reason, kRecruitWorkerTechLocked, reason: 'master tech does not satisfy the apprentice gate');
}

WorkerActionCostScenario apprenticeTechConsistencyScenario({required String label, String? refs}) => (label: label, run: runApprenticeTechConsistencyExpectation, refs: refs);
// dart format on
