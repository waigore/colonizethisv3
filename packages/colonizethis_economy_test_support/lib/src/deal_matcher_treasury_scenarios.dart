// Table-driven DealMatcher treasury-clamp scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'deal_matcher_scenarios.dart';
import 'deal_matcher_test_support.dart';

/// Treasury clamp scenarios from `world_market_deal_matcher_treasury_test.dart`.
List<DealMatcherScenario> dealMatcherTreasuryScenarios() => [
  ...dealMatcherTreasuryClampScenarios(),
  ...dealMatcherTreasuryEdgeCaseScenarios(),
];

List<DealMatcherScenario> dealMatcherTreasuryClampScenarios() => [
  DealMatcherScenario(
    label: 'truncates a single oversized bid to floor(treasury / price)',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'gp1': [matcherBid('timber', 10)],
      },
      tradeCapacityByFactionId: const {'gp1': 100},
      treasuryBudgetByBuyerFactionId: const {'gp1': 100},
    ),
    verify: (result) {
      expect(result.filledDeals, hasLength(1));
      final deal = result.filledDeals.single;
      expect(deal.buyerFactionId, 'gp1');
      expect(deal.quantity, 3);
      expect(deal.pricePerUnit, 30.0);
      expect(result.unfilledBidsByFactionId['gp1'], hasLength(1));
      expect(
        result.unfilledBidsByFactionId['gp1']!.single,
        matcherBid('timber', 7),
      );
    },
    refs: '#3115',
  ),
  DealMatcherScenario(
    label: 'per-buyer running tally exhausts treasury across bids in order',
    inputs: matcherInputs(
      offersByFactionId: {
        'sellerA': [matcherOffer('alpha', 5)],
        'sellerB': [matcherOffer('beta', 5)],
      },
      bidsByFactionId: {
        'gp1': [matcherBid('alpha', 5), matcherBid('beta', 5)],
      },
      tradeCapacityByFactionId: const {'gp1': 100},
      treasuryBudgetByBuyerFactionId: const {'gp1': 100},
      pricesByCommodityId: const {'alpha': 20.0, 'beta': 20.0},
    ),
    verify: (result) {
      expect(result.filledDeals, hasLength(1));
      final alphaDeal = result.filledDeals.single;
      expect(alphaDeal.commodityId, 'alpha');
      expect(alphaDeal.quantity, 5);
      expect(result.unfilledBidsByFactionId['gp1'], hasLength(1));
      expect(
        result.unfilledBidsByFactionId['gp1']!.single,
        matcherBid('beta', 5),
      );
    },
    refs: '#3115',
  ),
  DealMatcherScenario(
    label: 'negative-treasury buyer treated as zero budget (full suppression)',
    inputs: matcherInputs(
      offersByFactionId: {
        'sellerA': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'gp1': [matcherBid('timber', 10)],
      },
      tradeCapacityByFactionId: const {'gp1': 100},
      treasuryBudgetByBuyerFactionId: const {'gp1': -50},
    ),
    verify: (result) {
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['gp1'], hasLength(1));
      expect(
        result.unfilledBidsByFactionId['gp1']!.single,
        matcherBid('timber', 10),
      );
    },
    refs: '#3115',
  ),
  DealMatcherScenario(
    label: 'FRR pre-pass respects treasury clamp',
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [
          matcherOffer('timber', 10, originTileKey: 'oldWorld|M1|0|0'),
        ],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10)],
      },
      tradeCapacityByFactionId: const {'gpA': 100},
      treasuryBudgetByBuyerFactionId: const {'gpA': 60},
      pricesByCommodityId: const {'timber': 20.0},
      purchasedTileIndex: frrMatcherTestIndex(),
    ),
    verify: (result) {
      expect(result.filledDeals, hasLength(1));
      final frrDeal = result.filledDeals.single;
      expect(frrDeal.isFirstRightOfRefusalMatch, isTrue);
      expect(frrDeal.buyerFactionId, 'gpA');
      expect(frrDeal.quantity, 3);
      expect(result.unfilledBidsByFactionId['gpA'], hasLength(1));
      expect(
        result.unfilledBidsByFactionId['gpA']!.single,
        matcherBid('timber', 10).copyWith(quantity: 7),
      );
    },
    refs: '#3115',
  ),
];

