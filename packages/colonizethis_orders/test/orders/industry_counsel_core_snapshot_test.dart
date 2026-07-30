// Industry counsel core snapshot (Refs #4191). Dense for repo.orders_test_support_loc.
// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/industry_counsel_core_snapshot.dart';
import 'package:colonizethis_test/test.dart';
import 'support/scenario_runner.dart';

Game _icCoreGame() => Game(id: 'g1', players: [Player(id: 'gp1', displayName: 'GP', isHuman: true, stockpile: Stockpile().applyDelta(CommodityCatalog.grain.id, 50).applyDelta(CommodityCatalog.timber.id, 30).applyDelta(CommodityCatalog.iron.id, 30).applyDelta(CommodityCatalog.coal.id, 30), workerPool: const WorkerPool(peasants: 8))], worldState: WorldState(turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0), oldWorld: const RegionData(), newWorld: const RegionData()));

void main() {
  runLabeledScenarioGroup('industryCounselCoreDesiredOutputByRecipe', [
    rs('returns desired outputs for core-assigned recipes only', () {final s = industryCounselCoreDesiredOutputByRecipe(game: _icCoreGame(), playerId: 'gp1'); expect(s, isNotEmpty); for (final e in s.entries) {expect(ProductionRecipesCatalog.byId.containsKey(e.key), isTrue); expect(e.value, greaterThanOrEqualTo(0));}}),
    rs('merge preserves recipes outside the core snapshot', () {final m = mergeIndustryCounselCoreDesiredOutput(currentDesired: const {'wool_fabric': 5, 'cotton_fabric': 2}, coreSnapshot: const {'lumber': 3}); expect(m['wool_fabric'], 5); expect(m['cotton_fabric'], 2); expect(m['lumber'], 3);}),
  ], runRunnableScenario);
}
