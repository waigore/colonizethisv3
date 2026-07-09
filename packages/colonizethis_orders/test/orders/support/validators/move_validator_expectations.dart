// Compact MoveValidator / ArmyMoveValidator assertions (Refs #3949 wave 3).

import 'move_validator_expectation_shorthand.dart';

/// Pins for [moveValidatorScenarios] rows.
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
      mvExpectBuilderCannotEnterGp();
    case MoveValidatorTarget.militaryRegimentMoveOrderRejected:
      mvExpectMilitaryRegimentRejected();
    case MoveValidatorTarget.armyMoveIntoOtherGpWithoutWar:
      mvExpectArmyIntoGpNoWar();
    case MoveValidatorTarget.civilianWorkerCannotMoveIntoMinor:
      mvExpectBuilderCannotEnterMinor();
    case MoveValidatorTarget.explorerOntoMinor:
      mvExpectExplorerOntoMinor();
    case MoveValidatorTarget.spyOntoOtherGp:
      mvExpectSpyOntoOtherGp();
    case MoveValidatorTarget.explorerCrossRegionTribe:
      mvExpectExplorerCrossRegionTribe();
    case MoveValidatorTarget.builderCrossRegionTribeInvalid:
      mvExpectBuilderCrossRegionTribeInvalid();
    case MoveValidatorTarget.shortCircuitPreviousRejected:
      mvExpectShortCircuitPreviousRejected();
    case MoveValidatorTarget.armyMoveIntoMinorWithoutWar:
      mvExpectArmyIntoMinorNoWar();
    case MoveValidatorTarget.armyMoveIntoGpWithDeclareWar:
      mvExpectArmyIntoGpWithDeclareWar();
    case MoveValidatorTarget.armyMoveIntoMinorWithDeclareWar:
      mvExpectArmyIntoMinorWithDeclareWar();
    case MoveValidatorTarget.armyMoveIntoTribeWithDeclareWar:
      mvExpectArmyIntoTribeWithDeclareWar();
    case MoveValidatorTarget.armyMoveIntoMinorTribeWithoutWar:
      mvExpectArmyIntoMinorTribeNoWar();
  }
}
