import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('validateOrdersAndResolveTurnFromTrustedOrders', () {
    MapTopology buildTopology() {
      return MapTopology(
        nodes: [
          const TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
      );
    }

    Game buildGame() {
      const ow = 'oldWorld';
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
    }

    // AC 5 (trusted-path correctness): Given identical valid Orders, the
    // trusted entry point produces the same resulting WorldState as the
    // existing untrusted entry point. SPEC: SPEC/program/order-engine.md
    // § Trusted-source resolution.
    test(
      'produces identical resulting WorldState as validateOrdersAndResolveTurn '
      'for valid orders',
      () {
        final topology = buildTopology();
        final game = buildGame();
        const ow = 'oldWorld';
        final orders = Orders(
          moveOrdersByPlayerId: {
            'p1': [MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0')],
          },
        );

        final trusted = requireTurnResolutionComplete(
          validateOrdersAndResolveTurnFromTrustedOrders(
            game: game,
            topology: topology,
            orders: orders,
          ),
        );
        final untrusted = requireTurnResolutionComplete(
          validateOrdersAndResolveTurn(
            game: game,
            topology: topology,
            orders: orders,
          ),
        );

        expect(trusted.toJson(), equals(untrusted.toJson()));
        expect(
          trusted.worldState.oldWorld.units.single.locationProvinceId,
          '$ow|P2',
        );
      },
    );

    // AC 5 (trusted-path bypass): Trusted path applies orders as-supplied
    // without invoking the per-player pre-apply filter. We assert this
    // observably: when an order set contains an order that would be rejected
    // by validatePlayerOrdersWithContext, the trusted path does not silently
    // drop it (it is dispatched to the phase pipeline, where movement-phase
    // application skips the unknown unit). The resulting state therefore
    // matches running resolveTurnForGame directly with the same Orders.
    test('skips per-player pre-apply filter (matches resolveTurnForGame on '
        'unfiltered orders)', () {
      final topology = buildTopology();
      final game = buildGame();
      const ow = 'oldWorld';
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0'),
            MoveOrder(unitId: 'u999', destinationTileKey: '$ow|P2|0|0'),
          ],
        },
      );

      final trusted = requireTurnResolutionComplete(
        validateOrdersAndResolveTurnFromTrustedOrders(
          game: game,
          topology: topology,
          orders: orders,
        ),
      );
      final direct = requireTurnResolutionComplete(
        resolveTurnForGame(game: game, topology: topology, orders: orders),
      );

      expect(trusted.toJson(), equals(direct.toJson()));
    });

    // AC 6 (untrusted-path preservation): Untrusted entry point still drops
    // rejected orders. Reaffirms that the new trusted entry point did not
    // alter behavior of the existing entry point. SPEC AC: untrusted-path
    // preservation.
    test('validateOrdersAndResolveTurn still filters rejected orders for '
        'untrusted callers', () {
      final topology = buildTopology();
      final game = buildGame();
      const ow = 'oldWorld';
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0'),
            MoveOrder(unitId: 'u999', destinationTileKey: '$ow|P2|0|0'),
          ],
        },
      );

      final next = requireTurnResolutionComplete(
        validateOrdersAndResolveTurn(
          game: game,
          topology: topology,
          orders: orders,
        ),
      );

      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.oldWorld.units.length, 1);
      expect(
        next.worldState.oldWorld.units.single.locationProvinceId,
        '$ow|P2',
      );
    });

    test('forwards onPhaseProgress callbacks on trusted entry point', () {
      final topology = buildTopology();
      final game = buildGame();
      const ow = 'oldWorld';
      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0')],
        },
      );
      final phaseEvents = <String>[];

      final next = requireTurnResolutionComplete(
        validateOrdersAndResolveTurnFromTrustedOrders(
          game: game,
          topology: topology,
          orders: orders,
          onPhaseProgress: (phase, marker) {
            phaseEvents.add('${phase.name}:${marker.name}');
          },
        ),
      );

      expect(next.worldState.turnState.turnNumber, 1);
      expect(phaseEvents, isNotEmpty);
      expect(phaseEvents.first, 'orders:start');
      expect(phaseEvents.last, 'endOfTurn:end');
    });
  });
}
