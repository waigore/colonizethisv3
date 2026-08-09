// Naval battle resolution scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_combat_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> applyNavalBattleResultsScenarios() => [
  RunnableScenario(
    scenarioId: 'anbr-replace-fleets',
    label: 'replaces fleets in zone with surviving sides',
    run: () {
      final game = navalTwoPlayerGame(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['carrack'],
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['fluyte'],
          ),
        ],
      );
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('ap1', ['carrack']),
        ),
        side2: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('ap2', ['fluyte']),
        ),
      );
      final result = NavalBattleResult(
        survivingShipsSide1: legacyShipInstancesForFleet('out1', ['carrack']),
        survivingShipsSide2: const [],
      );
      final updated = applyNavalBattleResults(game, battle, result, 'oldWorld');
      expect(updated.worldState.fleets.length, 1);
      expect(updated.worldState.fleets.single.ownerId, 'p1');
      expect(updated.worldState.fleets.single.shipTypeIds, ['carrack']);
      expect(updated.worldState.fleets.single.mission, FleetMission.none);
    },
  ),
  RunnableScenario(
    scenarioId: 'anbr-preserve-mission',
    label: 'preserves mission on recreated surviving fleets',
    run: () {
      final game = navalTwoPlayerGame(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['carrack'],
            mission: FleetMission.patrol,
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['fluyte'],
            mission: FleetMission.blockade,
          ),
        ],
      );
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('m1', ['carrack']),
          mission: FleetMission.patrol,
        ),
        side2: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('m2', ['fluyte']),
          mission: FleetMission.blockade,
        ),
      );
      final result = NavalBattleResult(
        survivingShipsSide1: legacyShipInstancesForFleet('om1', ['carrack']),
        survivingShipsSide2: legacyShipInstancesForFleet('om2', ['fluyte']),
      );
      final updated = applyNavalBattleResults(game, battle, result, 'oldWorld');
      final p1 = updated.worldState.fleets.firstWhere((f) => f.ownerId == 'p1');
      final p2 = updated.worldState.fleets.firstWhere((f) => f.ownerId == 'p2');
      expect(p1.mission, FleetMission.patrol);
      expect(p2.mission, FleetMission.blockade);
    },
  ),
];
