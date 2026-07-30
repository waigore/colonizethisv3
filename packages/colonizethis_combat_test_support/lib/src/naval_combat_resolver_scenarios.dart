// Table-driven naval conflict detection and strength scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_combat_test_support.dart';
import 'scenario_runner.dart';



List<RunnableScenario> detectNavalConflictsScenarios() => [
  RunnableScenario(
    scenarioId: 'ncr-empty-fleets',
    label: 'returns empty when no fleets',
    run: () {
      final game = navalTwoPlayerGame(
        diplomacyRelations: [navalDiplomacyRelation(RelationState.atWar)],
      );
      expect(detectNavalConflicts(game), isEmpty);
    },
  ),
  RunnableScenario(
    scenarioId: 'ncr-peace-same-zone',
    label: 'returns empty when two factions in same zone but at peace',
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
        diplomacyRelations: [navalDiplomacyRelation(RelationState.atPeace)],
      );
      expect(detectNavalConflicts(game), isEmpty);
    },
  ),
  RunnableScenario(
    scenarioId: 'ncr-at-war-battle',
    label: 'returns one BattleContextSea when two at-war factions in same zone',
    run: () {
      final game = navalTwoPlayerGame(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['carrack', 'carrack'],
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['fluyte'],
          ),
        ],
        diplomacyRelations: [navalDiplomacyRelation(RelationState.atWar)],
      );
      final battles = detectNavalConflicts(game);
      expect(battles.length, 1);
      expect(battles[0].seaZoneId, 'sea1');
      expect(battles[0].side1.ownerId, 'p1');
      expect(battles[0].side1.shipTypeIds, ['carrack', 'carrack']);
      expect(battles[0].side1.ships.length, 2);
      expect(battles[0].side1.ships.map((s) => s.id).toSet().length, 2);
      expect(battles[0].side2.ownerId, 'p2');
      expect(battles[0].side2.shipTypeIds, ['fluyte']);
    },
  ),
];

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

List<RunnableScenario> navalStrengthScenarios() => [
  RunnableScenario(
    scenarioId: 'ns-empty',
    label: 'returns 0 for empty list',
    run: () {
      expect(navalStrength([]), 0.0);
    },
  ),
  RunnableScenario(
    scenarioId: 'ns-weighted-formula',
    label: 'uses configured weighted formula including durability',
    run: () {
      final carrack = NavalStatsCatalog.get('carrack');
      final expected = carrack.firepower +
          (carrack.range * 0.4) +
          (carrack.armour * 0.15) +
          (carrack.hull * (1 + carrack.armour / 10.0)) +
          (carrack.movement * 0.1);
      expect(navalStrength(['carrack']), closeTo(expected, 1e-9));
    },
  ),
];
