import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/event_bridge/game_event_bridge.dart';

void main() {
  suppressLogsForTests();

  group('GameEventBridge forwarding', () {
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
          side1CasualtyCount: 1,
          side2CasualtyCount: 3,
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
      expect(evt.side1CasualtyCount, 1);
      expect(evt.side2CasualtyCount, 3);
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
          orderKind: OrderKind.work,
          orderSummary: 'Build road',
          reasonCode: 'insufficient_treasury',
        ),
      );
      await pumpEventQueue();

      expect(received, hasLength(1));
      final evt = received.first;
      expect(evt.playerId, 'gp1');
      expect(evt.orderKind, OrderKind.work);
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
  });
}
