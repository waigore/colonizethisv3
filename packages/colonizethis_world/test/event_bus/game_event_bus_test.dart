import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'game_event_bus_extra_cases.dart';

void main() {
  group('GameEventBus', () {
    late DefaultGameEventBus bus;

    setUp(() {
      bus = DefaultGameEventBus();
    });

    tearDown(() {
      bus.dispose();
    });

    test('subscribe — single type receives matching event', () async {
      var callCount = 0;
      CombatResultEvent? received;
      bus.subscribe<CombatResultEvent>((e) {
        callCount++;
        received = e;
      });

      bus.publish(
        CombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
      );

      await Future.delayed(Duration.zero);
      expect(callCount, 1);
      expect(received?.provinceId, 'oldWorld|1');
    });

    test('subscribe — filtered: wrong type not received', () async {
      var callCount = 0;
      bus.subscribe<CombatResultEvent>((e) => callCount++);

      bus.publish(
        DiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'gp2',
          changeType: 'declare_war',
          turnNumber: 3,
        ),
      );

      await Future.delayed(Duration.zero);
      expect(callCount, 0);
    });

    test('subscribe — unsubscribe stops events', () async {
      var callCount = 0;
      final unsub = bus.subscribe<CombatResultEvent>((e) => callCount++);

      bus.publish(
        CombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
      );
      await Future.delayed(Duration.zero);
      expect(callCount, 1);

      unsub();

      bus.publish(
        CombatResultEvent(
          provinceId: 'oldWorld|2',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp2',
          turnNumber: 6,
        ),
      );
      await Future.delayed(Duration.zero);
      expect(callCount, 1);
    });

    test('subscribe — multiple handlers all called', () async {
      var count1 = 0;
      var count2 = 0;
      bus.subscribe<CombatResultEvent>((e) => count1++);
      bus.subscribe<CombatResultEvent>((e) => count2++);

      bus.publish(
        CombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
      );

      await Future.delayed(Duration.zero);
      expect(count1, 1);
      expect(count2, 1);
    });

    test('events stream receives all events in order', () async {
      final received = <GameEvent>[];
      bus.events.listen(received.add);

      bus.publish(
        ResearchCompleteEvent(
          playerId: 'gp1',
          techId: 'tech_naval',
          turnNumber: 1,
        ),
      );
      bus.publish(
        DiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'gp2',
          changeType: 'peace',
          turnNumber: 1,
        ),
      );
      bus.publish(
        CombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 1,
        ),
      );

      await Future.delayed(Duration.zero);
      expect(received.length, 3);
      expect(received[0], isA<ResearchCompleteEvent>());
      expect(received[1], isA<DiplomacyChangeEvent>());
      expect(received[2], isA<CombatResultEvent>());
    });
  });
  registerGameEventBusExtraCases();
}
