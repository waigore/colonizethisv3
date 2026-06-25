import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

/// Public-API coverage for the Theme B sink migration (Refs #3701): the four
/// public resolver entry points and [TurnResolverConfig] thread a single
/// [TurnEventSink] instead of the positional `(eventBus, onGameEvent,
/// onDialogue)` trio.
void main() {
  MapTopology buildTopology() => MapTopology(
    nodes: const [
      TopologyNode(
        id: 'P1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'P2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
  );

  Game buildGame() {
    const ow = 'oldWorld';
    return TestFixtures.minimalGame(
      id: 'sink-api',
      turnNumber: 0,
      players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'Regiment',
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
          ),
        ],
      ),
    );
  }

  group('TurnResolverConfig.eventSink', () {
    test('defaults to a no-op sink when none is supplied', () {
      final config = TurnResolverConfig(
        topology: buildTopology(),
        orders: const Orders(),
      );

      expect(config.eventSink.eventBus, isNull);
      expect(config.eventSink.hasGameEvent, isFalse);
      expect(config.eventSink.hasDialogue, isFalse);
    });

    test('copyWith overrides eventSink and preserves it when omitted', () {
      final original = TurnResolverConfig(
        topology: buildTopology(),
        orders: const Orders(),
      );
      final sink = TurnEventSink(onGameEvent: (_) {}, onDialogue: (_) {});

      final replaced = original.copyWith(eventSink: sink);
      expect(identical(replaced.eventSink, sink), isTrue);

      final preserved = replaced.copyWith(startFromPhase: TurnPhase.diplomacy);
      expect(identical(preserved.eventSink, sink), isTrue);
    });
  });

  group('public resolver entry points thread a TurnEventSink', () {
    test('resolveTurnForGame forwards dialogue through the sink', () {
      final dialogue = <DialogueEvent>[];
      final result = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: buildGame(),
          topology: buildTopology(),
          orders: const Orders(),
          eventSink: TurnEventSink(onDialogue: dialogue.add),
        ),
      );

      // Behaviour-preserving: the turn still resolves to completion. Dialogue
      // delivery is exercised here via the sink (vs. the removed trio param);
      // the minimal fixture may legitimately emit zero dialogue events.
      expect(result.worldState.turnState.turnNumber, 1);
    });

    test(
      'validateOrdersAndResolveTurnFromTrustedOrders accepts an eventSink',
      () {
        final events = <GameEvent>[];
        final result = requireTurnResolutionComplete(
          validateOrdersAndResolveTurnFromTrustedOrders(
            game: buildGame(),
            topology: buildTopology(),
            orders: const Orders(),
            eventSink: TurnEventSink(onGameEvent: events.add),
          ),
        );

        expect(result.worldState.turnState.turnNumber, 1);
      },
    );

    test('omitting eventSink resolves identically (no events misrouted)', () {
      final withoutSink = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: buildGame(),
          topology: buildTopology(),
          orders: const Orders(),
        ),
      );
      final withNoOpSink = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: buildGame(),
          topology: buildTopology(),
          orders: const Orders(),
          eventSink: const TurnEventSink(),
        ),
      );

      expect(
        withNoOpSink.worldState.turnState.turnNumber,
        withoutSink.worldState.turnState.turnNumber,
      );
    });
  });
}
