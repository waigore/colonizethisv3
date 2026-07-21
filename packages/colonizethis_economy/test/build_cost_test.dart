// Table-driven unit tests for build_cost (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
const _spawnProvinceId = 'oldWorld|p1';

BuildUnitOrder _buildOrder({required String unitType, required bool isMilitary}) =>
    BuildUnitOrder(unitType: unitType, isMilitary: isMilitary, spawnProvinceId: _spawnProvinceId);

(dynamic econ, Stockpile stockpile, int treasuryStart, int peasantsDelta) _catalogContextForUnit({
  required String unitType,
  required bool isMilitary,
  required int peasants,
  required int treasuryPadding,
}) {
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

void runBuildCostAffordApplyExpectation(BuildCostAffordApplyPins pins) {
  final player = corePlayer();
  final workers = coreWorkerPool(peasants: pins.peasants);
  final order = _buildOrder(unitType: pins.unitType, isMilitary: pins.isMilitary);
  final (econ, stockpile, treasuryStart, peasantsDelta) = _catalogContextForUnit(
    unitType: pins.unitType,
    isMilitary: pins.isMilitary,
    peasants: pins.peasants,
    treasuryPadding: pins.treasuryPadding,
  );
  final check = canAffordBuild(player, order, workers, stockpile, treasuryStart);
  expect(check.canAfford, isTrue);
  final after = applyBuildCostDeduction(player, order, workers, stockpile, treasuryStart);
  expect(after.treasury, treasuryStart - econ.buildTreasuryCost);
  expect(after.workers.peasants, workers.peasants - peasantsDelta);
  for (final e in econ.buildInputs.entries) {
    expect(after.stockpile.quantityOf(e.key), 0);
  }
}

void runBuildCostAffordRejectExpectation(BuildCostAffordRejectPins pins) {
  final player = corePlayer(techUnlocked: pins.techUnlocked ?? const {});
  final workers = coreWorkerPool(peasants: pins.peasants);
  final order = _buildOrder(unitType: pins.unitType, isMilitary: pins.isMilitary);
  final (econ, stockpile, treasuryStart, _) = _catalogContextForUnit(
    unitType: pins.unitType,
    isMilitary: pins.isMilitary,
    peasants: pins.peasants,
    treasuryPadding: pins.treasuryPadding,
  );
  final result = canAffordBuild(player, order, workers, stockpile, treasuryStart);
  expect(result.canAfford, isFalse);
  expect(result.reason, pins.expectedReason);
}

void runBuildCostScenario(BuildCostScenario scenario) {
  final unknownUnit = scenario.unknownUnit;
  if (unknownUnit != null) {
    runBuildCostUnknownUnitExpectation(unknownUnit);
    return;
  }
  final affordApply = scenario.affordApply;
  if (affordApply != null) {
    runBuildCostAffordApplyExpectation(affordApply);
    return;
  }
  runBuildCostAffordRejectExpectation(scenario.affordReject!);
}
// dart format on

void main() {
  group('build_cost', () {
    runLabeledScenarios(buildCostScenarios(), (scenario) {
      runBuildCostScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
