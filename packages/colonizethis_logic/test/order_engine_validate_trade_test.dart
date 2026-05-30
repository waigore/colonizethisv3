import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'world_market_trade_order_validator_test_support.dart';

/// End-to-end OrderEngine wiring for [TradeOrder] (#2989 A8).
///
/// Covers the validation contract that:
///   1. Engine validates trade orders in their own phase after naval orders.
///   2. `addTradeOrderWithContext` delegates to [TradeOrderValidator] via
///      [OrderEngine.validatePlayerOrdersWithContext].
///   3. Mutual exclusion, stockpile, and bid-type cap rejections surface
///      with stable reason codes per SPEC/program/world-market-resolution.md.
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

Game _gameWith({
  required Player player,
  List<OvertureState> overtures = const [],
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [player],
    overtureStates: overtures,
  );
}

void main() {
  group('OrderEngine validation pass — TradeOrder (#2989 A8)', () {
    test('accepts a valid offer when stockpile covers quantity', () {
      final game = _gameWith(
        player: Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: true,
          stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 10}),
        ),
      );
      final engine = OrderEngine()
        ..addTradeOrderWithContext(
          game,
          _topology,
          'gp1',
          validatorOffer(CommodityCatalog.timber.id, 5),
        );

      final results = engine.validatePlayerOrdersWithContext(
        game,
        _topology,
        'gp1',
      );

      expect(results, hasLength(1));
      expect(results.single.isAccepted, isTrue);
    });

    test('rejects mutual exclusion when bid and offer share a commodity', () {
      final game = _gameWith(
        player: Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: true,
          stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 20}),
        ),
        overtures: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      final engine = OrderEngine()
        ..addTradeOrderWithContext(
          game,
          _topology,
          'gp1',
          validatorOffer(CommodityCatalog.timber.id, 5),
        )
        ..addTradeOrderWithContext(
          game,
          _topology,
          'gp1',
          validatorBid(CommodityCatalog.timber.id, 3),
        );

      final results = engine.validatePlayerOrdersWithContext(
        game,
        _topology,
        'gp1',
      );

      expect(results, hasLength(2));
      expect(results.every((r) => !r.isAccepted), isTrue);
      expect(
        results.map((r) => r.reason).toSet(),
        {TradeOrderRejectionReasons.mutualExclusion},
      );
    });

    test('rejects offer exceeding available stockpile', () {
      final game = _gameWith(
        player: Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: true,
          stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 3}),
        ),
      );
      final result = OrderEngine().addTradeOrderWithContext(
        game,
        _topology,
        'gp1',
        validatorOffer(CommodityCatalog.timber.id, 10),
      );

      expect(result.isAccepted, isFalse);
      expect(result.reason, TradeOrderRejectionReasons.offerExceedsStockpile);
    });

    test('rejects bid when player has no embassy (bid type cap 0)', () {
      final game = _gameWith(
        player: Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: true,
          stockpile: Stockpile.empty,
        ),
      );
      final result = OrderEngine().addTradeOrderWithContext(
        game,
        _topology,
        'gp1',
        validatorBid(CommodityCatalog.timber.id, 1),
      );

      expect(result.isAccepted, isFalse);
      expect(result.reason, TradeOrderRejectionReasons.bidTypeCapExceeded);
    });
  });
}
