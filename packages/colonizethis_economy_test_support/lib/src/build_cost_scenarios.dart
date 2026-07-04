// Table-driven build-cost scenarios (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';

/// One row in a build-cost scenario table.
class BuildCostScenario {
  const BuildCostScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  final String label;
  final void Function() run;
  final String? refs;
}

/// Runs [scenario] (setup + assertions live in [BuildCostScenario.run]).
void runBuildCostScenario(BuildCostScenario scenario) {
  scenario.run();
}

Stockpile _stockpileForCatalogInputs(Map<CommodityId, int> inputs) {
  return stockpileWithDeltas(inputs);
}

/// Canonical scenarios for [canAffordBuild] and [applyBuildCostDeduction].
List<BuildCostScenario> buildCostScenarios() => [
  ..._buildCostUnknownUnitScenarios(),
  ..._buildCostAffordApplyScenarios(),
  ..._buildCostAffordRejectScenarios(),
];

List<BuildCostScenario> _buildCostUnknownUnitScenarios() => [
  BuildCostScenario(
    label: 'canAffordBuild returns false for unknown unit type',
    run: () {
      final player = corePlayer();
      final workers = coreWorkerPool(peasants: 10);
      const stockpile = Stockpile();
      const order = BuildUnitOrder(
        unitType: 'unknown_unit_xyz',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = canAffordBuild(player, order, workers, stockpile, 10000);
      expect(result.canAfford, isFalse);
      expect(result.reason, 'Insufficient resources');
    },
  ),
  BuildCostScenario(
    label:
        'applyBuildCostDeduction returns unchanged state for unknown unit type',
    run: () {
      final player = corePlayer();
      final workers = coreWorkerPool(peasants: 5);
      const stockpile = Stockpile();
      const order = BuildUnitOrder(
        unitType: 'unknown_unit_xyz',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = applyBuildCostDeduction(
        player,
        order,
        workers,
        stockpile,
        1000,
      );
      expect(result.workers.peasants, 5);
      expect(result.treasury, 1000);
    },
  ),
];

List<BuildCostScenario> _buildCostAffordApplyScenarios() => [
  BuildCostScenario(
    label: 'civilian Builder: apply matches catalog after canAfford true',
    run: () {
      final player = corePlayer();
      final workers = coreWorkerPool(peasants: 10);
      final econ = CivilianEconomyCatalog.byId[kUnitTypeBuilder]!;
      final stockpile = _stockpileForCatalogInputs(econ.buildInputs);
      const treasuryStart = 5000;
      const order = BuildUnitOrder(
        unitType: kUnitTypeBuilder,
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final check = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        treasuryStart,
      );
      expect(check.canAfford, isTrue);
      final after = applyBuildCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasuryStart,
      );
      expect(after.treasury, treasuryStart - econ.buildTreasuryCost);
      expect(after.workers.peasants, workers.peasants);
      for (final e in econ.buildInputs.entries) {
        expect(after.stockpile.quantityOf(e.key), 0);
      }
    },
  ),
  BuildCostScenario(
    label: 'military peasant_levies: apply matches catalog after canAfford true',
    run: () {
      final player = corePlayer();
      final workers = coreWorkerPool(peasants: 3);
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      final stockpile = _stockpileForCatalogInputs(econ.buildInputs);
      final treasuryStart = econ.buildTreasuryCost + 500;
      const order = BuildUnitOrder(
        unitType: 'peasant_levies',
        isMilitary: true,
        spawnProvinceId: 'oldWorld|p1',
      );
      final check = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        treasuryStart,
      );
      expect(check.canAfford, isTrue);
      final after = applyBuildCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasuryStart,
      );
      expect(after.treasury, treasuryStart - econ.buildTreasuryCost);
      expect(after.workers.peasants, workers.peasants - 1);
      for (final e in econ.buildInputs.entries) {
        expect(after.stockpile.quantityOf(e.key), 0);
      }
    },
  ),
  BuildCostScenario(
    label: 'naval carrack: apply matches catalog after canAfford true',
    run: () {
      final player = corePlayer();
      final workers = coreWorkerPool(peasants: 10);
      final econ = ShipEconomyCatalog.byId['carrack']!;
      final stockpile = _stockpileForCatalogInputs(econ.buildInputs);
      final treasuryStart = econ.buildTreasuryCost + 500;
      const order = BuildUnitOrder(
        unitType: 'carrack',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final check = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        treasuryStart,
      );
      expect(check.canAfford, isTrue);
      final after = applyBuildCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasuryStart,
      );
      expect(after.treasury, treasuryStart - econ.buildTreasuryCost);
      expect(after.workers.peasants, workers.peasants - 1);
      for (final e in econ.buildInputs.entries) {
        expect(after.stockpile.quantityOf(e.key), 0);
      }
    },
  ),
];

List<BuildCostScenario> _buildCostAffordRejectScenarios() => [
  BuildCostScenario(
    label: 'naval carrack: canAfford false when peasants are zero',
    run: () {
      final player = corePlayer();
      final workers = coreWorkerPool(peasants: 0);
      final econ = ShipEconomyCatalog.byId['carrack']!;
      final stockpile = _stockpileForCatalogInputs(econ.buildInputs);
      const order = BuildUnitOrder(
        unitType: 'carrack',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        econ.buildTreasuryCost + 10,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, 'Insufficient workers');
    },
  ),
  BuildCostScenario(
    label: 'naval fluyte: canAfford false when unlocking tech missing',
    run: () {
      final player = corePlayer(techUnlocked: const {});
      final workers = coreWorkerPool(peasants: 10);
      final econ = ShipEconomyCatalog.byId['fluyte']!;
      final stockpile = _stockpileForCatalogInputs(econ.buildInputs);
      const order = BuildUnitOrder(
        unitType: 'fluyte',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        econ.buildTreasuryCost + 500,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, 'Required technology not unlocked');
    },
  ),
  BuildCostScenario(
    label: 'military lancers: canAfford false when unlocking tech missing',
    run: () {
      final player = corePlayer(techUnlocked: const {});
      final workers = coreWorkerPool(peasants: 5);
      final econ = RegimentEconomyCatalog.byId['lancers']!;
      final stockpile = _stockpileForCatalogInputs(econ.buildInputs);
      const order = BuildUnitOrder(
        unitType: 'lancers',
        isMilitary: true,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        econ.buildTreasuryCost + 500,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, 'Required technology not unlocked');
    },
  ),
  BuildCostScenario(
    label: 'military peasant_levies: canAfford false when peasants are zero',
    run: () {
      final player = corePlayer();
      final workers = coreWorkerPool(peasants: 0);
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      final stockpile = _stockpileForCatalogInputs(econ.buildInputs);
      const order = BuildUnitOrder(
        unitType: 'peasant_levies',
        isMilitary: true,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        econ.buildTreasuryCost + 500,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, 'Insufficient workers');
    },
  ),
];
