import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

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
      expect(battles[0].side2.ownerId, 'p2');
      expect(battles[0].side2.shipTypeIds, ['fluyte']);
    });
  });

  group('navalStrength', () {
    test('returns 0 for empty list', () {
      expect(navalStrength([]), 0.0);
    });

    test('returns positive value for known ship types', () {
      final s = navalStrength(['carrack', 'fluyte']);
      expect(s, greaterThan(0));
    });
  });

  group('resolveSeaBattle', () {
    test('returns surviving ships with casualties by strength ratio', () {
      const battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(ownerId: 'p1', shipTypeIds: ['carrack', 'carrack']),
        side2: NavalBattleSide(ownerId: 'p2', shipTypeIds: ['fluyte']),
      );
      final result = resolveSeaBattle(battle, 42);
      expect(result.survivingShipTypeIdsSide1, isNotEmpty);
      expect(result.survivingShipTypeIdsSide2, isNotEmpty);
      expect(
        result.survivingShipTypeIdsSide1.length + result.survivingShipTypeIdsSide2.length,
        lessThanOrEqualTo(3),
      );
    });

    test('returns all ships when total strength is zero', () {
      const battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(ownerId: 'p1', shipTypeIds: []),
        side2: NavalBattleSide(ownerId: 'p2', shipTypeIds: []),
      );
      final result = resolveSeaBattle(battle, 0);
      expect(result.survivingShipTypeIdsSide1, isEmpty);
      expect(result.survivingShipTypeIdsSide2, isEmpty);
    });
  });

  group('applyNavalBattleResults', () {
    test('replaces fleets in zone with surviving sides', () {
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
      );
      const battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(ownerId: 'p1', shipTypeIds: ['carrack']),
        side2: NavalBattleSide(ownerId: 'p2', shipTypeIds: ['fluyte']),
      );
      const result = NavalBattleResult(
        survivingShipTypeIdsSide1: ['carrack'],
        survivingShipTypeIdsSide2: [],
      );
      final updated = applyNavalBattleResults(game, battle, result, 'oldWorld');
      expect(updated.worldState.fleets.length, 1);
      expect(updated.worldState.fleets.single.ownerId, 'p1');
      expect(updated.worldState.fleets.single.shipTypeIds, ['carrack']);
    });
  });

  group('navalInterceptProbability', () {
    test('Patrol base is 0.3', () {
      expect(
        navalInterceptProbability(interceptorStrength: 10, targetStrength: 10, isBlockade: false),
        0.3,
      );
    });
    test('Blockade base is 0.5', () {
      expect(
        navalInterceptProbability(interceptorStrength: 10, targetStrength: 10, isBlockade: true),
        0.5,
      );
    });
    test('superior force adds bonus', () {
      final p = navalInterceptProbability(interceptorStrength: 20, targetStrength: 5, isBlockade: false);
      expect(p, 0.3 + 0.1);
    });
    test('inferior force subtracts penalty', () {
      final p = navalInterceptProbability(interceptorStrength: 5, targetStrength: 20, isBlockade: false);
      expect(p, 0.3 - 0.1);
    });
    test('result is clamped 0.05-0.85', () {
      expect(
        navalInterceptProbability(interceptorStrength: 1, targetStrength: 100, isBlockade: false),
        greaterThanOrEqualTo(0.05),
      );
      expect(
        navalInterceptProbability(interceptorStrength: 100, targetStrength: 1, isBlockade: true),
        lessThanOrEqualTo(0.85),
      );
    });
  });
}
