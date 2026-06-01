// Unit tests for the world-market treasury bid budget helpers
// (Refs #3093 — treasury bid cap slice).
//
// SPEC/game/world-market.md § Treasury budget for bids,
// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _humanPlayerId = 'gp_h';

Game _buildGame({
  int treasury = 100,
  Map<CommodityId, int>? prices,
  Map<CommodityId, int>? stockpile,
}) {
  return Game(
    id: 'test_treasury_bid_budget',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(
        id: _humanPlayerId,
        displayName: 'England',
        isHuman: true,
        treasury: treasury,
        stockpile: Stockpile(
          quantities: stockpile ?? const <CommodityId, int>{},
        ),
      ),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: WorldMarketState(
      prices: prices ?? const <CommodityId, int>{},
    ),
  );
}

Orders _ordersWith(List<TradeOrder> orders) {
  return Orders(
    tradeOrdersByPlayerId: {
      _humanPlayerId: orders,
    },
  );
}

TradeOrder _bid(String commodityId, int qty) => TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.bid,
      quantity: qty,
      priority: 1,
    );

TradeOrder _offer(String commodityId, int qty) => TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.offer,
      quantity: qty,
      priority: 1,
    );

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('effectiveMarketPriceForCommodityId (Refs #3093)', () {
    test('returns the integer price from worldMarketState.prices when present',
        () {
      final game = _buildGame(prices: const {'timber': 42});
      expect(
        effectiveMarketPriceForCommodityId(
          commodityId: 'timber',
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        42,
      );
    });

    test(
        'falls back to ResourceRules.defaultMarketPriceForCommodityId when the '
        'prices map omits the commodity', () {
      final game = _buildGame(prices: const <CommodityId, int>{});
      final int? defaultTimber = rules.defaultMarketPriceForCommodityId('timber');
      expect(defaultTimber, isNotNull);
      expect(
        effectiveMarketPriceForCommodityId(
          commodityId: 'timber',
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        defaultTimber,
      );
    });

    test('returns null for manufactured commodities without a catalog default',
        () {
      final game = _buildGame(prices: const <CommodityId, int>{});
      expect(
        rules.defaultMarketPriceForCommodityId('lumber'),
        isNull,
        reason:
            'Manufactured commodity defaults are tracked as follow-up to #3093.',
      );
      expect(
        effectiveMarketPriceForCommodityId(
          commodityId: 'lumber',
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        isNull,
      );
    });

    test('returns null for riches commodities regardless of stored prices', () {
      final game = _buildGame(
        prices: const {'gold': 1000, 'silver': 500, 'gems': 999},
      );
      expect(
        effectiveMarketPriceForCommodityId(
          commodityId: 'gold',
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        isNull,
      );
      expect(
        effectiveMarketPriceForCommodityId(
          commodityId: 'silver',
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        isNull,
      );
    });

    test('treats negative stored prices as missing and falls back to catalog',
        () {
      final game = _buildGame(prices: const {'timber': -5});
      final int? defaultTimber = rules.defaultMarketPriceForCommodityId('timber');
      expect(defaultTimber, isNotNull);
      expect(
        effectiveMarketPriceForCommodityId(
          commodityId: 'timber',
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        defaultTimber,
      );
    });
  });

  group('stagedBidTotalSpendByPlayer (Refs #3093)', () {
    test('returns 0 when the player has no staged trade orders', () {
      final game = _buildGame(prices: const {'timber': 30});
      expect(
        stagedBidTotalSpendByPlayer(
          orders: const Orders(),
          playerId: _humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        0,
      );
    });

    test('returns 0 when the player has only staged offers (no bids)', () {
      final game = _buildGame(prices: const {'timber': 30});
      final orders = _ordersWith([_offer('timber', 5)]);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: _humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        0,
      );
    });

    test('sums quantity × effectiveMarketPrice across all staged bids', () {
      final game = _buildGame(prices: const {'timber': 30, 'iron': 80});
      final orders = _ordersWith([_bid('timber', 4), _bid('iron', 2)]);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: _humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        4 * 30 + 2 * 80,
      );
    });

    test('uses catalog defaults when a bid commodity is missing from prices',
        () {
      final game = _buildGame(prices: const <CommodityId, int>{});
      final int? defaultTimber = rules.defaultMarketPriceForCommodityId('timber');
      expect(defaultTimber, isNotNull);
      final orders = _ordersWith([_bid('timber', 3)]);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: _humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        3 * defaultTimber!,
      );
    });

    test('skips bids on commodities with no effective price (no contribution)',
        () {
      final game = _buildGame(prices: const <CommodityId, int>{});
      expect(rules.defaultMarketPriceForCommodityId('lumber'), isNull);
      final orders = _ordersWith([_bid('lumber', 5), _bid('timber', 2)]);
      final int? defaultTimber = rules.defaultMarketPriceForCommodityId('timber');
      expect(defaultTimber, isNotNull);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: _humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        2 * defaultTimber!,
      );
    });

    test('ignores bids with non-positive quantity (defensive guard)', () {
      final game = _buildGame(prices: const {'timber': 30});
      final orders = _ordersWith([
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 0,
          priority: 1,
        ),
        _bid('timber', 3),
      ]);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: _humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        3 * 30,
        reason: 'quantity == 0 should contribute nothing to the running total',
      );
    });

    test('isolates spend per player (unknown playerId returns 0)', () {
      final game = _buildGame(prices: const {'timber': 30});
      final orders = _ordersWith([_bid('timber', 4)]);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: 'gp_ghost',
          game: game,
          resourceRules: rules,
        ),
        0,
      );
    });
  });

  group('treasuryAvailableForBidsByPlayer (Refs #3093)', () {
    test('returns the player\'s raw treasury for known players', () {
      final game = _buildGame(treasury: 250);
      expect(
        treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: _humanPlayerId,
        ),
        250,
      );
    });

    test('clamps negative treasury to 0 (defensive guard)', () {
      final game = _buildGame(treasury: -10);
      expect(
        treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: _humanPlayerId,
        ),
        0,
      );
    });

    test('returns 0 when playerId does not resolve to a player', () {
      final game = _buildGame(treasury: 100);
      expect(
        treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: 'gp_ghost',
        ),
        0,
      );
    });
  });

  group('composition: UI clamp budget math (Refs #3093)', () {
    test(
        'treasury 100, market price timber 30, no staged bids → headroom for '
        'fresh row equals raw treasury (allows up to qty 3)', () {
      final game = _buildGame(
        treasury: 100,
        prices: const {'timber': 30},
      );
      final int budget = treasuryAvailableForBidsByPlayer(
        game: game,
        playerId: _humanPlayerId,
      );
      final int currentSpend = stagedBidTotalSpendByPlayer(
        orders: const Orders(),
        playerId: _humanPlayerId,
        game: game,
        resourceRules: rules,
      );
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'timber',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(rowPrice, 30);
      final int headroom = budget - currentSpend;
      expect(headroom ~/ rowPrice!, 3);
    });

    test(
        'treasury 100, staged Bid timber qty 3 (spend 90) → adding a fresh bid '
        'for iron (price 80) is refused (headroom 10 < 80)', () {
      final game = _buildGame(
        treasury: 100,
        prices: const {'timber': 30, 'iron': 80},
      );
      final orders = _ordersWith([_bid('timber', 3)]);
      final int budget = treasuryAvailableForBidsByPlayer(
        game: game,
        playerId: _humanPlayerId,
      );
      final int currentSpend = stagedBidTotalSpendByPlayer(
        orders: orders,
        playerId: _humanPlayerId,
        game: game,
        resourceRules: rules,
      );
      final int? ironPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'iron',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(ironPrice, 80);
      final int headroom = budget - currentSpend;
      expect(headroom, 10);
      expect(headroom < ironPrice!, isTrue,
          reason:
              'Cannot fit even 1 unit of iron at price 80 with only 10 treasury '
              'headroom — the UI must silent-no-op the toggle.');
    });

    test(
        'treasury 100, staged Bid timber qty 3 (spend 90), incrementing timber → '
        'next increment would make spend 120 (> 100), so the UI must silent-no-op',
        () {
      final game = _buildGame(
        treasury: 100,
        prices: const {'timber': 30},
      );
      final orders = _ordersWith([_bid('timber', 3)]);
      final int budget = treasuryAvailableForBidsByPlayer(
        game: game,
        playerId: _humanPlayerId,
      );
      final int currentSpend = stagedBidTotalSpendByPlayer(
        orders: orders,
        playerId: _humanPlayerId,
        game: game,
        resourceRules: rules,
      );
      final int delta = 1;
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'timber',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(rowPrice, 30);
      expect(currentSpend + delta * rowPrice! > budget, isTrue);
    });
  });
}
