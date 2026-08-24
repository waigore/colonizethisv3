// Pre-combat index scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/src/combat/pre_combat_index.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'pre_combat_index_test_support.dart';
import 'scenario_runner.dart';

const _ow = preCombatIndexOldWorldRegionId;

List<RunnableScenario> resolveArmyMoveDestinationProvinceIdScenarios() => [
  RunnableScenario(
    scenarioId: 'pci-prefixed-destination',
    label: 'passes through an already-prefixed destination unchanged',
    run: () {
      final army = preCombatIndexArmy(
        'a1',
        ownerId: 'p1',
        stationedProvinceId: '$_ow|p1',
      );
      const order = ArmyMoveOrder(
        armyId: 'a1',
        destinationProvinceId: '$_ow|p2',
      );
      expect(resolveArmyMoveDestinationProvinceId(army, order), '$_ow|p2');
    },
  ),
  RunnableScenario(
    scenarioId: 'pci-qualifies-local-destination',
    label: 'qualifies a bare local id with the army stationed region',
    run: () {
      final army = preCombatIndexArmy(
        'a1',
        ownerId: 'p1',
        stationedProvinceId: '$_ow|p1',
      );
      const order = ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'p2');
      expect(resolveArmyMoveDestinationProvinceId(army, order), '$_ow|p2');
    },
  ),
];
