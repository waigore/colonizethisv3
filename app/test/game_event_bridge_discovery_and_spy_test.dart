// Discovery, overture, and spy forwarding for GameEventBridge
// (Refs #4720 Slice G).

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
  });
}
