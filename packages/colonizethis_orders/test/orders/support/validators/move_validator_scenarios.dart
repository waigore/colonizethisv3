// Table-driven MoveValidator / ArmyMoveValidator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'move_validator_expectations.dart';

/// One row in [moveValidatorScenarios].
class MoveValidatorScenario implements RefsScenario {
  const MoveValidatorScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final MoveValidatorTarget target;
  @override
  final String? refs;
}

void runMoveValidatorScenario(MoveValidatorScenario scenario) {
  runMoveValidatorExpectation(scenario.target);
}

/// Canonical scenarios for [MoveValidator] / [ArmyMoveValidator] family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `move_validator_part*_test.dart` descriptions (single-line `label:` for CI).
List<MoveValidatorScenario> moveValidatorScenarios() => const [
      MoveValidatorScenario(
        label: 'civilian cannot move into other GP territory',
        target: MoveValidatorTarget.civilianCannotMoveIntoOtherGp,
      ),
      MoveValidatorScenario(
        label: 'military regiment MoveOrder is rejected; use army move',
        target: MoveValidatorTarget.militaryRegimentMoveOrderRejected,
      ),
      MoveValidatorScenario(
        label: 'ArmyMoveValidator military cannot move into other GP province without war',
        target: MoveValidatorTarget.armyMoveIntoOtherGpWithoutWar,
      ),
      MoveValidatorScenario(
        label: 'civilian worker cannot move into Minor/Tribe territory',
        target: MoveValidatorTarget.civilianWorkerCannotMoveIntoMinor,
      ),
      MoveValidatorScenario(
        label: 'Explorer may move onto Minor province tile (cross-region style)',
        target: MoveValidatorTarget.explorerOntoMinor,
      ),
      MoveValidatorScenario(
        label: 'Spy may move onto other Great Power province tile without declare war',
        target: MoveValidatorTarget.spyOntoOtherGp,
      ),
      MoveValidatorScenario(
        label: 'explorer can move cross-region into tribe-owned province',
        target: MoveValidatorTarget.explorerCrossRegionTribe,
      ),
      MoveValidatorScenario(
        label: 'builder cross-region into tribe-owned province is still invalid',
        target: MoveValidatorTarget.builderCrossRegionTribeInvalid,
      ),
      MoveValidatorScenario(
        label: 'short-circuits when previous order rejected',
        target: MoveValidatorTarget.shortCircuitPreviousRejected,
      ),
      MoveValidatorScenario(
        label: 'ArmyMoveValidator military cannot move into Minor province without war',
        target: MoveValidatorTarget.armyMoveIntoMinorWithoutWar,
      ),
      MoveValidatorScenario(
        label: 'ArmyMoveValidator military may move into other GP province with same-turn declareWar',
        target: MoveValidatorTarget.armyMoveIntoGpWithDeclareWar,
      ),
      MoveValidatorScenario(
        label: 'ArmyMoveValidator military may move into Minor province with same-turn declareWar',
        target: MoveValidatorTarget.armyMoveIntoMinorWithDeclareWar,
      ),
      MoveValidatorScenario(
        label: 'ArmyMoveValidator military may move into Tribe province with same-turn declareWar',
        target: MoveValidatorTarget.armyMoveIntoTribeWithDeclareWar,
      ),
      MoveValidatorScenario(
        label: 'ArmyMoveValidator military cannot move into Minor/Tribe province without war',
        target: MoveValidatorTarget.armyMoveIntoMinorTribeWithoutWar,
      ),
    ];
