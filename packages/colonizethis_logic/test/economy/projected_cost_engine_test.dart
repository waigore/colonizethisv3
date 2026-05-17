import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/economy/projected_cost_engine.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('ProjectedCostEngine work material', () {
    test('canAffordWorkMaterialCost is false when any commodity is short', () {
      const stockpile = Stockpile(quantities: {'lumber': 1});
      const cost = <String, int>{'lumber': 2};
      expect(
        ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost),
        isFalse,
      );
    });

    test('deductWorkMaterialCost reduces quantities', () {
      const stockpile = Stockpile(quantities: {'lumber': 5, 'cast_iron': 3});
      const cost = <String, int>{'lumber': 2, 'cast_iron': 1};
      final after = ProjectedCostEngine.deductWorkMaterialCost(stockpile, cost);
      expect(after.quantityOf('lumber'), 3);
      expect(after.quantityOf('cast_iron'), 2);
    });
  });

  group('ProjectedCostEngine build', () {
    test('delegates canAffordBuildOrder to build_cost canAffordBuild', () {
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
    });

    test(
      'delegates applyBuildOrderCostDeduction to applyBuildCostDeduction',
      () {
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
        expect(
          viaEngine.stockpile.quantities,
          direct.stockpile.quantities,
        );
      },
    );
  });
}
