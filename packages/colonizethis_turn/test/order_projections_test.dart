import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_projections_cases.dart';

void main() {
  group('projectOrderEffects', () {
    test('returns empty ProjectedEffects when player not in game', () {
      final effects = projectOrderEffects(
        game: orderProjectionsEmptyGame(),
        orders: const Orders(),
        topology: orderProjectionsSingleProvinceTopology,
        tileMapByRegion: const {},
        playerId: 'nonexistent',
      );
      expect(effects.workerCount, isNull);
      expect(effects.unitLocations, isNull);
      expect(effects.stockpileDeltas, isNull);
      expect(effects.treasuryDelta, isNull);
    });

    test('returns unitLocations and workerCount for single player after resolve', () {
      final effects = projectOrderEffects(
        game: orderProjectionsTwoProvinceMoveGame(),
        orders: orderProjectionsMoveToP2Orders(),
        topology: orderProjectionsTwoProvinceTopology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.workerCount, isNotNull);
      expect(effects.unitLocations, isNotNull);
      expect(effects.unitLocations!['u1'], '$kRegionOldWorld|P2');
    });

    test('returns ProjectedEffects with workerCount and unitLocations after full resolve', () {
      final effects = projectOrderEffects(
        game: orderProjectionsSingleProvinceGame(),
        orders: const Orders(),
        topology: orderProjectionsSingleProvinceTopology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.workerCount, isNotNull);
      expect(effects.unitLocations, isNotNull);
    });

    test('includes newWorld unit locations in ProjectedEffects', () {
      final effects = projectOrderEffects(
        game: orderProjectionsCrossRegionNwUnitGame(),
        orders: const Orders(),
        topology: orderProjectionsCrossRegionTopology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.unitLocations, isNotNull);
      expect(effects.unitLocations!['u1'], '$kRegionNewWorld|N1');
    });

    test('returns stockpileDeltas and treasuryDelta when resolve changes stockpile and treasury', () {
      final effects = projectOrderEffects(
        game: orderProjectionsTreasuryStockpileGame(),
        orders: const Orders(),
        topology: orderProjectionsSingleProvinceTopology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.treasuryDelta, isNotNull);
      expect(effects.workerCount, isNotNull);
      expect(effects.unitLocations, isNotNull);
    });

    test('stockpileDeltas includes negative delta when commodity fully consumed', () {
      final effects = projectOrderEffects(
        game: orderProjectionsGrainConsumptionGame(),
        orders: const Orders(),
        topology: orderProjectionsSingleProvinceTopology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.stockpileDeltas, isNotNull);
      expect(effects.stockpileDeltas!['grain'], -1);
    });

    test('productionByRecipe populated when defaultAssignments provided', () {
      final effects = projectOrderEffects(
        game: orderProjectionsProductionGame(),
        orders: const Orders(),
        topology: orderProjectionsSingleProvinceTopology,
        tileMapByRegion: const {},
        playerId: 'p1',
        defaultAssignments: orderProjectionsLumberAssignments(),
      );
      expect(effects.productionByRecipe, isNotNull);
      expect(
        effects.productionByRecipe![orderProjectionsLumberRecipeId],
        2,
      );
    });

    test('productionByRecipe null when no defaultAssignments', () {
      final effects = projectOrderEffects(
        game: orderProjectionsSingleProvinceGame(),
        orders: const Orders(),
        topology: orderProjectionsSingleProvinceTopology,
        tileMapByRegion: const {},
        playerId: 'p1',
      );
      expect(effects.productionByRecipe, isNull);
    });
  });
}
