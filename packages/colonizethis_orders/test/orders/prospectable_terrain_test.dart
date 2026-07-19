// Ported from colonizethis_logic (Refs #4090 Slice E).
// Table-driven for repo.orders_test_prefer_scenario_tables (Refs #3949).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup('terrain prospectability classification', [
    rs('defines prospectability for every terrain type', () {
      expect(
        kProspectableByTerrainType.keys.toSet(),
        TerrainType.values.toSet(),
      );
    }),
    rs('matches canonical mineral prospecting terrain rules', () {
      expect(kProspectableByTerrainType[TerrainType.plains], isFalse);
      expect(kProspectableByTerrainType[TerrainType.hardwoodForest], isFalse);
      expect(kProspectableByTerrainType[TerrainType.scrubForest], isFalse);
      expect(kProspectableByTerrainType[TerrainType.hills], isTrue);
      expect(kProspectableByTerrainType[TerrainType.mountain], isTrue);
      expect(kProspectableByTerrainType[TerrainType.swamp], isTrue);
      expect(kProspectableByTerrainType[TerrainType.desert], isTrue);
    }),
  ], runRunnableScenario);
}
