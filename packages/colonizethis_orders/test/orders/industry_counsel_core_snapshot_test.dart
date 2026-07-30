import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/industry_counsel_core_snapshot.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  group('industryCounselCoreDesiredOutputByRecipe', () {
    test('returns desired outputs for core-assigned recipes only', () {
      final player = Player(
        id: 'gp1',
        displayName: 'GP',
        isHuman: true,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 50)
            .applyDelta(CommodityCatalog.timber.id, 30)
            .applyDelta(CommodityCatalog.iron.id, 30)
            .applyDelta(CommodityCatalog.coal.id, 30),
        workerPool: const WorkerPool(peasants: 8),
      );
      final game = Game(
        id: 'g1',
        players: [player],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
      );

      final snapshot = industryCounselCoreDesiredOutputByRecipe(
        game: game,
        playerId: 'gp1',
      );

      expect(snapshot, isNotEmpty);
      for (final entry in snapshot.entries) {
        expect(ProductionRecipesCatalog.byId.containsKey(entry.key), isTrue);
        expect(entry.value, greaterThanOrEqualTo(0));
      }
    });

    test('merge preserves recipes outside the core snapshot', () {
      const current = {'wool_fabric': 5, 'cotton_fabric': 2};
      const core = {'lumber': 3};

      final merged = mergeIndustryCounselCoreDesiredOutput(
        currentDesired: current,
        coreSnapshot: core,
      );

      expect(merged['wool_fabric'], 5);
      expect(merged['cotton_fabric'], 2);
      expect(merged['lumber'], 3);
    });
  });
}
