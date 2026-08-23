import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:logger/logger.dart';

void registerGameEventBusExtraCases() {
  group('extra', () {
    late DefaultGameEventBus bus;
    setUp(() {
      bus = DefaultGameEventBus();
    });
    tearDown(() {
      bus.dispose();
    });
    test('subscribe — OrderRejectedEvent is sealed subtype', () async {
      var callCount = 0;
      bus.subscribe<OrderRejectedEvent>((e) => callCount++);

      bus.publish(
        OrderRejectedEvent(
          playerId: 'gp1',
          orderKind: OrderKind.work,
          orderSummary: 'Build road',
          reasonCode: 'insufficient_treasury',
        ),
      );

      await Future.delayed(Duration.zero);
      expect(callCount, 1);
    });

    test('subscribe — VictorySetEvent is sealed subtype', () async {
      var callCount = 0;
      bus.subscribe<VictorySetEvent>((e) => callCount++);

      bus.publish(
        VictorySetEvent(
          winnerPlayerId: 'gp1',
          victoryType: 'military',
          turnNumber: 100,
        ),
      );

      await Future.delayed(Duration.zero);
      expect(callCount, 1);
    });

    test('subscribe — ProvinceCapturedEvent is sealed subtype', () async {
      var callCount = 0;
      bus.subscribe<ProvinceCapturedEvent>((e) => callCount++);

      bus.publish(
        ProvinceCapturedEvent(
          provinceId: 'newWorld|2',
          previousOwnerId: 'gp2',
          newOwnerId: 'gp1',
          turnNumber: 10,
        ),
      );

      await Future.delayed(Duration.zero);
      expect(callCount, 1);
    });

    test('publish null event safe (no-op)', () {
      bus.publish(
        ResearchCompleteEvent(
          playerId: 'gp1',
          techId: 'tech_naval',
          turnNumber: 1,
        ),
      );
    });

    test('publish logs event line with event type and summary', () async {
      final capturedEvents = <LogEvent>[];
      void listener(LogEvent event) => capturedEvents.add(event);
      Logger.addLogListener(listener);
      addTearDown(() => Logger.removeLogListener(listener));

      bus.publish(
        DiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'gp2',
          changeType: 'peace',
          turnNumber: 2,
        ),
      );

      await Future<void>.delayed(Duration.zero);
      final line = capturedEvents
          .where((e) => e.level == Level.info)
          .map((e) => e.message.toString())
          .firstWhere((m) => m.contains('world: event=DiplomacyChangeEvent'));
      expect(line, contains('turn=2'));
      expect(line, contains('actorId=gp1'));
      expect(line, contains('targetId=gp2'));
      expect(line, contains('changeType=peace'));
    });

    test('publish truncates long event summaries with marker', () async {
      final capturedEvents = <LogEvent>[];
      void listener(LogEvent event) => capturedEvents.add(event);
      Logger.addLogListener(listener);
      addTearDown(() => Logger.removeLogListener(listener));

      final longSummary = List.filled(600, 'x').join();
      bus.publish(
        OrderRejectedEvent(
          playerId: 'gp1',
          orderKind: OrderKind.move,
          orderSummary: longSummary,
          reasonCode: 'invalid_order',
        ),
      );

      await Future<void>.delayed(Duration.zero);
      final line = capturedEvents
          .where((e) => e.level == Level.info)
          .map((e) => e.message.toString())
          .firstWhere((m) => m.contains('world: event=OrderRejectedEvent'));
      expect(line, contains('truncated=true'));
    });
  });
}
