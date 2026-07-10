// Table-driven MoveValidator / ArmyMoveValidator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'move_validator_run_rows.dart';

/// One row in [moveValidatorScenarios].
class MoveValidatorScenario implements RefsScenario {
  const MoveValidatorScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runMoveValidatorScenario(MoveValidatorScenario scenario) => scenario.run();

/// Canonical scenarios for [MoveValidator] / [ArmyMoveValidator] family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `move_validator_part*_test.dart` descriptions (single-line `label:` for CI).
List<MoveValidatorScenario> moveValidatorScenarios() => [
  MoveValidatorScenario(
    label: 'civilian cannot move into other GP territory',
    run: mvRunCivilianCannotMoveIntoOtherGpTerritory,
  ),
  MoveValidatorScenario(
    label: 'military regiment MoveOrder is rejected; use army move',
    run: mvRunMilitaryRegimentMoveOrderRejectedUseArmyMove,
  ),
  MoveValidatorScenario(
    label:
        'ArmyMoveValidator military cannot move into other GP province without war',
    run: mvRunArmyMoveIntoOtherGpProvinceWithoutWar,
  ),
  MoveValidatorScenario(
    label: 'civilian worker cannot move into Minor/Tribe territory',
    run: mvRunCivilianWorkerCannotMoveIntoMinorTribeTerritory,
  ),
  MoveValidatorScenario(
    label: 'Explorer may move onto Minor province tile (cross-region style)',
    run: mvRunExplorerMayMoveOntoMinorProvinceTile,
  ),
  MoveValidatorScenario(
    label:
        'Spy may move onto other Great Power province tile without declare war',
    run: mvRunSpyMayMoveOntoOtherGreatPowerProvinceTileWithoutDeclareWar,
  ),
  MoveValidatorScenario(
    label: 'explorer can move cross-region into tribe-owned province',
    run: mvRunExplorerCanMoveCrossRegionIntoTribeOwnedProvince,
  ),
  MoveValidatorScenario(
    label: 'builder cross-region into tribe-owned province is still invalid',
    run: mvRunBuilderCrossRegionIntoTribeOwnedProvinceStillInvalid,
  ),
  MoveValidatorScenario(
    label: 'short-circuits when previous order rejected',
    run: mvRunShortCircuitsWhenPreviousOrderRejected,
  ),
  MoveValidatorScenario(
    label:
        'ArmyMoveValidator military cannot move into Minor province without war',
    run: mvRunArmyMoveIntoMinorProvinceWithoutWar,
  ),
  MoveValidatorScenario(
    label:
        'ArmyMoveValidator military may move into other GP province with same-turn declareWar',
    run: mvRunArmyMoveIntoOtherGpProvinceWithSameTurnDeclareWar,
  ),
  MoveValidatorScenario(
    label:
        'ArmyMoveValidator military may move into Minor province with same-turn declareWar',
    run: mvRunArmyMoveIntoMinorProvinceWithSameTurnDeclareWar,
  ),
  MoveValidatorScenario(
    label:
        'ArmyMoveValidator military may move into Tribe province with same-turn declareWar',
    run: mvRunArmyMoveIntoTribeProvinceWithSameTurnDeclareWar,
  ),
  MoveValidatorScenario(
    label:
        'ArmyMoveValidator military cannot move into Minor/Tribe province without war',
    run: mvRunArmyMoveIntoMinorTribeProvinceWithoutWar,
  ),
];
