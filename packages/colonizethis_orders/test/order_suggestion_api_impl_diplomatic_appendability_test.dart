import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('suggestDiplomaticOrders appendability', () {
    test(
      'does not suggest toward target already in draft diplomatic orders',
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
        final withPending = Orders(
          diplomaticOrdersByPlayerId: {
            'gp1': [
              const DiplomaticOrder(
                type: DiplomaticOrderType.alliance,
                targetFactionId: 'gp2',
              ),
            ],
          },
        );
        final list = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          withPending,
        );
        expect(list.where((o) => o.targetFactionId == 'gp2'), isEmpty);
      },
    );

    test(
      'suggestDiplomaticOrders: cumulative list appendable and validates',
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
        final suggestions = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final byTarget = <String, List<DiplomaticOrderType>>{};
        for (final o in suggestions) {
          byTarget.putIfAbsent(o.targetFactionId, () => []).add(o.type);
        }
        for (final e in byTarget.entries) {
          final types = e.value;
          expect(
            types.toSet().length,
            types.length,
            reason: 'at most one suggestion per type per target ${e.key}',
          );
          final nonEconomic = types
              .where(
                (t) =>
                    t != DiplomaticOrderType.grantAid &&
                    t != DiplomaticOrderType.setSubsidy,
              )
              .length;
          expect(
            nonEconomic,
            lessThanOrEqualTo(1),
            reason:
                'at most one primary diplomatic suggestion per target ${e.key}',
          );
        }
        final eng = OrderEngine();
        for (final o in suggestions) {
          final addResult = eng.addDiplomaticOrderWithContext(
            game,
            topology,
            'gp1',
            o,
          );
          expect(
            addResult.isAccepted,
            isTrue,
            reason: '${o.type} ${o.targetFactionId} after prior suggestions',
          );
        }
        final validateResults = eng.validatePlayerOrdersWithContext(
          game,
          topology,
          'gp1',
        );
        expect(validateResults, isNotEmpty);
        expect(
          validateResults.every((r) => r.isAccepted),
          isTrue,
          reason: 'full merged diplomatic list validates',
        );
      },
    );

    test(
      'removing pending diplomatic order restores suggestions for that target',
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
        final pending = Orders(
          diplomaticOrdersByPlayerId: {
            'gp1': [
              const DiplomaticOrder(
                type: DiplomaticOrderType.alliance,
                targetFactionId: 'gp2',
              ),
            ],
          },
        );
        expect(
          api
              .suggestDiplomaticOrders(view, game, topology, pending)
              .where((o) => o.targetFactionId == 'gp2'),
          isEmpty,
        );
        final afterClear = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(afterClear.where((o) => o.targetFactionId == 'gp2'), isNotEmpty);
      },
    );
  });
}
