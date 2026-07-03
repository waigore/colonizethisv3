// Table-driven TradeOrderSuggester scenarios (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'trade_order_suggester_test_support.dart';

/// One row in a TradeOrderSuggester scenario table.
class TradeOrderSuggesterScenario {
  const TradeOrderSuggesterScenario({
    required this.label,
    required this.buildContext,
    required this.verify,
    this.refs,
  });

  final String label;
  final TradeSuggestionContext Function() buildContext;
  final void Function(
    TradeSuggestionContext context,
    TradeSuggestionResult result,
  )
  verify;
  final String? refs;
}

/// Runs [scenario] through [TradeOrderSuggester.suggest].
void runTradeOrderSuggesterScenario(TradeOrderSuggesterScenario scenario) {
  final context = scenario.buildContext();
  scenario.verify(context, TradeOrderSuggester.suggest(context));
}

/// Empty / defensive-path scenarios from `world_market_trade_order_suggester_test.dart`.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterEmptyDefensiveScenarios() =>
    [
      TradeOrderSuggesterScenario(
        label: 'empty context returns empty result',
        buildContext: suggesterCtx,
        verify: (context, result) {
          expect(result.isEmpty, isTrue);
          expect(result.offers, isEmpty);
          expect(result.bids, isEmpty);
        },
      ),
      TradeOrderSuggesterScenario(
        label: 'negative tradeCargoCapacity returns empty result',
        buildContext: () => suggesterCtx(
          tradeCargoCapacity: -1,
          availableStockpileByCommodityId: {'timber': 10},
          commodityNeedByCommodityId: {'iron': 10},
        ),
        verify: (context, result) {
          expect(result.isEmpty, isTrue);
        },
      ),
      TradeOrderSuggesterScenario(
        label:
            'negative entries in available/need maps are silently dropped (no throw)',
        buildContext: () => suggesterCtx(
          availableStockpileByCommodityId: {'timber': -5, 'iron': 10},
          commodityNeedByCommodityId: {'coal': -3, 'wool': 4},
        ),
        verify: (context, result) {
          expect(result.offers, hasLength(1));
          expect(result.offers.single.commodityId, 'iron');
          expect(result.bids, hasLength(1));
          expect(result.bids.single.commodityId, 'wool');
        },
      ),
    ];

/// Surplus-offer detection scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterSurplusOfferScenarios() =>
    [
      TradeOrderSuggesterScenario(
        label:
            'positive available stockpile produces an offer with that quantity',
        buildContext: () =>
            suggesterCtx(availableStockpileByCommodityId: {'timber': 12}),
        verify: (context, result) {
          expect(result.offers, hasLength(1));
          final offer = result.offers.single;
          expect(offer.commodityId, 'timber');
          expect(offer.type, TradeOrderType.offer);
          expect(offer.quantity, 12);
          expect(offer.priority, TradeSuggestionContext.defaultOfferPriority);
          expect(offer.isFtp, isFalse);
          expect(result.bids, isEmpty);
        },
        refs: '#2989',
      ),
      TradeOrderSuggesterScenario(
        label: 'zero / missing available is not offered',
        buildContext: () => suggesterCtx(
          availableStockpileByCommodityId: {'timber': 0, 'iron': 5},
        ),
        verify: (context, result) {
          expect(result.offers, hasLength(1));
          expect(result.offers.single.commodityId, 'iron');
          expect(result.offers.single.quantity, 5);
        },
      ),
      TradeOrderSuggesterScenario(
        label: 'riches commodities are excluded from offers',
        buildContext: () => suggesterCtx(
          availableStockpileByCommodityId: {
            'spices': 100,
            'gold': 50,
            'timber': 10,
          },
        ),
        verify: (context, result) {
          expect(result.offers, hasLength(1));
          expect(result.offers.single.commodityId, 'timber');
        },
      ),
      TradeOrderSuggesterScenario(
        label: 'offers iterate in alphabetical commodity id order (determinism)',
        buildContext: () => suggesterCtx(
          availableStockpileByCommodityId: {
            'wool': 4,
            'coal': 2,
            'iron': 3,
            'timber': 1,
          },
        ),
        verify: (context, result) {
          expect(result.offers.map((o) => o.commodityId).toList(), [
            'coal',
            'iron',
            'timber',
            'wool',
          ]);
        },
      ),
    ];

