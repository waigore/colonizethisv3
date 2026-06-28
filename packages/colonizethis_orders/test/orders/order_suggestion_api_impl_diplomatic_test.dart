import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('suggestDiplomaticOrders', () {
    test(
      'returns alliance (single diplo per target) for other GP when at peace and not allied',
      () {
        const api = DefaultOrderSuggestionAPI();
        const topology = MapTopology(nodes: [], edges: []);
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
        final view = buildPlayerView(game, topology, 'gp1');
        final list = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList();
        expect(toGp2, hasLength(1));
        expect(toGp2.single.type, DiplomaticOrderType.alliance);
      },
    );

    test('returns declareWar toward GP when at peace and already allied', () {
      const api = DefaultOrderSuggestionAPI();
      const topology = MapTopology(nodes: [], edges: []);
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
            level: RelationLevel.allied,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList();
      expect(toGp2, hasLength(1));
      expect(toGp2.single.type, DiplomaticOrderType.declareWar);
    });

    test(
      'returns breakAlliance toward GP when a formal alliance exists at peace',
      () {
        const api = DefaultOrderSuggestionAPI();
        const topology = MapTopology(nodes: [], edges: []);
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
              level: RelationLevel.allied,
              formalAlliance: true,
            ),
          ],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        final list = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList();
        expect(toGp2, hasLength(1));
        expect(toGp2.single.type, DiplomaticOrderType.breakAlliance);
        // Appendability: the emitted break-alliance suggestion validates.
        final eng = OrderEngine();
        expect(
          eng
              .addDiplomaticOrderWithContext(game, topology, 'gp1', toGp2.single)
              .isAccepted,
          isTrue,
        );
      },
    );

    test(
      'does not return breakAlliance when relation level is allied but no formal alliance',
      () {
        const api = DefaultOrderSuggestionAPI();
        const topology = MapTopology(nodes: [], edges: []);
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
              level: RelationLevel.allied,
            ),
          ],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        final list = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          list.where((o) => o.type == DiplomaticOrderType.breakAlliance),
          isEmpty,
        );
      },
    );

    test('returns offerPeace when at war with another GP', () {
      const api = DefaultOrderSuggestionAPI();
      const topology = MapTopology(nodes: [], edges: []);
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
            state: RelationState.atWar,
            level: RelationLevel.hostile,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final offerPeace = list
          .where((o) => o.type == DiplomaticOrderType.offerPeace)
          .toList();
      expect(offerPeace.any((o) => o.targetFactionId == 'gp2'), isTrue);
    });

    test('returns alliance candidate when at peace and not allied', () {
      const api = DefaultOrderSuggestionAPI();
      const topology = MapTopology(nodes: [], edges: []);
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
            level: RelationLevel.friendly,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final alliance = list
          .where((o) => o.type == DiplomaticOrderType.alliance)
          .toList();
      expect(alliance.any((o) => o.targetFactionId == 'gp2'), isTrue);
    });
  });
}
