// Consolidated MoveValidator / ArmyMoveValidator runners (Refs #3949 wave 3).
//
// Merges former move_validator_part{1,2,3}_test.dart into one ≤400-line family
// runner with scenarios in support/.

import 'package:colonizethis_test/test.dart';

import '../support/scenario_runner.dart';
import '../support/validators/move_validator_scenarios.dart';

void main() {
  group('MoveValidator', () {
    runLabeledScenarios(moveValidatorScenarios(), runRunnableScenario);
  });
}
