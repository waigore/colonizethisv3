// dart format off
// Compact build-cost assertions (Refs #3939 phase 3 slice 36).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'build_cost_scenarios.dart';

const _spawnProvinceId = 'oldWorld|p1';

BuildUnitOrder _buildOrder({required String unitType, required bool isMilitary}) => BuildUnitOrder(unitType: unitType, isMilitary: isMilitary, spawnProvinceId: _spawnProvinceId);

/// Pins for unknown-unit afford/reject rows.
typedef BuildCostUnknownUnitPins = ({bool viaApplyDeduction, int peasants, int treasury, int expectedPeasants, int expectedTreasury});

void runBuildCostUnknownUnitExpectation(BuildCostUnknownUnitPins pins) {
  final player = corePlayer();
  final workers = coreWorkerPool(peasants: pins.peasants);
  const stockpile = Stockpile();
  const order = BuildUnitOrder(unitType: 'unknown_unit_xyz', isMilitary: false, spawnProvinceId: _spawnProvinceId);
  if (pins.viaApplyDeduction) {
    final result = applyBuildCostDeduction(player, order, workers, stockpile, pins.treasury);
    expect(result.workers.peasants, pins.expectedPeasants);
    expect(result.treasury, pins.expectedTreasury);
    return;
  }
  final result = canAffordBuild(player, order, workers, stockpile, pins.treasury);
  expect(result.canAfford, isFalse);
  expect(result.reason, 'Insufficient resources');
}

BuildCostScenario buildCostUnknownUnitScenario({required String label, required BuildCostUnknownUnitPins pins}) => (label: label, unknownUnit: pins, affordApply: null, affordReject: null, refs: null);

/// Pins for afford-then-apply catalog rows.
typedef BuildCostAffordApplyPins = ({String unitType, bool isMilitary, int peasants, int treasuryPadding});

void runBuildCostAffordApplyExpectation(BuildCostAffordApplyPins pins) {
  final player = corePlayer();
  final workers = coreWorkerPool(peasants: pins.peasants);
  final order = _buildOrder(unitType: pins.unitType, isMilitary: pins.isMilitary);
  final (econ, stockpile, treasuryStart, peasantsDelta) = _catalogContextForUnit(unitType: pins.unitType, isMilitary: pins.isMilitary, peasants: pins.peasants, treasuryPadding: pins.treasuryPadding);
  final check = canAffordBuild(player, order, workers, stockpile, treasuryStart);
  expect(check.canAfford, isTrue);
  final after = applyBuildCostDeduction(player, order, workers, stockpile, treasuryStart);
  expect(after.treasury, treasuryStart - econ.buildTreasuryCost);
  expect(after.workers.peasants, workers.peasants - peasantsDelta);
  for (final e in econ.buildInputs.entries) {
    expect(after.stockpile.quantityOf(e.key), 0);
  }
}

(dynamic econ, Stockpile stockpile, int treasuryStart, int peasantsDelta) _catalogContextForUnit({required String unitType, required bool isMilitary, required int peasants, required int treasuryPadding}) {
  if (isMilitary) {
    final econ = RegimentEconomyCatalog.byId[unitType]!;
    return (econ, stockpileWithDeltas(econ.buildInputs), econ.buildTreasuryCost + treasuryPadding, 1);
  }
  if (ShipEconomyCatalog.byId.containsKey(unitType)) {
    final econ = ShipEconomyCatalog.byId[unitType]!;
    return (econ, stockpileWithDeltas(econ.buildInputs), econ.buildTreasuryCost + treasuryPadding, 1);
  }
  final econ = CivilianEconomyCatalog.byId[unitType]!;
  return (econ, stockpileWithDeltas(econ.buildInputs), treasuryPadding, 0);
}

BuildCostScenario buildCostAffordApplyScenario({required String label, required BuildCostAffordApplyPins pins}) => (label: label, unknownUnit: null, affordApply: pins, affordReject: null, refs: null);

/// Pins for afford-reject rows.
typedef BuildCostAffordRejectPins = ({String unitType, bool isMilitary, int peasants, Map<String, bool>? techUnlocked, int treasuryPadding, String expectedReason});

void runBuildCostAffordRejectExpectation(BuildCostAffordRejectPins pins) {
  final player = corePlayer(techUnlocked: pins.techUnlocked ?? const {});
  final workers = coreWorkerPool(peasants: pins.peasants);
  final order = _buildOrder(unitType: pins.unitType, isMilitary: pins.isMilitary);
  final (econ, stockpile, treasuryStart, _) = _catalogContextForUnit(unitType: pins.unitType, isMilitary: pins.isMilitary, peasants: pins.peasants, treasuryPadding: pins.treasuryPadding);
  final result = canAffordBuild(player, order, workers, stockpile, treasuryStart);
  expect(result.canAfford, isFalse);
  expect(result.reason, pins.expectedReason);
}

BuildCostScenario buildCostAffordRejectScenario({required String label, required BuildCostAffordRejectPins pins}) => (label: label, unknownUnit: null, affordApply: null, affordReject: pins, refs: null);
// dart format on
