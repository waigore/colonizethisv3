import 'package:colonizethis_ai_contracts/src/ai/simple_ai_heuristics.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/simple_ai_heuristics_fixture.dart';

void main() {
  group('turnSeedForPlayer', () {
    test('uses aiSeedByGpId when present', () {
      final game = simpleAiEmptyWorldGame(
        turnNumber: 5,
        globalGameSeed: 100,
        aiSeedByGpId: const {simpleAiPlayerId: 999},
      );

      final seed = turnSeedForPlayer(game, simpleAiPlayerId, 5);
      expect(seed, isNonZero);
      expect(seed, equals(turnSeedForPlayer(game, simpleAiPlayerId, 5)));
    });

    test('uses fallbackAiSeed when aiSeedByGpId missing for player', () {
      final game = simpleAiEmptyWorldGame(
        players: const [
          Player(id: simpleAiPlayerId, displayName: 'GP1', isHuman: true),
        ],
        globalGameSeed: 50,
      );

      final seedWithFallback = turnSeedForPlayer(
        game,
        simpleAiPlayerId,
        1,
        fallbackAiSeed: 777,
      );
      expect(seedWithFallback, isNonZero);
      expect(turnSeedForPlayer(game, simpleAiPlayerId, 1), isNonZero);
      expect(
        seedWithFallback,
        equals(
          turnSeedForPlayer(game, simpleAiPlayerId, 1, fallbackAiSeed: 777),
        ),
      );
    });

    test('different turn or player produces different seed', () {
      final game = simpleAiEmptyWorldGame(
        players: const [
          Player(id: simpleAiPlayerId, displayName: 'GP1', isHuman: false),
          Player(id: simpleAiPeerId, displayName: 'GP2', isHuman: false),
        ],
        aiSeedByGpId: const {simpleAiPlayerId: 1, simpleAiPeerId: 2},
      );

      final s1 = turnSeedForPlayer(game, simpleAiPlayerId, 1);
      final s2 = turnSeedForPlayer(game, simpleAiPlayerId, 2);
      final s3 = turnSeedForPlayer(game, simpleAiPeerId, 1);
      expect(s1, isNot(equals(s2)));
      expect(s1, isNot(equals(s3)));
    });
  });

  group('generateOrdersWithSimpleHeuristics', () {
    test('returns empty Orders when player not in game', () {
      final game = simpleAiEmptyWorldGame(
        players: const [
          Player(id: simpleAiPlayerId, displayName: 'AI', isHuman: false),
        ],
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        const MapTopology(nodes: [], edges: []),
        'nonexistent',
        12345,
      );
      expect(orders.moveOrdersByPlayerId, isEmpty);
      expect(orders.workOrdersByPlayerId, isEmpty);
      expect(orders.buildUnitOrdersByPlayerId, isEmpty);
      expect(orders.researchOrdersByPlayerId, isEmpty);
    });

    test('returns only valid orders for player', () {
      final game = simpleAiMilitaryOwGame(
        peerLocal: 'P2',
        // At war so that attacking move into gp2 province is rules-legal
        // per SPEC/game/diplomacy.md and OrderEngine movement validation.
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: simpleAiPlayerId,
            factionId2: simpleAiPeerId,
            state: RelationState.atWar,
          ),
        ],
      );

      final orders = generateOrdersWithSimpleHeuristics(
        game,
        simpleAiAdjacentTopology(),
        simpleAiPlayerId,
        turnSeedForPlayer(game, simpleAiPlayerId, 1),
      );

      expect(orders.armyMoveOrdersByPlayerId[simpleAiPlayerId], isNotNull);
      for (final m in orders.armyMoveOrdersByPlayerId[simpleAiPlayerId]!) {
        expect(m.armyId, contains(simpleAiPlayerId));
        expect(
          m.destinationProvinceId,
          anyOf('$simpleAiOw|P1', '$simpleAiOw|P2'),
        );
      }
    });

    test('filters out move to Minor nation province when no relation', () {
      final game = simpleAiMilitaryOwGame(
        peerLocal: 'M1',
        peerOwnerId: 'minor1',
        players: const [
          Player(id: simpleAiPlayerId, displayName: 'AI', isHuman: false),
        ],
        minorNations: const [
          MinorNation(
            id: 'minor1',
            displayName: 'Minor',
            capitalProvinceId: 'M1',
          ),
        ],
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        simpleAiAdjacentTopology(b: 'M1'),
        simpleAiPlayerId,
        turnSeedForPlayer(game, simpleAiPlayerId, 1),
      );
      final moves = orders.moveOrdersByPlayerId[simpleAiPlayerId] ?? [];
      for (final m in moves) {
        expect(
          Unit.provinceIdFromTileKey(m.destinationTileKey),
          isNot('$simpleAiOw|M1'),
          reason: 'move to Minor province should be filtered when no relation',
        );
      }
    });

    test(
      'filters out move to province of faction at peace (diplomacy filter)',
      () {
        final game = simpleAiMilitaryOwGame(
          peerLocal: 'P2',
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: simpleAiPlayerId,
              factionId2: simpleAiPeerId,
              state: RelationState.atPeace,
            ),
          ],
        );
        final orders = generateOrdersWithSimpleHeuristics(
          game,
          simpleAiAdjacentTopology(),
          simpleAiPlayerId,
          turnSeedForPlayer(game, simpleAiPlayerId, 1),
        );
        final moves = orders.moveOrdersByPlayerId[simpleAiPlayerId] ?? [];
        for (final m in moves) {
          expect(
            Unit.provinceIdFromTileKey(m.destinationTileKey),
            isNot('$simpleAiOw|P2'),
            reason:
                'validator/occupancy should not target gp2 for this fixture',
          );
        }
      },
    );
  });
}
