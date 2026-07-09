// Consolidated OrderEngine validateDiplomatic runners (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';

import 'support/engine/order_engine_validate_diplomatic_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('OrderEngine validateDiplomatic', () {
    runLabeledScenarios(
      orderEngineValidateDiplomaticScenarios(),
      runOrderEngineValidateDiplomaticScenario,
    );
  });
}
