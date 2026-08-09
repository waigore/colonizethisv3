// Naval resolver scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_combat_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> normalizeNavalBattleSidesScenarios() => [
  RunnableScenario(
    scenarioId: 'nbs-mover-attacker',
    label: 'only mover is attacker when the other is not Patrol or Blockade',
    run: () {
      final game = navalGameTwoFleetsAtWar(
        fleet1: Fleet(
          id: 'mv',
          ownerId: 'p1',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: ['carrack'],
          mission: FleetMission.none,
        ),
        fleet2: Fleet(
          id: 'st',
          ownerId: 'p2',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: ['fluyte'],
          mission: FleetMission.defend,
        ),
      );
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('x', ['fluyte']),
          mission: FleetMission.defend,
        ),
        side2: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('y', ['carrack']),
          mission: FleetMission.none,
        ),
      );
      final n = normalizeNavalBattleSidesForAttacker(battle, game, {'mv'});
      expect(n.side1.ownerId, 'p1');
      expect(n.side2.ownerId, 'p2');
    },
  ),
  RunnableScenario(
    scenarioId: 'nbs-interceptor-attacker',
    label: 'interceptor is attacker when the other faction moved',
    run: () {
      final game = navalGameTwoFleetsAtWar(
        fleet1: Fleet(
          id: 'mv',
          ownerId: 'p1',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: ['carrack'],
          mission: FleetMission.none,
        ),
        fleet2: Fleet(
          id: 'ic',
          ownerId: 'p2',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: ['fluyte'],
          mission: FleetMission.blockade,
        ),
      );
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('a', ['carrack']),
          mission: FleetMission.none,
        ),
        side2: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('b', ['fluyte']),
          mission: FleetMission.blockade,
        ),
      );
      final n = normalizeNavalBattleSidesForAttacker(battle, game, {'mv'});
      expect(n.side1.ownerId, 'p2');
      expect(n.side2.ownerId, 'p1');
    },
  ),
  RunnableScenario(
    scenarioId: 'nbs-lex-neither-moved',
    label: 'neither moved: lexicographically smaller ownerId is attacker',
    run: () {
      final game = navalGameTwoFleetsAtWar(
        fleet1: Fleet(
          id: 'fa',
          ownerId: 'p1',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: ['carrack'],
        ),
        fleet2: Fleet(
          id: 'fb',
          ownerId: 'p2',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: ['fluyte'],
        ),
      );
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('u2', ['fluyte']),
        ),
        side2: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('u1', ['carrack']),
        ),
      );
      final n = normalizeNavalBattleSidesForAttacker(battle, game, {});
      expect(n.side1.ownerId, 'p1');
      expect(n.side2.ownerId, 'p2');
    },
  ),
  RunnableScenario(
    scenarioId: 'nbs-lex-both-moved',
    label: 'both moved: lexicographically smaller ownerId is attacker',
    run: () {
      final game = navalGameTwoFleetsAtWar(
        fleet1: Fleet(
          id: 'fa',
          ownerId: 'p1',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: ['carrack'],
        ),
        fleet2: Fleet(
          id: 'fb',
          ownerId: 'p2',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: ['fluyte'],
        ),
      );
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('u2', ['fluyte']),
        ),
        side2: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('u1', ['carrack']),
        ),
      );
      final n = normalizeNavalBattleSidesForAttacker(
        battle,
        game,
        {'fa', 'fb'},
      );
      expect(n.side1.ownerId, 'p1');
      expect(n.side2.ownerId, 'p2');
    },
  ),
];