/// Deficit-bid detection scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterDeficitBidScenarios() => [
  TradeOrderSuggesterScenario(
    label: 'positive need with zero stockpile produces a bid with that quantity',
    buildContext: () =>
        suggesterCtx(commodityNeedByCommodityId: {'timber': 8}),
    verify: (context, result) {
      expect(result.bids, hasLength(1));
      final bid = result.bids.single;
      expect(bid.commodityId, 'timber');
      expect(bid.type, TradeOrderType.bid);
      expect(bid.quantity, 8);
      expect(bid.priority, TradeSuggestionContext.defaultBidPriority);
      expect(bid.isFtp, isFalse);
      expect(result.offers, isEmpty);
    },
    refs: '#2989',
  ),
  TradeOrderSuggesterScenario(
    label:
        'mutual-exclusion at suggestion time: same commodity with stockpile=5 '
        'and need=9 produces a deficit bid of 4 only (no offer)',
    buildContext: () => suggesterCtx(
      availableStockpileByCommodityId: {'timber': 5},
      commodityNeedByCommodityId: {'timber': 9},
    ),
    verify: (context, result) {
      expect(result.offers, isEmpty);
      expect(result.bids, hasLength(1));
      expect(result.bids.single.commodityId, 'timber');
      expect(result.bids.single.quantity, 4);
    },
  ),
  TradeOrderSuggesterScenario(
    label: 'riches commodities are excluded from bids even when needed',
    buildContext: () => suggesterCtx(
      commodityNeedByCommodityId: {'gems': 5, 'gold': 5, 'timber': 4},
    ),
    verify: (context, result) {
      expect(result.bids, hasLength(1));
      expect(result.bids.single.commodityId, 'timber');
      expect(result.bids.single.quantity, 4);
    },
  ),
];

/// Bid type cap (rule 4) scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterBidTypeCapScenarios() => [
  TradeOrderSuggesterScenario(
    label: 'bidTypeCap=0 suppresses every bid',
    buildContext: () => suggesterCtx(
      bidTypeCap: 0,
      commodityNeedByCommodityId: {'timber': 4, 'iron': 3},
    ),
    verify: (context, result) {
      expect(result.bids, isEmpty);
      expect(result.offers, isEmpty);
    },
    refs: '#2989',
  ),
  TradeOrderSuggesterScenario(
    label: 'bidTypeCap=3 admits the first three alphabetical commodities only',
    buildContext: () => suggesterCtx(
      commodityNeedByCommodityId: {
        'wool': 5,
        'coal': 5,
        'timber': 5,
        'iron': 5,
      },
    ),
    verify: (context, result) {
      expect(
        result.bids.map((b) => b.commodityId).toList(),
        ['coal', 'iron', 'timber'],
        reason:
            'Alphabetical iteration + cap-of-3 keeps coal/iron/timber and '
            'drops wool deterministically.',
      );
    },
    refs: '#2989',
  ),
  TradeOrderSuggesterScenario(
    label: 'bidTypeCap=6 admits up to six distinct commodities',
    buildContext: () => suggesterCtx(
      bidTypeCap: 6,
      commodityNeedByCommodityId: {
        'cattle': 1,
        'coal': 1,
        'cotton': 1,
        'grain': 1,
        'hides': 1,
        'iron': 1,
        'timber': 1,
      },
    ),
    verify: (context, result) {
      expect(result.bids, hasLength(6));
      expect(result.bids.map((b) => b.commodityId).toList(), [
        'cattle',
        'coal',
        'cotton',
        'grain',
        'hides',
        'iron',
      ]);
    },
    refs: '#2989',
  ),
];

