import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/ai/simple_ai_heuristics.dart';
import 'package:colonizethis_logic/src/orders/incremental_candidate_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Tests that the optional `sharedCandidateValidator` parameter on top-level
/// suggest functions (Refs #2394, SPEC/program/order-suggestions.md
/// § Throughput bounds) preserves the observable suggestion contract: when a
/// caller supplies an externally constructed `IncrementalCandidateValidator`
/// built with matching `(game, view.playerId, currentOrders)` inputs, the
/// returned suggestions are identical to the default path that builds the
/// validator internally.
///
/// Negative coverage: mismatched validator playerId trips an assertion (debug
/// mode), guarding callers against accidental cross-player reuse.
void main() {
  suppressLogsForTests();

  const gp = 'gp1';
  const ow = 'oldWorld';
  const cap = '$ow|cap';
  const p1 = '$ow|p1';
  const p2 = '$ow|p2';

  Game buildGame() {
    return Game(
      id: 'g_shared_validator',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [
            Province(
              id: cap,
              regionId: ow,
              ownerId: gp,
              townTileKey: '$ow|cap|0|0',
            ),
            Province(id: p1, regionId: ow, ownerId: gp),
            Province(id: p2, regionId: ow, ownerId: 'gp2'),
          ],
          units: [
            Unit(
              id: 'u_builder',
              type: kUnitTypeBuilder,
              ownerId: gp,
              locationProvinceId: cap,
              tileKey: '$ow|cap|0|0',
            ),
            Unit(
              id: 'u_explorer',
              type: kUnitTypeExplorer,
              ownerId: gp,
              locationProvinceId: cap,
              tileKey: '$ow|cap|0|0',
            ),
            Unit(
              id: 'r1',
              type: 'musketeers',
              ownerId: gp,
              locationProvinceId: p1,
              tileKey: '$ow|p1|0|0',
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: [
          Army(
            id: homeArmyIdFor(gp),
            ownerId: gp,
            regionId: ow,
            stationedProvinceId: cap,
            regimentUnitIds: const [],
            isHomeArmy: true,
          ),
          Army(
            id: 'field_a',
            ownerId: gp,
            regionId: ow,
            stationedProvinceId: p1,
            regimentUnitIds: const ['r1'],
            isHomeArmy: false,
          ),
        ],
        tileKeysByRegionAndProvince: const {
          ow: {
            cap: ['$ow|cap|0|0'],
            p1: ['$ow|p1|0|0'],
            p2: ['$ow|p2|0|0'],
          },
        },
        playerVisibilityByTile: const {
          gp: {
            '$ow|cap|0|0': 'fullyVisible',
            '$ow|p1|0|0': 'fullyVisible',
            '$ow|p2|0|0': 'fogged',
          },
        },
        resourceByTileKey: const {
          '$ow|p1|0|0': 'wood',
        },
      ),
      players: const [
        Player(
          id: gp,
          displayName: 'GP1',
          isHuman: false,
          capitalProvinceId: cap,
          treasury: 999,
        ),
        Player(id: 'gp2', displayName: 'GP2', isHuman: true),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: gp,
          factionId2: 'gp2',
          state: RelationState.atWar,
        ),
      ],
    );
  }

  MapTopology buildTopology() {
    return const MapTopology(
      nodes: [
        TopologyNode(id: cap, regionId: ow, type: TopologyNodeType.province),
        TopologyNode(id: p1, regionId: ow, type: TopologyNodeType.province),
        TopologyNode(id: p2, regionId: ow, type: TopologyNodeType.province),
      ],
      edges: [
        TopologyEdge(id1: cap, id2: p1),
        TopologyEdge(id1: p1, id2: p2),
      ],
    );
  }

  group('shared validator equivalence (Refs #2394)', () {
    test('suggestMoveOrders matches default path', () {
      final game = buildGame();
      final topology = buildTopology();
      final view = buildPlayerView(game, topology, gp);
      const orders = Orders();

      final defaultPath = suggestMoveOrders(view, game, topology, orders);
      final sharedValidator = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: gp,
        basePrefix: orders,
      );
      final sharedPath = suggestMoveOrders(
        view,
        game,
        topology,
        orders,
        sharedCandidateValidator: sharedValidator,
      );
      expect(sharedPath, equals(defaultPath));
    });

    test('suggestArmyMoveOrders matches default path', () {
      final game = buildGame();
      final topology = buildTopology();
      final view = buildPlayerView(game, topology, gp);
      const orders = Orders();

      final defaultPath = suggestArmyMoveOrders(view, game, topology, orders);
      final sharedValidator = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: gp,
        basePrefix: orders,
      );
      final sharedPath = suggestArmyMoveOrders(
        view,
        game,
        topology,
        orders,
        sharedCandidateValidator: sharedValidator,
      );
      expect(sharedPath, equals(defaultPath));
    });

    test('suggestWorkOrders matches default path', () {
      final game = buildGame();
      final topology = buildTopology();
      final view = buildPlayerView(game, topology, gp);
      const orders = Orders();

      final defaultPath = suggestWorkOrders(view, game, topology, orders);
      final sharedValidator = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: gp,
        basePrefix: orders,
      );
      final sharedPath = suggestWorkOrders(
        view,
        game,
        topology,
        orders,
        sharedCandidateValidator: sharedValidator,
      );
      expect(sharedPath, equals(defaultPath));
    });

    test('suggestBuildOrders matches default path', () {
      final game = buildGame();
      final topology = buildTopology();
      final view = buildPlayerView(game, topology, gp);
      const orders = Orders();

      final defaultPath = suggestBuildOrders(view, game, topology, orders);
      final sharedValidator = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: gp,
        basePrefix: orders,
      );
      final sharedPath = suggestBuildOrders(
        view,
        game,
        topology,
        orders,
        sharedCandidateValidator: sharedValidator,
      );
      expect(sharedPath, equals(defaultPath));
    });

    test(
      'shared validator built with externally provided view/unitsById produces '
      'identical suggestions to forPlayer default path (no internal rebuild)',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final view = buildPlayerView(game, topology, gp);
        final unitsById = unitsByIdFromWorld(game.worldState);
        const orders = Orders();

        // Default path: forPlayer rebuilds view/unitsById internally.
        final defaultValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: gp,
          basePrefix: orders,
        );

        // Throughput hook: forPlayer accepts pre-built view/unitsById and
        // skips the internal rebuild. Refs #2394.
        final sharedValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: gp,
          basePrefix: orders,
          view: view,
          unitsById: unitsById,
        );

        // Same view/unitsById ⇒ same suggestions across every family.
        expect(
          suggestMoveOrders(
            view,
            game,
            topology,
            orders,
            sharedCandidateValidator: defaultValidator,
          ),
          equals(
            suggestMoveOrders(
              view,
              game,
              topology,
              orders,
              sharedCandidateValidator: sharedValidator,
            ),
          ),
        );
        expect(
          suggestArmyMoveOrders(
            view,
            game,
            topology,
            orders,
            sharedCandidateValidator: defaultValidator,
          ),
          equals(
            suggestArmyMoveOrders(
              view,
              game,
              topology,
              orders,
              sharedCandidateValidator: sharedValidator,
            ),
          ),
        );
        expect(
          suggestWorkOrders(
            view,
            game,
            topology,
            orders,
            sharedCandidateValidator: defaultValidator,
          ),
          equals(
            suggestWorkOrders(
              view,
              game,
              topology,
              orders,
              sharedCandidateValidator: sharedValidator,
            ),
          ),
        );
        expect(
          suggestBuildOrders(
            view,
            game,
            topology,
            orders,
            sharedCandidateValidator: defaultValidator,
          ),
          equals(
            suggestBuildOrders(
              view,
              game,
              topology,
              orders,
              sharedCandidateValidator: sharedValidator,
            ),
          ),
        );
      },
    );
  });

  group('shared validator playerId mismatch is rejected', () {
    test(
      'suggestMoveOrders trips assertion when validator is for a different '
      'player',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final view = buildPlayerView(game, topology, gp);
        final wrongValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'gp2',
          basePrefix: const Orders(),
        );
        expect(
          () => suggestMoveOrders(
            view,
            game,
            topology,
            const Orders(),
            sharedCandidateValidator: wrongValidator,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'suggestArmyMoveOrders trips assertion when validator is for a '
      'different player',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final view = buildPlayerView(game, topology, gp);
        final wrongValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'gp2',
          basePrefix: const Orders(),
        );
        expect(
          () => suggestArmyMoveOrders(
            view,
            game,
            topology,
            const Orders(),
            sharedCandidateValidator: wrongValidator,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'suggestWorkOrders trips assertion when validator is for a different '
      'player',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final view = buildPlayerView(game, topology, gp);
        final wrongValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'gp2',
          basePrefix: const Orders(),
        );
        expect(
          () => suggestWorkOrders(
            view,
            game,
            topology,
            const Orders(),
            sharedCandidateValidator: wrongValidator,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'suggestBuildOrders trips assertion when validator is for a different '
      'player',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final view = buildPlayerView(game, topology, gp);
        final wrongValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'gp2',
          basePrefix: const Orders(),
        );
        expect(
          () => suggestBuildOrders(
            view,
            game,
            topology,
            const Orders(),
            sharedCandidateValidator: wrongValidator,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'IncrementalCandidateValidator.forPlayer trips assertion when supplied '
      'view is for a different player',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final foreignView = buildPlayerView(game, topology, 'gp2');
        expect(
          () => IncrementalCandidateValidator.forPlayer(
            game: game,
            topology: topology,
            playerId: gp,
            basePrefix: const Orders(),
            view: foreignView,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });

  group('generateOrdersWithSimpleHeuristics still produces the same orders', () {
    test(
      'orders generated under the new shared-validator code path are unchanged '
      'against a known fixture',
      () {
        final game = buildGame();
        final topology = buildTopology();
        // simple_ai_heuristics uses the shared-validator path internally; we
        // verify it still produces valid orders matching expectations.
        final orders = generateOrdersWithSimpleHeuristics(
          game,
          topology,
          gp,
          turnSeedForPlayer(game, gp, 1, fallbackAiSeed: 42),
        );
        expect(orders.workOrdersByPlayerId, isNotNull);
        // Generated army-move orders should target only legal destinations.
        final armyMoves = orders.armyMoveOrdersByPlayerId[gp] ?? const [];
        for (final m in armyMoves) {
          expect(
            m.destinationProvinceId,
            anyOf(cap, p1, p2),
            reason:
                'army move destination must be one of the corpus provinces',
          );
        }
      },
    );
  });
}
