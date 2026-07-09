/// Equivalence tests for [ArmyMoveValidator] with optional `armiesById`.
///
/// Verifies that the O(1) `Map<String, Army>` lookup path introduced for
/// Refs #2394 (SPEC/program/order-suggestions.md — incremental validation)
/// produces the same `OrderValidationResult` as the legacy single-pass scan.
library;

import 'package:colonizethis_test/test.dart';

import '../support/scenario_runner.dart';
import '../support/validators/army_move_validator_armies_by_id_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'ArmyMoveValidator armiesById equivalence',
    armyMoveValidatorArmiesByIdScenarios(),
    runArmyMoveValidatorArmiesByIdScenario,
  );
}
