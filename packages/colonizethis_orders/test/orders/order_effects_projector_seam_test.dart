import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../world_market_trade_order_validator_test_support.dart';

/// Injected order-effects projector seam (Refs #3290 C2).
///
/// SPEC/program/order-engine.md § Injected projector seam,
/// SPEC/program/logic-package-split-phase0.md § orders -> projections seam.
///
/// The concrete `projectOrderEffects` runs the turn resolver and lives in the
/// neutral `lib/src/projections/` core module, above the orders domain. The
/// engine consumes it via an injected [OrderEffectsProjector] so the orders
/// source tree never imports the core module. These tests pin the seam
/// contract: the injected projector is used for `projectedEffects` and
/// trade-order validation, and a missing projector fails loudly rather than
/// silently returning empty / wrong effects.
const _regionId = 'oldWorld';

final _topology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: _regionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game _gameWithPlayer(Player player) => Game(
  id: 'g',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(
      provinces: [
        Province(id: '$_regionId|P1', regionId: _regionId, ownerId: player.id),
      ],
      units: const [],
    ),
    newWorld: const RegionData(),
  ),
  players: [player],
);

int _fakeProjectorInvocations = 0;

ProjectedEffects _fakeProjector({
  required Game game,
  required Orders orders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required String playerId,
  List<AssignedRecipe> defaultAssignments = const [],
}) {
  _fakeProjectorInvocations++;
  return const ProjectedEffects(workerCount: 99, treasuryDelta: -42);
}

void main() {
  setUp(() => _fakeProjectorInvocations = 0);

  group('OrderEffectsProjector seam — projectedEffects', () {
    test('uses the injected projector output', () {
      final game = _gameWithPlayer(
        Player(id: 'p1', displayName: 'P1', isHuman: true),
      );
      final engine = OrderEngine(projector: _fakeProjector);

      final effects = engine.projectedEffects(game, _topology, 'p1');

      expect(_fakeProjectorInvocations, 1);
      expect(effects.workerCount, 99);
      expect(effects.treasuryDelta, -42);
    });

    test('throws StateError when no projector was injected', () {
      final game = _gameWithPlayer(
        Player(id: 'p1', displayName: 'P1', isHuman: true),
      );
      final engine = OrderEngine();

      expect(
        () => engine.projectedEffects(game, _topology, 'p1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('OrderEffectsProjector seam — trade-order validation', () {
    test(
      'throws StateError when a trade order is validated without a projector',
      () {
        final game = _gameWithPlayer(
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 10}),
          ),
        );
        final engine = OrderEngine()
          ..addTradeOrder('gp1', validatorOffer(CommodityCatalog.timber.id, 5));

        expect(
          () => engine.validatePlayerOrdersWithContext(game, _topology, 'gp1'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('uses the injected projector and accepts a valid offer', () {
      final game = _gameWithPlayer(
        Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: true,
          stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 10}),
        ),
      );
      final engine = OrderEngine(projector: _fakeProjector)
        ..addTradeOrder('gp1', validatorOffer(CommodityCatalog.timber.id, 5));

      final results = engine.validatePlayerOrdersWithContext(
        game,
        _topology,
        'gp1',
      );

      expect(_fakeProjectorInvocations, 1);
      expect(results, hasLength(1));
      expect(results.single.isAccepted, isTrue);
    });

    test('does not invoke the projector when no trade order is staged', () {
      final game = _gameWithPlayer(
        Player(id: 'p1', displayName: 'P1', isHuman: true),
      );
      // No projector injected: validation must still succeed because the trade
      // phase short-circuits on empty trade orders (the projector is never
      // reached).
      final engine = OrderEngine()
        ..addMoveOrder(
          'p1',
          const MoveOrder(
            unitId: 'u1',
            destinationTileKey: '$_regionId|P1|0|0',
          ),
        );

      expect(
        () => engine.validatePlayerOrdersWithContext(game, _topology, 'p1'),
        returnsNormally,
      );
    });
  });
}