List<DealMatcherScenario> dealMatcherTreasuryEdgeCaseScenarios() => [
  DealMatcherScenario(
    label:
        'emits exactly one bidPartialFillTreasuryInsufficient note per '
        'truncated bid (full bid quantity carried in note)',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'gp1': [matcherBid('timber', 10)],
      },
      tradeCapacityByFactionId: const {'gp1': 100},
      treasuryBudgetByBuyerFactionId: const {'gp1': 100},
    ),
    verify: (result) {
      final activity = result.activityByCommodityId['timber'];
      expect(activity, isNotNull);
      expect(activity!.notes, hasLength(1));
      expect(
        activity.notes.single,
        const MarketActivityNote(
          kind: MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
          factionId: 'gp1',
          commodityId: 'timber',
          quantity: 10,
        ),
      );
    },
    refs: '#3115',
  ),
  DealMatcherScenario(
    label: 'two identical runs produce byte-identical FilledDeal sequences',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'gp1': [matcherBid('timber', 10)],
        'gp2': [matcherBid('timber', 10)],
      },
      tradeCapacityByFactionId: const {'gp1': 100, 'gp2': 100},
      treasuryBudgetByBuyerFactionId: const {'gp1': 100, 'gp2': 200},
    ),
    verify: (result) {
      final b = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 10)],
          },
          bidsByFactionId: {
            'gp1': [matcherBid('timber', 10)],
            'gp2': [matcherBid('timber', 10)],
          },
          tradeCapacityByFactionId: const {'gp1': 100, 'gp2': 100},
          treasuryBudgetByBuyerFactionId: const {'gp1': 100, 'gp2': 200},
        ),
      );
      expect(result.filledDeals, equals(b.filledDeals));
      expect(
        result.unfilledBidsByFactionId.keys.toList()..sort(),
        equals(b.unfilledBidsByFactionId.keys.toList()..sort()),
      );
    },
    refs: '#3115',
  ),
  DealMatcherScenario(
    label:
        'zero-price commodity preserves legacy free-fill (no treasury debit)',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('iron', 5)],
      },
      bidsByFactionId: {
        'gp1': [matcherBid('iron', 5)],
      },
      tradeCapacityByFactionId: const {'gp1': 100},
      treasuryBudgetByBuyerFactionId: const {'gp1': 0},
      pricesByCommodityId: const <CommodityId, double>{},
    ),
    verify: (result) {
      expect(result.filledDeals, hasLength(1));
      final deal = result.filledDeals.single;
      expect(deal.pricePerUnit, 0.0);
      expect(deal.quantity, 5);
      final activity = result.activityByCommodityId['iron'];
      expect(activity, isNotNull);
      expect(
        activity!.notes,
        isEmpty,
        reason: 'no treasury truncation should be recorded on free-fill',
      );
    },
    refs: '#3115',
  ),
  DealMatcherScenario(
    label: 'missing buyer entry in treasury budget treated as zero',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 5)],
      },
      bidsByFactionId: {
        'gp1': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: const {'gp1': 100},
      treasuryBudgetByBuyerFactionId: const <String, int>{},
    ),
    verify: (result) {
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['gp1'], hasLength(1));
      expect(
        result.unfilledBidsByFactionId['gp1']!.single,
        matcherBid('timber', 5),
      );
    },
    refs: '#3115',
  ),
  DealMatcherScenario(
    label: 'unaffordable bid at non-zero price emits a note even with zero '
        'fill quantity',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 1)],
      },
      bidsByFactionId: {
        'gp1': [matcherBid('timber', 1)],
      },
      tradeCapacityByFactionId: const {'gp1': 100},
      treasuryBudgetByBuyerFactionId: const {'gp1': 10},
      pricesByCommodityId: const {'timber': 30.0},
    ),
    verify: (result) {
      expect(result.filledDeals, isEmpty);
      final activity = result.activityByCommodityId['timber'];
      expect(activity, isNotNull);
      expect(activity!.notes, hasLength(1));
      expect(
        activity.notes.single.kind,
        MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
      );
    },
    refs: '#3115',
  ),
  DealMatcherScenario(
    label: 'cargo clamps tighter than treasury → matchQty falls back to cargo, '
        'no truncation note emitted',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'gp1': [matcherBid('timber', 10)],
      },
      tradeCapacityByFactionId: const {'gp1': 4},
      treasuryBudgetByBuyerFactionId: const {'gp1': 10_000},
      pricesByCommodityId: const {'timber': 30.0},
    ),
    verify: (result) {
      expect(result.filledDeals.single.quantity, 4);
      final activity = result.activityByCommodityId['timber'];
      expect(activity, isNotNull);
      expect(
        activity!.notes,
        isEmpty,
        reason:
            'cargo-truncated bids do not emit the treasury-insufficient '
            'note (only treasury-clamped fills emit it)',
      );
    },
    refs: '#3115',
  ),
];
