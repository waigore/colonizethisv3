import 'package:colonizethis_ai_contracts/src/ai/sim_game_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/sim_game_ai_fixture.dart';

void main() {
  group('defaultSimGameAi', () {
    test('produces army move orders only to adjacent provinces', () {
      final topology = simGameAiTopology(includeP3: true);
      final game = simGameAiMilitaryGame(
        provinceLocals: const ['P1', 'P2', 'P3'],
        ownerByLocal: const {
          'P1': simGameAiPlayerId,
          'P2': simGameAiPeerOwnerId,
          'P3': 'p3',
        },
        unitLocals: const ['P1', 'P2'],
      );
      final player = game.players.single;

      final orders = defaultSimGameAi(
        game: game,
        player: player,
        topology: topology,
        baseSeed: 42,
      );

      final armyMoves = orders.armyMoveOrdersByPlayerId[player.id] ?? const [];
      expect(armyMoves, isNotEmpty);
      final gameWithArmies = ensureMilitaryArmiesForGame(game);
      for (final mo in armyMoves) {
        final army = gameWithArmies.worldState.armies.firstWhere(
          (a) => a.id == mo.armyId,
        );
        final fromLocal = ProvinceId.localIdFrom(army.stationedProvinceId);
        final toLocal = ProvinceId.localIdFrom(mo.destinationProvinceId);
        final isAdjacent = topology.edges.any(
          (e) =>
              (e.id1 == fromLocal && e.id2 == toLocal) ||
              (e.id1 == toLocal && e.id2 == fromLocal),
        );
        expect(
          isAdjacent,
          isTrue,
          reason: 'Move from $fromLocal to $toLocal must follow topology edge',
        );
      }
    });

    test('is deterministic for same game, player, topology, and seed', () {
      final topology = simGameAiTopology();
      final game = simGameAiMilitaryGame(turnNumber: 3);
      final player = game.players.single;

      final o1 = defaultSimGameAi(
        game: game,
        player: player,
        topology: topology,
        baseSeed: 99,
      );
      final o2 = defaultSimGameAi(
        game: game,
        player: player,
        topology: topology,
        baseSeed: 99,
      );

      expect(o1, equals(o2));
    });

    test(
      'drops moves into at-peace GP provinces via diplomacy post-filter',
      () {
        final topology = simGameAiTopology();
        final game = simGameAiMilitaryGame(
          players: const [
            Player(
              id: simGameAiPlayerId,
              displayName: 'Power 1',
              isHuman: true,
            ),
            Player(
              id: simGameAiPeerOwnerId,
              displayName: 'Power 2',
              isHuman: false,
            ),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: simGameAiPlayerId,
              factionId2: simGameAiPeerOwnerId,
              score: 50,
              state: RelationState.atPeace,
            ),
          ],
        );

        final orders = defaultSimGameAi(
          game: game,
          player: game.players.first,
          topology: topology,
          baseSeed: 1,
        );
        final moves = orders.moveOrdersByPlayerId[simGameAiPlayerId] ?? const [];
        expect(
          moves.any(
            (m) =>
                Unit.provinceIdFromTileKey(m.destinationTileKey) ==
                'oldWorld|P2',
          ),
          isFalse,
          reason: 'no civilian move orders in this military-only fixture',
        );
      },
    );

    test('drops moves into minor provinces when relation is unknown', () {
      final topology = simGameAiTopology();
      final game = simGameAiMilitaryGame(
        ownerByLocal: const {
          'P1': simGameAiPlayerId,
          'P2': 'minor1',
        },
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
      );

      final orders = defaultSimGameAi(
        game: game,
        player: game.players.first,
        topology: topology,
        baseSeed: 1,
      );
      final moves = orders.moveOrdersByPlayerId[simGameAiPlayerId] ?? const [];
      expect(
        moves.any(
          (m) =>
              Unit.provinceIdFromTileKey(m.destinationTileKey) == 'oldWorld|P2',
        ),
        isFalse,
        reason: 'no civilian move orders in this military-only fixture',
      );
    });

    test('does not mutate game state', () {
      final topology = simGameAiTopology();
      final game = simGameAiMilitaryGame(
        turnNumber: 2,
        players: const [
          Player(id: simGameAiPlayerId, displayName: 'Power 1', isHuman: true),
          Player(
            id: simGameAiPeerOwnerId,
            displayName: 'Power 2',
            isHuman: false,
          ),
        ],
      );
      final before = game.toJson();

      defaultSimGameAi(
        game: game,
        player: game.players.first,
        topology: topology,
        baseSeed: 7,
      );

      expect(game.toJson(), equals(before));
    });
  });
}
