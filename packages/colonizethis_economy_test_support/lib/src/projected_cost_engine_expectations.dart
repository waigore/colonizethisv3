// dart format off
// Compact ProjectedCostEngine helper assertions (Refs #3939 phase 3 slice 35).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'projected_cost_engine_scenarios.dart';

/// Pins for work-material affordability rows.
typedef WorkMaterialAffordPins = ({Map<String, int> stockpileDeltas, Map<String, int> cost, bool expectedAfford});

void runWorkMaterialAffordExpectation(WorkMaterialAffordPins pins) {
  final stockpile = stockpileWithDeltas(pins.stockpileDeltas);
  expect(ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, pins.cost), pins.expectedAfford);
}

ProjectedCostEngineWorkMaterialScenario workMaterialAffordScenario({required String label, required WorkMaterialAffordPins pins}) => (label: label, run: () => runWorkMaterialAffordExpectation(pins), refs: null);

/// Pins for work-material deduction rows.
typedef WorkMaterialDeductPins = ({Map<String, int> stockpileDeltas, Map<String, int> cost, Map<String, int> expectedQuantities});

void runWorkMaterialDeductExpectation(WorkMaterialDeductPins pins) {
  final stockpile = stockpileWithDeltas(pins.stockpileDeltas);
  final after = ProjectedCostEngine.deductWorkMaterialCost(stockpile, pins.cost);
  for (final entry in pins.expectedQuantities.entries) {
    expect(after.quantityOf(entry.key), entry.value);
  }
}

ProjectedCostEngineWorkMaterialScenario workMaterialDeductScenario({required String label, required WorkMaterialDeductPins pins}) => (label: label, run: () => runWorkMaterialDeductExpectation(pins), refs: null);

const _delegationPlayer = Player(id: 'p1', displayName: 'P', isHuman: true);

const _delegationWorkers = WorkerPool(peasants: 10);

const _delegationStockpile = Stockpile();

const _delegationBuildOrder = BuildUnitOrder(unitType: 'unknown_unit_xyz', isMilitary: false, spawnProvinceId: 'oldWorld|p1');

const _delegationTreasury = 10000;

void runBuildAffordDelegationExpectation() {
  final viaEngine = ProjectedCostEngine.canAffordBuildOrder(_delegationPlayer, _delegationBuildOrder, _delegationWorkers, _delegationStockpile, _delegationTreasury);
  final direct = canAffordBuild(_delegationPlayer, _delegationBuildOrder, _delegationWorkers, _delegationStockpile, _delegationTreasury);
  expect(viaEngine.canAfford, direct.canAfford);
  expect(viaEngine.reason, direct.reason);
}

ProjectedCostEngineBuildScenario buildAffordDelegationScenario({required String label}) => (label: label, run: runBuildAffordDelegationExpectation, refs: null);

const _applyDeductionPlayer = Player(
  id: 'p1',
  displayName: 'P',
  isHuman: true,
  treasury: 50000,
  stockpile: Stockpile(quantities: {'paper': 50, 'cast_iron': 50, 'lumber': 50}),
  workerPool: WorkerPool(peasants: 5),
  techUnlocked: {kTechIdEarlySteamEngine: true},
);

const _applyDeductionOrder = BuildUnitOrder(unitType: kUnitTypeRailBuilder, isMilitary: false, spawnProvinceId: 'oldWorld|p1');

const _applyDeductionWorkers = WorkerPool(peasants: 5);

const _applyDeductionStockpile = Stockpile(quantities: {'paper': 50, 'cast_iron': 50, 'lumber': 50});

const _applyDeductionTreasury = 50000;

void runBuildApplyDeductionDelegationExpectation() {
  final viaEngine = ProjectedCostEngine.applyBuildOrderCostDeduction(_applyDeductionPlayer, _applyDeductionOrder, _applyDeductionWorkers, _applyDeductionStockpile, _applyDeductionTreasury);
  final direct = applyBuildCostDeduction(_applyDeductionPlayer, _applyDeductionOrder, _applyDeductionWorkers, _applyDeductionStockpile, _applyDeductionTreasury);
  expect(viaEngine.treasury, direct.treasury);
  expect(viaEngine.workers.peasants, direct.workers.peasants);
  expect(viaEngine.stockpile.quantities, direct.stockpile.quantities);
}

ProjectedCostEngineBuildScenario buildApplyDeductionDelegationScenario({required String label}) => (label: label, run: runBuildApplyDeductionDelegationExpectation, refs: null);
// dart format on