/// Cumulative cargo cap (rule 5) scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterCargoCapScenarios() => [
  TradeOrderSuggesterScenario(
    label: 'cargo budget is consumed across distinct bids (per-buyer total)',
    buildContext: () => suggesterCtx(
      tradeCargoCapacity: 6,
      commodityNeedByCommodityId: {'coal': 4, 'iron': 5},
    ),
    verify: (context, result) {
      expect(result.bids, hasLength(2));
      expect(result.bids[0].commodityId, 'coal');
      expect(result.bids[0].quantity, 4);
      expect(result.bids[1].commodityId, 'iron');
      expect(
        result.bids[1].quantity,
        2,
        reason: 'iron is partial-capped by remaining cargo (6 - 4 = 2).',
      );
    },
    refs: '#2989',
  ),
  TradeOrderSuggesterScenario(
    label: 'per-commodity bid never exceeds tradeCargoCapacity',
    buildContext: () => suggesterCtx(
      tradeCargoCapacity: 10,
      commodityNeedByCommodityId: {'timber': 999},
    ),
    verify: (context, result) {
      expect(result.bids, hasLength(1));
      expect(result.bids.single.quantity, 10);
    },
  ),
  TradeOrderSuggesterScenario(
    label: 'zero cargo budget suppresses bids entirely',
    buildContext: () => suggesterCtx(
      tradeCargoCapacity: 0,
      commodityNeedByCommodityId: {'timber': 5},
    ),
    verify: (context, result) {
      expect(result.bids, isEmpty);
    },
  ),
];

/// Validator-clean-by-construction scenarios.
List<TradeOrderSuggesterScenario>
tradeOrderSuggesterValidatorCleanScenarios() => [
  TradeOrderSuggesterScenario(
    label:
        'every suggested order is accepted by TradeOrderValidator.validate',
    buildContext: () => suggesterCtx(
      tradeCargoCapacity: 12,
      treasuryBudgetForBids: 500,
      availableStockpileByCommodityId: {'timber': 10, 'wool': 0},
      commodityNeedByCommodityId: {'coal': 5, 'iron': 7, 'wool': 4},
    ),
    verify: (context, result) {
      expect(result.offers, isNotEmpty);
      expect(result.bids, isNotEmpty);
      final all = <TradeOrder>[...result.offers, ...result.bids];
      final validatorResults = TradeOrderValidator.validate(
        context: TradeOrderValidationContext(
          playerId: context.playerId,
          bidTypeCap: context.bidTypeCap,
          tradeCargoCapacity: context.tradeCargoCapacity,
          availableStockpileByCommodityId:
              context.availableStockpileByCommodityId,
          treasuryBudgetForBids: context.treasuryBudgetForBids,
          worldMarketState: context.worldMarketState,
          resourceRules: context.resourceRules ?? ResourceRules.defaultRules,
        ),
        proposedOrders: all,
      );
      for (final r in validatorResults) {
        expect(r.isAccepted, isTrue, reason: r.reason);
      }
    },
  ),
  TradeOrderSuggesterScenario(
    label:
        'mixed surplus/deficit submission produces no commodity in both lists',
    buildContext: () => suggesterCtx(
      bidTypeCap: 6,
      availableStockpileByCommodityId: {'timber': 50, 'wool': 5},
      commodityNeedByCommodityId: {
        'wool': 8,
        'iron': 4,
      },
    ),
    verify: (context, result) {
      final offerIds = result.offers.map((o) => o.commodityId).toSet();
      final bidIds = result.bids.map((b) => b.commodityId).toSet();
      expect(offerIds.intersection(bidIds), isEmpty);
      expect(offerIds, contains('timber'));
      expect(bidIds, containsAll(<String>{'wool', 'iron'}));
    },
  ),
];
