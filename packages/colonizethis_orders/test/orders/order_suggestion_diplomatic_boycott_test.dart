/// Tests for the `boycott` candidate in `suggestDiplomaticOrders` (Refs #3758
/// R8). SPEC/program/order-suggestions.md § Boycott candidate;
/// SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).
library;

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Game _twoGpGame({
  bool holdsColony = true,
  RelationState state = RelationState.atPeace,
  RelationLevel level = RelationLevel.neutral,
  List<BoycottState> boycotts = const [],
  List<MinorNation> minors = const [],
}) {
  return Game(
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
    minorNations: minors,
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        state: state,
        level: level,
      ),
    ],
    colonyStates: holdsColony
        ? const [
            ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1),
          ]
        : const [],
    boycottStates: boycotts,
  );
}

void main() {
  const api = DefaultOrderSuggestionAPI();
  const topology = MapTopology(nodes: [], edges: []);

  group('suggestDiplomaticOrders boycott candidate', () {
    test(
      'emits a boycott toward another GP at peace when the issuer holds a colony',
      () {
        final game = _twoGpGame();
        final view = buildPlayerView(game, topology, 'gp1');
        final list = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final boycotts = list.where(
          (o) =>
              o.type == DiplomaticOrderType.boycott &&
              o.targetFactionId == 'gp2',
        );
        expect(boycotts, hasLength(1));
        // Appendability: the emitted boycott validates against the engine.
        final eng = OrderEngine();
        expect(
          eng
              .addDiplomaticOrderWithContext(
                game,
                topology,
                'gp1',
                boycotts.single,
              )
              .isAccepted,
          isTrue,
        );
      },
    );

    test(
      'boycott coexists with the single non-economic candidate for the same GP',
      () {
        // Neutral at-peace pair yields an alliance as the non-economic winner;
        // the independent boycott pass adds the boycott alongside it.
        final game = _twoGpGame();
        final view = buildPlayerView(game, topology, 'gp1');
        final list = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final toGp2 = list
            .where((o) => o.targetFactionId == 'gp2')
            .map((o) => o.type)
            .toSet();
        expect(toGp2, contains(DiplomaticOrderType.alliance));
        expect(toGp2, contains(DiplomaticOrderType.boycott));
      },
    );

    test('does not emit a boycott when the issuer holds no colony', () {
      final game = _twoGpGame(holdsColony: false);
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(list.where((o) => o.type == DiplomaticOrderType.boycott), isEmpty);
    });

    test('does not emit a duplicate boycott when one already exists', () {
      final game = _twoGpGame(
        boycotts: const [
          BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 1),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(list.where((o) => o.type == DiplomaticOrderType.boycott), isEmpty);
    });

    test('does not emit a boycott toward a Minor/Tribe target', () {
      final game = _twoGpGame(
        minors: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(
        list.where(
          (o) =>
              o.type == DiplomaticOrderType.boycott &&
              o.targetFactionId == 'minor1',
        ),
        isEmpty,
      );
    });

    test('does not emit a boycott when at war with the target GP', () {
      final game = _twoGpGame(
        state: RelationState.atWar,
        level: RelationLevel.hostile,
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(list.where((o) => o.type == DiplomaticOrderType.boycott), isEmpty);
    });
  });
}
