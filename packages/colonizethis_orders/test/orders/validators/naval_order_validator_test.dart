// Consolidated NavalOrderValidator runner (Refs #3949 wave 3).
//
// Merges former naval_order_validator_{part1,part2,docking,mission}_test.dart
// into one ≤400-line family runner with scenarios in support/.

import 'package:colonizethis_test/test.dart';

import '../support/scenario_runner.dart';
import '../support/validators/naval_order_validator_scenarios.dart';

void main() {
  group('NavalOrderValidator', () {
    runLabeledScenarioGroup(
      'validateNavalMove',
      navalMoveValidatorScenarios(),
      runNavalOrderValidatorScenario,
    );
    runLabeledScenarioGroup(
      'validateNavalMission',
      navalMissionValidatorScenarios(),
      runNavalOrderValidatorScenario,
    );
  });
}
