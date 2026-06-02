// Unit tests for `carryForwardBidNotionalByPlayer` (Refs #3122).
//
// SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp = 'gp1';

Game _gameWithCarryForwardBids(List<TradeOrder> bids, {
  Map<CommodityId, int>? prices,
}) {
  return Game(
    id: 'g_carryfwd',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: _gp,
        displayName: 'GP1',
        isHuman: false,
        treasury: 1000,
      ),
    ],
    worldMarketState: WorldMarketState(
      prices: prices ?? const <CommodityId, int>{},
      carryForwardBidsByFactionId: {_gp: bids},
    ),
  );
}

TradeOrder _bid(String commodityId, int qty, {int priority = 3}) => TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.bid,
      quantity: qty,
      priority: priority,
    );

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('carryForwardBidNotionalByPlayer (Refs #3122)', () {
    test('returns 0 when player has no carry-forward bids', () {
      final game = _gameWithCarryForwardBids(const []);
      expect(
        carryForwardBidNotionalByPlayer(
          game: game,
          playerId: _gp,
          resourceRules: rules,
        ),
        0,
      );
    });

    test('sums quantity * effectivePrice across carry-forward bids', () {
      final game = _gameWithCarryForwardBids(
        [
          _bid('timber', 5),
          _bid('iron', 3),
        ],
        prices: {'timber': 10, 'iron': 20},
      );
      expect(
        carryForwardBidNotionalByPlayer(
          game: game,
          playerId: _gp,
          resourceRules: rules,
        ),
        5 * 10 + 3 * 20,
      );
    });

    test('falls back to catalog default price when world price is missing', () {
      final catalogTimber =
          rules.defaultMarketPriceForCommodityId('timber') ?? 0;
      expect(catalogTimber, greaterThan(0));
      final game = _gameWithCarryForwardBids(
        [_bid('timber', 4)],
        prices: const <CommodityId, int>{},
      );
      expect(
        carryForwardBidNotionalByPlayer(
          game: game,
          playerId: _gp,
          resourceRules: rules,
        ),
        4 * catalogTimber,
      );
    });

    test(
      'skips bids whose effective price is null '
      '(manufactured commodity before in-game price discovery)',
      () {
        // `fabric` is manufactured: no default in ResourceRules.
        expect(
          rules.defaultMarketPriceForCommodityId('fabric'),
          isNull,
        );
        final game = _gameWithCarryForwardBids(
          [_bid('fabric', 5)],
          prices: const <CommodityId, int>{},
        );
        expect(
          carryForwardBidNotionalByPlayer(
            game: game,
            playerId: _gp,
            resourceRules: rules,
          ),
          0,
        );
      },
    );

    test('skips offers (type != bid) and zero-quantity bids', () {
      final game = _gameWithCarryForwardBids(
        [
          TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.offer,
            quantity: 10,
            priority: 3,
          ),
          _bid('iron', 0),
        ],
        prices: {'timber': 10, 'iron': 20},
      );
      expect(
        carryForwardBidNotionalByPlayer(
          game: game,
          playerId: _gp,
          resourceRules: rules,
        ),
        0,
      );
    });
  });
}
