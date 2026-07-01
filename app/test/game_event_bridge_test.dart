import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/game_event_bridge.dart';

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

    test('forwards NavalCombatResultEvent', () async {
      final received = <AppNavalCombatResultEvent>[];
      appBus.on<AppNavalCombatResultEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        NavalCombatResultEvent(
          seaZoneId: 's3',
          side1OwnerId: 'gp1',
          side2OwnerId: 'gp2',
          outcomeName: 'side1Victory',
          turnNumber: 4,
          winnerOwnerId: 'gp1',
          side1Retreated: false,
          side2Retreated: true,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      final evt = received.first;
      expect(evt.seaZoneId, 's3');
      expect(evt.side1OwnerId, 'gp1');
      expect(evt.side2OwnerId, 'gp2');
      expect(evt.outcomeName, 'side1Victory');
      expect(evt.turnNumber, 4);
      expect(evt.winnerOwnerId, 'gp1');
      expect(evt.side1Retreated, isFalse);
      expect(evt.side2Retreated, isTrue);
    });

    test('forwards ProvinceCapturedEvent', () async {
      final received = <AppProvinceCapturedEvent>[];
      appBus.on<AppProvinceCapturedEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        ProvinceCapturedEvent(
          provinceId: 'newWorld|3',
          previousOwnerId: 'gp2',
          newOwnerId: 'gp1',
          turnNumber: 7,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.first.provinceId, 'newWorld|3');
      expect(received.first.previousOwnerId, 'gp2');
      expect(received.first.newOwnerId, 'gp1');
      expect(received.first.turnNumber, 7);
    });

    test('forwards DiplomacyChangeEvent', () async {
      final received = <AppDiplomacyChangeEvent>[];
      appBus.on<AppDiplomacyChangeEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        DiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'gp2',
          changeType: 'declare_war',
          turnNumber: 3,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      final evt = received.first;
      expect(evt.actorId, 'gp1');
      expect(evt.targetId, 'gp2');
      expect(evt.changeType, 'declare_war');
      expect(evt.turnNumber, 3);
    });

    test('forwards ResearchCompleteEvent', () async {
      final received = <AppResearchCompleteEvent>[];
      appBus.on<AppResearchCompleteEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        ResearchCompleteEvent(
          playerId: 'gp1',
          techId: 'tech_naval',
          turnNumber: 10,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      final evt = received.first;
      expect(evt.playerId, 'gp1');
      expect(evt.techId, 'tech_naval');
      expect(evt.turnNumber, 10);
    });

    test('forwards VictorySetEvent', () async {
      final received = <AppVictorySetEvent>[];
      appBus.on<AppVictorySetEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        VictorySetEvent(
          winnerPlayerId: 'gp1',
          victoryType: 'military',
          turnNumber: 50,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      final evt = received.first;
      expect(evt.winnerPlayerId, 'gp1');
      expect(evt.victoryType, 'military');
      expect(evt.turnNumber, 50);
    });

    test('forwards OrderRejectedEvent', () async {
      final received = <AppOrderRejectedEvent>[];
      appBus.on<AppOrderRejectedEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        OrderRejectedEvent(
          playerId: 'gp1',
          orderSummary: 'Build road',
          reasonCode: 'insufficient_treasury',
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      final evt = received.first;
      expect(evt.playerId, 'gp1');
      expect(evt.orderSummary, 'Build road');
      expect(evt.reasonCode, 'insufficient_treasury');
    });

    test('forwards WorkOrderCompletedEvent', () async {
      final received = <AppWorkOrderCompletedEvent>[];
      appBus.on<AppWorkOrderCompletedEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        WorkOrderCompletedEvent(
          playerId: 'gp1',
          unitId: 'u1',
          workTarget: kWorkTargetBuildRoad,
          targetTileKey: 'oldWorld|p1|3|4',
          provinceId: 'oldWorld|p1',
          turnNumber: 2,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      final evt = received.first;
      expect(evt.playerId, 'gp1');
      expect(evt.unitId, 'u1');
      expect(evt.workTarget, kWorkTargetBuildRoad);
      expect(evt.targetTileKey, 'oldWorld|p1|3|4');
      expect(evt.provinceId, 'oldWorld|p1');
      expect(evt.turnNumber, 2);
    });

    test('forwards PlayerProvinceDiscoveredEvent', () async {
      final received = <AppPlayerProvinceDiscoveredEvent>[];
      appBus.on<AppPlayerProvinceDiscoveredEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        PlayerProvinceDiscoveredEvent(
          playerId: 'gp1',
          provinceId: 'newWorld|p3',
          turnNumber: 6,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.first.playerId, 'gp1');
      expect(received.first.provinceId, 'newWorld|p3');
      expect(received.first.turnNumber, 6);
    });

    test('forwards PlayerSeaZoneDiscoveredEvent', () async {
      final received = <AppPlayerSeaZoneDiscoveredEvent>[];
      appBus.on<AppPlayerSeaZoneDiscoveredEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        PlayerSeaZoneDiscoveredEvent(
          playerId: 'gp1',
          seaZoneId: 'oldWorld|s3',
          turnNumber: 6,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.first.playerId, 'gp1');
      expect(received.first.seaZoneId, 'oldWorld|s3');
      expect(received.first.turnNumber, 6);
    });

    test('forwards OvertureAdvancedEvent', () async {
      final received = <AppOvertureAdvancedEvent>[];
      appBus.on<AppOvertureAdvancedEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        OvertureAdvancedEvent(
          offererGpId: 'gp1',
          targetFactionId: 'gp2',
          newStage: 'embassy',
          turnNumber: 8,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.first.offererGpId, 'gp1');
      expect(received.first.targetFactionId, 'gp2');
      expect(received.first.newStage, 'embassy');
      expect(received.first.turnNumber, 8);
    });

    test('forwards SpyCaughtEvent', () async {
      final received = <AppSpyCaughtEvent>[];
      appBus.on<AppSpyCaughtEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        SpyCaughtEvent(
          unitId: 'spy1',
          spyOwnerId: 'gp1',
          territoryOwnerId: 'gp2',
          provinceId: 'oldWorld|p1',
          turnNumber: 5,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      final evt = received.first;
      expect(evt.unitId, 'spy1');
      expect(evt.spyOwnerId, 'gp1');
      expect(evt.territoryOwnerId, 'gp2');
      expect(evt.provinceId, 'oldWorld|p1');
      expect(evt.turnNumber, 5);
    });

    test('forwards SpyDefectedEvent', () async {
      final received = <AppSpyDefectedEvent>[];
      appBus.on<AppSpyDefectedEvent>().listen(received.add);
      bridge.start();

      logicBus.publish(
        SpyDefectedEvent(
          unitId: 'spy2',
          previousOwnerId: 'gp1',
          newOwnerId: 'gp2',
          provinceId: 'oldWorld|p2',
          turnNumber: 6,
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      final evt = received.first;
      expect(evt.unitId, 'spy2');
      expect(evt.previousOwnerId, 'gp1');
      expect(evt.newOwnerId, 'gp2');
      expect(evt.provinceId, 'oldWorld|p2');
      expect(evt.turnNumber, 6);
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
