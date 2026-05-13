import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_logic/src/world/player_view.dart';
import 'package:colonizethis_logic/src/world/unit_lookup.dart';

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

  group('nextOvertureStage', () {
    test('follows expected progression', () {
      expect(
        nextOvertureStage(OvertureStage.none),
        OvertureStage.tradeConsulate,
      );
      expect(
        nextOvertureStage(OvertureStage.tradeConsulate),
        OvertureStage.embassy,
      );
      expect(nextOvertureStage(OvertureStage.embassy), OvertureStage.nap);
      expect(nextOvertureStage(OvertureStage.nap), OvertureStage.joinEmpire);
    });

    test('returns null when already at final stage', () {
      expect(nextOvertureStage(OvertureStage.joinEmpire), isNull);
    });
  });

  group('acceptance wrappers', () {
    test('isNavalMoveOrderAccepted returns a boolean result', () {
      final accepted = isNavalMoveOrderAccepted(
        minimalGame,
        topology,
        'gp1',
        const Orders(),
        const NavalMoveOrder(
          fleetId: 'fleet1',
          destinationSeaZoneId: 'sea1',
        ),
      );
      expect(accepted, isFalse);
    });

    test('isNavalMissionOrderAccepted returns a boolean result', () {
      final accepted = isNavalMissionOrderAccepted(
        minimalGame,
        topology,
        'gp1',
        const Orders(),
        const NavalMissionOrder(
          fleetId: 'fleet1',
          mission: 'patrol',
        ),
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

    test(
      'isDiplomaticOrderAccepted matches default path when view/units shared',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              state: RelationState.atPeace,
              level: RelationLevel.neutral,
            ),
          ],
        );
        const candidate = DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'gp2',
        );
        final sharedView = buildPlayerView(game, topology, 'gp1');
        final sharedUnits = unitsByIdFromWorld(game.worldState);
        final defaultPath = isDiplomaticOrderAccepted(
          game,
          topology,
          'gp1',
          const Orders(),
          candidate,
        );
        final sharedPath = isDiplomaticOrderAccepted(
          game,
          topology,
          'gp1',
          const Orders(),
          candidate,
          view: sharedView,
          unitsById: sharedUnits,
        );
        expect(sharedPath, defaultPath);
        expect(defaultPath, isTrue);
      },
    );
  });
}
