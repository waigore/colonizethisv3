// Unit tests for the world-market sellable / offer-cap helpers
// (Refs #3093 Slice 2 — sellable clamp).
//
// SPEC/game/world-market.md § Trade orders § Validation rules,
// SPEC/ui/trade-screen.md § Market tab — Sellable + offer clamp.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _humanPlayerId = 'gp_h';

Game _buildGame({Map<CommodityId, int>? stockpile}) {
  return Game(
    id: 'test_sellable_quantity',
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
        treasury: 500,
        stockpile: Stockpile(
          quantities: stockpile ?? const <CommodityId, int>{},
        ),
      ),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: const WorldMarketState(),
  );
}

Orders _ordersWithOffers(List<TradeOrder> orders) {
  return Orders(
    tradeOrdersByPlayerId: {
      _humanPlayerId: orders,
    },
  );
}

void main() {
  group('offerCapByCommodityId (Refs #3093)', () {
    test('returns empty map for unknown player', () {
      final game = _buildGame(stockpile: const {'timber': 10});
      expect(
        offerCapByCommodityId(game: game, playerId: 'gp_ghost'),
        isEmpty,
      );
    });

    test('returns each non-riches stockpile quantity as the offer cap', () {
      final game = _buildGame(
        stockpile: const {
          'timber': 10,
          'iron': 7,
          'fabric': 3,
        },
      );
      final cap = offerCapByCommodityId(
        game: game,
        playerId: _humanPlayerId,
      );
      expect(cap['timber'], 10);
      expect(cap['iron'], 7);
      expect(cap['fabric'], 3);
      expect(cap.length, 3);
    });

    test('excludes riches commodities (gold, silver, gems, diamonds, spices)',
        () {
      final game = _buildGame(
        stockpile: const {
          'timber': 10,
          'gold': 5,
          'silver': 4,
          'gems': 3,
          'diamonds': 2,
          'spices': 1,
        },
      );
      final cap = offerCapByCommodityId(
        game: game,
        playerId: _humanPlayerId,
      );
      expect(cap['timber'], 10);
      expect(cap.containsKey('gold'), isFalse);
      expect(cap.containsKey('silver'), isFalse);
      expect(cap.containsKey('gems'), isFalse);
      expect(cap.containsKey('diamonds'), isFalse);
      expect(cap.containsKey('spices'), isFalse);
    });

    test('skips commodities with non-positive stockpile', () {
      final game = _buildGame(
        stockpile: const {
          'timber': 10,
        },
      );
      final cap = offerCapByCommodityId(
        game: game,
        playerId: _humanPlayerId,
      );
      expect(cap['iron'], isNull);
    });
  });

  group('stagedOfferQuantitiesByCommodityId (Refs #3093)', () {
    test('returns empty map when no trade orders are staged', () {
      const orders = Orders();
      expect(
        stagedOfferQuantitiesByCommodityId(
          orders: orders,
          playerId: _humanPlayerId,
        ),
        isEmpty,
      );
    });

    test('sums quantities per commodity for offer-typed orders', () {
      final orders = _ordersWithOffers([
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.offer,
          quantity: 5,
          priority: 1,
        ),
        TradeOrder(
          commodityId: 'iron',
          type: TradeOrderType.offer,
          quantity: 3,
          priority: 1,
        ),
      ]);
      final staged = stagedOfferQuantitiesByCommodityId(
        orders: orders,
        playerId: _humanPlayerId,
      );
      expect(staged['timber'], 5);
      expect(staged['iron'], 3);
    });

    test('excludes bid-typed orders', () {
      final orders = _ordersWithOffers([
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 4,
          priority: 1,
        ),
        TradeOrder(
          commodityId: 'iron',
          type: TradeOrderType.offer,
          quantity: 3,
          priority: 1,
        ),
      ]);
      final staged = stagedOfferQuantitiesByCommodityId(
        orders: orders,
        playerId: _humanPlayerId,
      );
      expect(staged.containsKey('timber'), isFalse);
      expect(staged['iron'], 3);
    });

    test('excludes non-positive quantities', () {
      final orders = _ordersWithOffers([
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.offer,
          quantity: 0,
          priority: 1,
        ),
      ]);
      final staged = stagedOfferQuantitiesByCommodityId(
        orders: orders,
        playerId: _humanPlayerId,
      );
      expect(staged.containsKey('timber'), isFalse);
    });
  });

  group('sellableHeadroomByCommodityId (Refs #3093)', () {
    test('returns the offer cap when no offers are staged', () {
      final game = _buildGame(
        stockpile: const {'timber': 10, 'iron': 7},
      );
      const orders = Orders();
      final sellable = sellableHeadroomByCommodityId(
        game: game,
        playerId: _humanPlayerId,
        orders: orders,
      );
      expect(sellable['timber'], 10);
      expect(sellable['iron'], 7);
    });

    test(
        'subtracts staged offer quantity from the cap to produce the '
        '`(N)` display headroom (default: industry allocation = 0)', () {
      final game = _buildGame(
        stockpile: const {'timber': 10},
      );
      // 10 stockpile, no allocation passed, staged 2 → headroom 8
      // (= 10 - 0 - 2); allocation subtraction exercised by the next pin.
      final orders = _ordersWithOffers([
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.offer,
          quantity: 2,
          priority: 1,
        ),
      ]);
      final sellable = sellableHeadroomByCommodityId(
        game: game,
        playerId: _humanPlayerId,
        orders: orders,
      );
      expect(sellable['timber'], 8);
    });

    test(
        'industry-allocation reservation: stockpile 10 timber, '
        'production consumes 3 timber, staged offer 2 → sellable 5 '
        '(canonical AC for Refs #3093 sellable definition)', () {
      final game = _buildGame(
        stockpile: const {'timber': 10},
      );
      final orders = _ordersWithOffers([
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.offer,
          quantity: 2,
          priority: 1,
        ),
      ]);
      final sellable = sellableHeadroomByCommodityId(
        game: game,
        playerId: _humanPlayerId,
        orders: orders,
        productionInputConsumptionByCommodityId: const {'timber': 3},
      );
      expect(sellable['timber'], 5,
          reason: 'Canonical AC: max(0, 10 - 3) - 2 = 5. Offer chip / `+` '
              'stepper must clamp at this sellable headroom.');
    });

    test(
        'industry-allocation reservation: when consumption equals '
        'stockpile, cap is 0 → key omitted (Offer chip disabled)', () {
      final game = _buildGame(
        stockpile: const {'timber': 10},
      );
      const orders = Orders();
      final sellable = sellableHeadroomByCommodityId(
        game: game,
        playerId: _humanPlayerId,
        orders: orders,
        productionInputConsumptionByCommodityId: const {'timber': 10},
      );
      expect(sellable.containsKey('timber'), isFalse,
          reason: 'Full reservation collapses the cap to 0 → key dropped.');
    });

    test(
        'industry-allocation reservation: negative consumption entries '
        'are clamped at 0 (defensive — caller cannot inflate the cap)',
        () {
      final game = _buildGame(
        stockpile: const {'timber': 10},
      );
      const orders = Orders();
      final sellable = sellableHeadroomByCommodityId(
        game: game,
        playerId: _humanPlayerId,
        orders: orders,
        productionInputConsumptionByCommodityId: const {'timber': -100},
      );
      expect(sellable['timber'], 10,
          reason: 'Negative consumption must not raise sellable above '
              'raw stockpile.');
    });

    test(
        'industry-allocation reservation: empty map matches null '
        '(both fall back to raw stockpile)', () {
      final game = _buildGame(
        stockpile: const {'timber': 10},
      );
      const orders = Orders();
      final viaNull = sellableHeadroomByCommodityId(
        game: game,
        playerId: _humanPlayerId,
        orders: orders,
      );
      final viaEmpty = sellableHeadroomByCommodityId(
        game: game,
        playerId: _humanPlayerId,
        orders: orders,
        productionInputConsumptionByCommodityId:
            const <CommodityId, int>{},
      );
      expect(viaNull['timber'], 10);
      expect(viaEmpty['timber'], 10);
    });

    test(
        'industry-allocation reservation: consumption on one commodity '
        'does not affect another commodity\'s cap', () {
      final game = _buildGame(
        stockpile: const {'timber': 10, 'iron': 7},
      );
      const orders = Orders();
      final sellable = sellableHeadroomByCommodityId(
        game: game,
        playerId: _humanPlayerId,
        orders: orders,
        productionInputConsumptionByCommodityId: const {'timber': 4},
      );
      expect(sellable['timber'], 6);
      expect(sellable['iron'], 7,
          reason: 'Iron has no reservation entry → raw stockpile.');
    });

    test(
        'clamps headroom at 0 (drops the commodity) when staged offer '
        'reaches or exceeds the cap', () {
      final game = _buildGame(
        stockpile: const {'timber': 5},
      );
      final orders = _ordersWithOffers([
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.offer,
          quantity: 5,
          priority: 1,
        ),
      ]);
      final sellable = sellableHeadroomByCommodityId(
        game: game,
        playerId: _humanPlayerId,
        orders: orders,
      );
      expect(sellable.containsKey('timber'), isFalse,
          reason:
              'Cap=5 minus staged offer 5 = 0; missing key means `(0)` so '
              'the Trade Market tab shows no `(N)` and disables the Offer '
              'chip / `+` button.');
    });

    test('bids do not consume the offer headroom', () {
      final game = _buildGame(
        stockpile: const {'timber': 10},
      );
      final orders = _ordersWithOffers([
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 4,
          priority: 1,
        ),
      ]);
      final sellable = sellableHeadroomByCommodityId(
        game: game,
        playerId: _humanPlayerId,
        orders: orders,
      );
      expect(sellable['timber'], 10);
    });

    test('riches commodities are excluded even when staged offers exist',
        () {
      // Defensive: validator rejects riches offers; helper must drop them too.
      final game = _buildGame(
        stockpile: const {'timber': 10, 'gold': 4},
      );
      final orders = _ordersWithOffers([
        TradeOrder(
          commodityId: 'gold',
          type: TradeOrderType.offer,
          quantity: 2,
          priority: 1,
        ),
      ]);
      final sellable = sellableHeadroomByCommodityId(
        game: game,
        playerId: _humanPlayerId,
        orders: orders,
      );
      expect(sellable.containsKey('gold'), isFalse);
      expect(sellable['timber'], 10);
    });
  });
}
