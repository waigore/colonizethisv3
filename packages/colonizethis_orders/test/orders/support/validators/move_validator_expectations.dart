// Compact MoveValidator / ArmyMoveValidator assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'move_validator_expectation_shorthand.dart';
import 'move_validator_fixtures.dart';

/// Pins for [moveValidatorScenarios] rows.
part 'move_validator_expectations_cases_a.dart';
part 'move_validator_expectations_cases_b.dart';

enum MoveValidatorTarget {
  civilianCannotMoveIntoOtherGp,
  militaryRegimentMoveOrderRejected,
  armyMoveIntoOtherGpWithoutWar,
  civilianWorkerCannotMoveIntoMinor,
  explorerOntoMinor,
  spyOntoOtherGp,
  explorerCrossRegionTribe,
  builderCrossRegionTribeInvalid,
  shortCircuitPreviousRejected,
  armyMoveIntoMinorWithoutWar,
  armyMoveIntoGpWithDeclareWar,
  armyMoveIntoMinorWithDeclareWar,
  armyMoveIntoTribeWithDeclareWar,
  armyMoveIntoMinorTribeWithoutWar,
}

void runMoveValidatorExpectation(MoveValidatorTarget target) {
  switch (target) {
    case MoveValidatorTarget.civilianCannotMoveIntoOtherGp:
      _civilianCannotMoveIntoOtherGp();
    case MoveValidatorTarget.militaryRegimentMoveOrderRejected:
      _militaryRegimentMoveOrderRejected();
    case MoveValidatorTarget.armyMoveIntoOtherGpWithoutWar:
      _armyMoveIntoOtherGpWithoutWar();
    case MoveValidatorTarget.civilianWorkerCannotMoveIntoMinor:
      _civilianWorkerCannotMoveIntoMinor();
    case MoveValidatorTarget.explorerOntoMinor:
      _explorerOntoMinor();
    case MoveValidatorTarget.spyOntoOtherGp:
      _spyOntoOtherGp();
    case MoveValidatorTarget.explorerCrossRegionTribe:
      _explorerCrossRegionTribe();
    case MoveValidatorTarget.builderCrossRegionTribeInvalid:
      _builderCrossRegionTribeInvalid();
    case MoveValidatorTarget.shortCircuitPreviousRejected:
      _shortCircuitPreviousRejected();
    case MoveValidatorTarget.armyMoveIntoMinorWithoutWar:
      _armyMoveIntoMinorWithoutWar();
    case MoveValidatorTarget.armyMoveIntoGpWithDeclareWar:
      _armyMoveIntoGpWithDeclareWar();
    case MoveValidatorTarget.armyMoveIntoMinorWithDeclareWar:
      _armyMoveIntoMinorWithDeclareWar();
    case MoveValidatorTarget.armyMoveIntoTribeWithDeclareWar:
      _armyMoveIntoTribeWithDeclareWar();
    case MoveValidatorTarget.armyMoveIntoMinorTribeWithoutWar:
      _armyMoveIntoMinorTribeWithoutWar();
  }
}

