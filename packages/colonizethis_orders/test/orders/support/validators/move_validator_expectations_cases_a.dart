part of 'move_validator_expectations.dart';

void _civilianCannotMoveIntoOtherGp() {
  mvExpectBuilderCannotEnterGp();
}

void _militaryRegimentMoveOrderRejected() {
  mvExpectMilitaryRegimentRejected();
}

void _armyMoveIntoOtherGpWithoutWar() {
  mvExpectArmyIntoGpNoWar();
}

void _civilianWorkerCannotMoveIntoMinor() {
  mvExpectBuilderCannotEnterMinor();
}

void _explorerOntoMinor() {
  mvExpectExplorerOntoMinor();
}

void _spyOntoOtherGp() {
  mvExpectSpyOntoOtherGp();
}

void _explorerCrossRegionTribe() {
  mvExpectExplorerCrossRegionTribe();
}
