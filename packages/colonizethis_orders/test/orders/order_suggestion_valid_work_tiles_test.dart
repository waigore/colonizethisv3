// Consolidated getValidWorkOrderTileKeys / suggestWorkOrders runners (Refs #3949 wave 3).
//
// Merges former order_suggestion_valid_work_tiles_part*_test.dart into one
// ≤400-line family runner with scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/valid_work_tiles_scenarios.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    runLabeledScenarios(
      validWorkTilesScenarios(),
      runValidWorkTilesScenario,
    );
  });
}
