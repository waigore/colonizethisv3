import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('detectNavalConflicts', () {
    test('returns empty when no fleets', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [],
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atWar,
          ),
        ],
      );
      expect(detectNavalConflicts(game), isEmpty);
    });

    test('returns empty when two factions in same zone but at peace', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
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
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atPeace,
          ),
        ],
      );
      expect(detectNavalConflicts(game), isEmpty);
    });

    test('returns one BattleContextSea when two at-war factions in same zone', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
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
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atWar,
          ),
        ],
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
    });
  });

  group('normalizeNavalBattleSidesForAttacker', () {
    Game gameTwoFleets({
      required Fleet fleet1,
      required Fleet fleet2,
    }) {
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [fleet1, fleet2],
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atWar,
          ),
        ],
      );
    }

    test('only mover is attacker when the other is not Patrol or Blockade', () {
      final game = gameTwoFleets(
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
    });

    test('interceptor is attacker when the other faction moved', () {
      final game = gameTwoFleets(
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
    });

    test('neither moved: lexicographically smaller ownerId is attacker', () {
      final game = gameTwoFleets(
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
    });

    test('both moved: lexicographically smaller ownerId is attacker', () {
      final game = gameTwoFleets(
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
      final n = normalizeNavalBattleSidesForAttacker(battle, game, {'fa', 'fb'});
      expect(n.side1.ownerId, 'p1');
      expect(n.side2.ownerId, 'p2');
    });
  });

  group('navalStrength', () {
    test('returns 0 for empty list', () {
      expect(navalStrength([]), 0.0);
    });

    test('uses configured weighted formula including durability', () {
      final carrack = NavalStatsCatalog.get('carrack');
      final expected = carrack.firepower +
          (carrack.range * 0.4) +
          (carrack.armour * 0.15) +
          (carrack.hull * (1 + carrack.armour / 10.0)) +
          (carrack.movement * 0.1);
      expect(navalStrength(['carrack']), closeTo(expected, 1e-9));
    });
  });
}
