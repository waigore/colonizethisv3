import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/src/orders/order_suggestion_context.dart';

void main() {
  final minimalGame = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: 'gp1', displayName: 'P1', isHuman: true)],
  );
  const topology = MapTopology(nodes: [], edges: []);

  group('appendDiplomaticOrderForTrial', () {
    test('appends order for existing player list', () {
      const existing = DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: 'minorA',
      );
      const added = DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'minorB',
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': [existing],
        },
      );

      final updated = appendDiplomaticOrderForTrial(orders, 'gp1', added);

      expect(updated.diplomaticOrdersByPlayerId['gp1'], [existing, added]);
      expect(orders.diplomaticOrdersByPlayerId['gp1'], [existing]);
    });

    test('creates new player list when absent', () {
      const added = DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: 'gp2',
      );
      const orders = Orders();

      final updated = appendDiplomaticOrderForTrial(orders, 'gp9', added);

      expect(updated.diplomaticOrdersByPlayerId['gp9'], [added]);
      expect(orders.diplomaticOrdersByPlayerId.containsKey('gp9'), isFalse);
    });
  });

  group('acceptance wrappers', () {
    test('isNavalMoveOrderAccepted returns a boolean result', () {
      final accepted = isNavalMoveOrderAccepted(
        minimalGame,
        topology,
        'gp1',
        const Orders(),
        const NavalMoveOrder(fleetId: 'fleet1', destinationSeaZoneId: 'sea1'),
      );
      expect(accepted, isFalse);
    });

    test('isNavalMissionOrderAccepted returns a boolean result', () {
      final accepted = isNavalMissionOrderAccepted(
        minimalGame,
        topology,
        'gp1',
        const Orders(),
        const NavalMissionOrder(fleetId: 'fleet1', mission: 'patrol'),
      );
      expect(accepted, isFalse);
    });

    test('isDiplomaticOrderAccepted returns a boolean result', () {
      final accepted = isDiplomaticOrderAccepted(
        minimalGame,
        topology,
        'gp1',
        const Orders(),
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'minor1',
        ),
      );
      expect(accepted, isFalse);
    });
  });
}
