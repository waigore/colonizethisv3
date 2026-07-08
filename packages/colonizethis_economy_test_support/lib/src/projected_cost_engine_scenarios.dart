// Table-driven projected cost engine scenarios (Refs #3939 phase 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'scenario_runner.dart';

/// One row in [projectedCostEngineWorkMaterialScenarios].
class ProjectedCostEngineWorkMaterialScenario implements RefsScenario {
  const ProjectedCostEngineWorkMaterialScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runProjectedCostEngineWorkMaterialScenario(
  ProjectedCostEngineWorkMaterialScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for ProjectedCostEngine work-material helpers.
List<ProjectedCostEngineWorkMaterialScenario>
    projectedCostEngineWorkMaterialScenarios() => [
      ProjectedCostEngineWorkMaterialScenario(
        label: 'canAffordWorkMaterialCost is false when any commodity is short',
        run: () {
          final stockpile = stockpileWithDeltas({'lumber': 1});
          const cost = <String, int>{'lumber': 2};
          expect(
            ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost),
            isFalse,
          );
        },
      ),
      ProjectedCostEngineWorkMaterialScenario(
        label: 'deductWorkMaterialCost reduces quantities',
        run: () {
          final stockpile = stockpileWithDeltas({'lumber': 5, 'cast_iron': 3});
          const cost = <String, int>{'lumber': 2, 'cast_iron': 1};
          final after =
              ProjectedCostEngine.deductWorkMaterialCost(stockpile, cost);
          expect(after.quantityOf('lumber'), 3);
          expect(after.quantityOf('cast_iron'), 2);
        },
      ),
    ];

/// One row in [projectedCostEngineBuildScenarios].
class ProjectedCostEngineBuildScenario implements RefsScenario {
  const ProjectedCostEngineBuildScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runProjectedCostEngineBuildScenario(
  ProjectedCostEngineBuildScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for ProjectedCostEngine build delegation.
List<ProjectedCostEngineBuildScenario> projectedCostEngineBuildScenarios() => [
      ProjectedCostEngineBuildScenario(
        label: 'delegates canAffordBuildOrder to build_cost canAffordBuild',
        run: () {
          const player = Player(id: 'p1', displayName: 'P', isHuman: true);
          const workers = WorkerPool(peasants: 10);
          const stockpile = Stockpile();
          const order = BuildUnitOrder(
            unitType: 'unknown_unit_xyz',
            isMilitary: false,
            spawnProvinceId: 'oldWorld|p1',
          );
          final a = ProjectedCostEngine.canAffordBuildOrder(
            player,
            order,
            workers,
            stockpile,
            10000,
          );
          final b = canAffordBuild(player, order, workers, stockpile, 10000);
          expect(a.canAfford, b.canAfford);
          expect(a.reason, b.reason);
        },
      ),
      ProjectedCostEngineBuildScenario(
        label:
            'delegates applyBuildOrderCostDeduction to applyBuildCostDeduction',
        run: () {
          const player = Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            treasury: 50000,
            stockpile: Stockpile(
              quantities: {'paper': 50, 'cast_iron': 50, 'lumber': 50},
            ),
            workerPool: WorkerPool(peasants: 5),
            techUnlocked: {kTechIdEarlySteamEngine: true},
          );
          const order = BuildUnitOrder(
            unitType: kUnitTypeRailBuilder,
            isMilitary: false,
            spawnProvinceId: 'oldWorld|p1',
          );
          const workers = WorkerPool(peasants: 5);
          const stockpile = Stockpile(
            quantities: {'paper': 50, 'cast_iron': 50, 'lumber': 50},
          );
          const treasury = 50000;
          final viaEngine = ProjectedCostEngine.applyBuildOrderCostDeduction(
            player,
            order,
            workers,
            stockpile,
            treasury,
          );
          final direct = applyBuildCostDeduction(
            player,
            order,
            workers,
            stockpile,
            treasury,
          );
          expect(viaEngine.treasury, direct.treasury);
          expect(viaEngine.workers.peasants, direct.workers.peasants);
          expect(viaEngine.stockpile.quantities, direct.stockpile.quantities);
        },
      ),
    ];
