// Consolidated OrderEngine validateBuild(civilian) runners (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';

import 'support/engine/order_engine_validate_build_civilian_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('OrderEngine validateBuild (civilian)', () {
    runLabeledScenarios(
      orderEngineValidateBuildCivilianScenarios(),
      runOrderEngineValidateBuildCivilianScenario,
    );
  });
}
