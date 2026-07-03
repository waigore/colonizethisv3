import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('GameEvent', () {
    test('CombatResultEvent has required fields', () {
      const e = CombatResultEvent(
        provinceId: 'oldWorld|1',
        attackerId: 'gp1',
        defenderId: 'gp2',
        winnerId: 'gp1',
        turnNumber: 5,
        casualties: {'gp2': 2},
      );
      expect(e.provinceId, 'oldWorld|1');
      expect(e.attackerId, 'gp1');
      expect(e.defenderId, 'gp2');
      expect(e.winnerId, 'gp1');
      expect(e.turnNumber, 5);
      expect(e.casualties, {'gp2': 2});
    });

    test('ProvinceCapturedEvent has required fields', () {
      const e = ProvinceCapturedEvent(
        provinceId: 'newWorld|2',
        previousOwnerId: 'gp2',
        newOwnerId: 'gp1',
        turnNumber: 10,
      );
      expect(e.provinceId, 'newWorld|2');
      expect(e.previousOwnerId, 'gp2');
      expect(e.newOwnerId, 'gp1');
      expect(e.turnNumber, 10);
    });

    test('DiplomacyChangeEvent has required fields', () {
      const e = DiplomacyChangeEvent(
        actorId: 'gp1',
        targetId: 'gp2',
        changeType: 'declare_war',
        turnNumber: 3,
      );
      expect(e.actorId, 'gp1');
      expect(e.targetId, 'gp2');
      expect(e.changeType, 'declare_war');
      expect(e.turnNumber, 3);
    });

    test('ResearchCompleteEvent has required fields', () {
      const e = ResearchCompleteEvent(
        playerId: 'gp1',
        techId: 'tech_naval',
        turnNumber: 7,
      );
      expect(e.playerId, 'gp1');
      expect(e.techId, 'tech_naval');
      expect(e.turnNumber, 7);
    });

    test('VictorySetEvent has required fields', () {
      const e = VictorySetEvent(
        winnerPlayerId: 'gp1',
        victoryType: 'military',
        turnNumber: 100,
      );
      expect(e.winnerPlayerId, 'gp1');
      expect(e.victoryType, 'military');
      expect(e.turnNumber, 100);
    });

    test('OrderRejectedEvent has required fields', () {
      const e = OrderRejectedEvent(
        playerId: 'gp1',
        orderSummary: 'Build road',
        reasonCode: 'insufficient_treasury',
      );
      expect(e.playerId, 'gp1');
      expect(e.orderSummary, 'Build road');
      expect(e.reasonCode, 'insufficient_treasury');
    });

    test('NavalCombatResultEvent has required fields', () {
      const e = NavalCombatResultEvent(
        seaZoneId: 's2',
        side1OwnerId: 'gp1',
        side2OwnerId: 'gp2',
        outcomeName: 'side1Victory',
        turnNumber: 4,
        winnerOwnerId: 'gp1',
        side1Retreated: false,
        side2Retreated: true,
      );
      expect(e.seaZoneId, 's2');
      expect(e.winnerOwnerId, 'gp1');
      expect(e.side2Retreated, isTrue);
    });

    test('SpyCaughtEvent has required fields', () {
      const e = SpyCaughtEvent(
        unitId: 'spy1',
        spyOwnerId: 'gp1',
        territoryOwnerId: 'gp2',
        provinceId: 'oldWorld|p1',
        turnNumber: 3,
      );
      expect(e.unitId, 'spy1');
      expect(e.spyOwnerId, 'gp1');
      expect(e.territoryOwnerId, 'gp2');
      expect(e.provinceId, 'oldWorld|p1');
      expect(e.turnNumber, 3);
    });

    test('SpyDefectedEvent has required fields', () {
      const e = SpyDefectedEvent(
        unitId: 'spy2',
        previousOwnerId: 'gp1',
        newOwnerId: 'gp2',
        provinceId: 'oldWorld|p2',
        turnNumber: 4,
      );
      expect(e.unitId, 'spy2');
      expect(e.previousOwnerId, 'gp1');
      expect(e.newOwnerId, 'gp2');
      expect(e.provinceId, 'oldWorld|p2');
      expect(e.turnNumber, 4);
    });
  });
}
