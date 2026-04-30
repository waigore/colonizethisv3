import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'package:colonizethis_data/colonizethis_data.dart' show kTechIdCropRotation;
List<String> _researchMessages(List<LogEvent> events) => [
      for (final e in events)
        if (e.message.contains('logic: research')) e.message,
    ];

void main() {
  group('research logging', () {
    late List<LogEvent> capturedEvents;
    late void Function(LogEvent) listener;

    setUp(() {
      capturedEvents = [];
      listener = capturedEvents.add;
      Logger.addLogListener(listener);
      Logger.level = Level.info;
    });

    tearDown(() {
      Logger.removeLogListener(listener);
      capturedEvents.clear();
      Logger.level = Level.info;
    });

    test('resolveResearchPhase emits phase start/end when no research orders', () {
      final player = Player(
        id: 'p1',
        displayName: 'Player 1',
        isHuman: true,
        treasury: 1000,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.research, turnNumber: 7),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g', worldState: world, players: [player]);

      resolveResearchPhase(game, const Orders());

      final lines = _researchMessages(capturedEvents);
      expect(
        lines.any(
          (m) => m.contains('logic: research phase start') && m.contains('turn=7'),
        ),
        isTrue,
      );
      expect(
        lines.any(
          (m) =>
              m.contains('logic: research phase end') &&
              m.contains('turn=7') &&
              m.contains('playersWithOrders=0'),
        ),
        isTrue,
      );
    });

    test('resolveResearchPhase emits apply summary when player has research orders',
        () {
      final player = Player(
        id: 'p1',
        displayName: 'Player 1',
        isHuman: true,
        treasury: 2000,
        techUnlocked: const {},
        researchSlots: 1,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.research, turnNumber: 3),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g', worldState: world, players: [player]);
      final orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.maximum,
            ),
          ],
        },
      );

      resolveResearchPhase(game, orders);

      final lines = _researchMessages(capturedEvents);
      expect(
        lines.any(
          (m) =>
              m.contains('logic: research apply') &&
              m.contains('turn=3') &&
              m.contains('playerId=p1') &&
              m.contains('orders=1'),
        ),
        isTrue,
      );
      expect(
        lines.any(
          (m) =>
              m.contains('logic: research phase end') &&
              m.contains('turn=3') &&
              m.contains('playersWithOrders=1'),
        ),
        isTrue,
      );
    });
  });
}
