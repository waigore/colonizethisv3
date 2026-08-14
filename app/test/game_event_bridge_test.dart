import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/event_bridge/game_event_bridge.dart';

void main() {
  suppressLogsForTests();

  group('GameEventBridge', () {
    late DefaultGameEventBus logicBus;
    late AppEventBus appBus;
    late GameEventBridge bridge;

    setUp(() {
      logicBus = DefaultGameEventBus();
      appBus = AppEventBus.create();
      bridge = GameEventBridge(logicBus: logicBus, appBus: appBus);
    });

    tearDown(() {
      bridge.dispose();
      logicBus.dispose();
      appBus.dispose();
    });

    test('start() begins forwarding events', () async {
      final received = <GameToUIEvent>[];
      appBus.on<GameToUIEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        CombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.first, isA<AppCombatResultEvent>());
      final evt = received.first as AppCombatResultEvent;
      expect(evt.provinceId, 'oldWorld|1');
      expect(evt.attackerId, 'gp1');
      expect(evt.defenderId, 'gp2');
      expect(evt.winnerId, 'gp1');
      expect(evt.turnNumber, 5);
    });

    test('stop() halts forwarding', () async {
      final received = <GameToUIEvent>[];
      appBus.on<GameToUIEvent>().listen(received.add);
      bridge.start();
      bridge.stop();

      logicBus.publish(
        CombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
      );
      await pumpEventQueue();

      expect(received, isEmpty);
    });

    test('forwarded events maintain emission order', () async {
      final received = <GameToUIEvent>[];
      appBus.on<GameToUIEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        ResearchCompleteEvent(playerId: 'gp1', techId: 'tech_1', turnNumber: 1),
      );
      logicBus.publish(
        DiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'gp2',
          changeType: 'peace',
          turnNumber: 1,
        ),
      );
      logicBus.publish(
        CombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          winnerId: 'gp1',
          turnNumber: 1,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(3));
      expect(received[0], isA<AppResearchCompleteEvent>());
      expect(received[1], isA<AppDiplomacyChangeEvent>());
      expect(received[2], isA<AppCombatResultEvent>());
    });

    test('forwards GeneralMedalGainedEvent', () async {
      final received = <GameToUIEvent>[];
      appBus.on<GameToUIEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        const GeneralMedalGainedEvent(
          playerId: 'gp1',
          generalId: 'g1',
          provinceId: 'oldWorld|cap',
          newMedals: 2,
          turnNumber: 4,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.single, isA<AppGeneralMedalGainedEvent>());
      final evt = received.single as AppGeneralMedalGainedEvent;
      expect(evt.playerId, 'gp1');
      expect(evt.generalId, 'g1');
      expect(evt.provinceId, 'oldWorld|cap');
      expect(evt.newMedals, 2);
      expect(evt.turnNumber, 4);
    });

    test('dispose after stop is safe', () {
      bridge.start();
      bridge.stop();
      expect(() => bridge.dispose(), returnsNormally);
    });

    test('double start is no-op', () async {
      final received = <GameToUIEvent>[];
      appBus.on<GameToUIEvent>().listen(received.add);
      bridge.start();
      bridge.start();

      logicBus.publish(
        CombatResultEvent(
          provinceId: 'oldWorld|1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          winnerId: 'gp1',
          turnNumber: 5,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
    });
  });
}
