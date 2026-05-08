import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveSeaBattle', () {
    test('returns surviving ships with casualties by strength ratio', () {
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('battle_p1', ['carrack', 'carrack']),
        ),
        side2: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('battle_p2', ['fluyte']),
        ),
      );
      final result = resolveSeaBattle(battle, 42);
      expect(result.survivingShipsSide1, isNotEmpty);
      expect(result.survivingShipsSide2, isNotEmpty);
      expect(
        result.survivingShipsSide1.length + result.survivingShipsSide2.length,
        lessThanOrEqualTo(3),
      );
    });

    test('returns all ships when total strength is zero', () {
      const battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(ownerId: 'p1', ships: []),
        side2: NavalBattleSide(ownerId: 'p2', ships: []),
      );
      final result = resolveSeaBattle(battle, 0);
      expect(result.survivingShipsSide1, isEmpty);
      expect(result.survivingShipsSide2, isEmpty);
    });

    test('feeding coverage multiplies raw naval strength like land combat morale', () {
      final raw = navalStrength(['carrack', 'carrack']);
      expect(raw * moraleMultiplierForFeedingCoverage(1.0), raw);
      expect(raw * moraleMultiplierForFeedingCoverage(0.6), raw * 0.75);
      expect(raw * moraleMultiplierForFeedingCoverage(0.0), raw * 0.5);
    });

    test('does not retreat when retreat is disallowed by topology/relation gate', () {
      final battle = BattleContextSea(
        seaZoneId: 'sea1',
        side1: NavalBattleSide(
          ownerId: 'p1',
          ships: legacyShipInstancesForFleet('ret_p1', ['carrack', 'carrack']),
          mission: FleetMission.patrol,
        ),
        side2: NavalBattleSide(
          ownerId: 'p2',
          ships: legacyShipInstancesForFleet('ret_p2', ['fluyte', 'fluyte']),
          mission: FleetMission.blockade,
        ),
      );
      final result = resolveSeaBattle(
        battle,
        42,
        side1CanRetreat: false,
        side2CanRetreat: false,
      );
      expect(result.side1Retreated, isFalse);
      expect(result.side2Retreated, isFalse);
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
    });

    test('preserves mission on recreated surviving fleets', () {
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
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
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
    });
  });

  group('navalInterceptProbability', () {
    test('Patrol uses mission-factor * ratio', () {
      // Ratio = 5/(5+5) = 0.5, patrol factor = 0.5 => 0.25
      expect(
        navalInterceptProbability(interceptorScore: 5, targetFleeScore: 5, isBlockade: false),
        0.25,
      );
    });

    test('Blockade uses mission-factor * ratio', () {
      // Ratio = 8/(8+2) = 0.8, blockade factor = 0.9 => 0.72
      expect(
        navalInterceptProbability(interceptorScore: 8, targetFleeScore: 2, isBlockade: true),
        closeTo(0.72, 1e-9),
      );
    });

    test('result is clamped 0.05-0.85', () {
      expect(
        navalInterceptProbability(interceptorScore: 0, targetFleeScore: 100, isBlockade: false),
        greaterThanOrEqualTo(0.05),
      );
      expect(
        navalInterceptProbability(interceptorScore: 100, targetFleeScore: 0, isBlockade: true),
        lessThanOrEqualTo(0.85),
      );
    });
  });
}
