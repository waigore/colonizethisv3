// Table-driven DealMatcher scenarios (Refs #3836, #3939).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'deal_matcher_expectations.dart';
import 'deal_matcher_scenario.dart';
import 'deal_matcher_test_support.dart';

/// Treasury clamp scenarios from `world_market_deal_matcher_treasury_test.dart`.
List<DealMatcherScenario> dealMatcherTreasuryScenarios() => [
  ...dealMatcherTreasuryClampScenarios(),
  ...dealMatcherTreasuryEdgeCaseScenarios(),
];

List<DealMatcherScenario> dealMatcherTreasuryClampScenarios() => [
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gp1',
        quantity: 3,
        pricePerUnit: 30.0,
      ),
      unfilledBidsByFactionId: {
        'gp1': [matcherBid('timber', 7)],
      },
    ),
    refs: '#3115',
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: const FilledDealExpectation(
        commodityId: 'alpha',
        quantity: 5,
      ),
      unfilledBidsByFactionId: {
        'gp1': [matcherBid('beta', 5)],
      },
    ),
    refs: '#3115',
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledBidsByFactionId: {
        'gp1': [matcherBid('timber', 10)],
      },
    ),
    refs: '#3115',
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gpA',
        quantity: 3,
        isFirstRightOfRefusalMatch: true,
      ),
      unfilledBidsByFactionId: {
        'gpA': [matcherBid('timber', 10).copyWith(quantity: 7)],
      },
    ),
    refs: '#3115',
  ),
];

List<DealMatcherScenario> dealMatcherTreasuryEdgeCaseScenarios() => [
  DealMatcherScenario.expect(
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
    expect: const DealMatchExpectation(
      activityNotesByCommodityId: {
        'timber': [
          MarketActivityNote(
            kind: MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
            factionId: 'gp1',
            commodityId: 'timber',
            quantity: 10,
          ),
        ],
      },
    ),
    refs: '#3115',
  ),
  DealMatcherScenario.expect(
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
    deterministicRerun: true,
    expect: const DealMatchExpectation(),
    refs: '#3115',
  ),
  DealMatcherScenario.expect(
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
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(
        pricePerUnit: 0.0,
        quantity: 5,
      ),
      activityNotesEmptyForCommodities: ['iron'],
    ),
    refs: '#3115',
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledBidsByFactionId: {
        'gp1': [matcherBid('timber', 5)],
      },
    ),
    refs: '#3115',
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      activityNotesByCommodityId: {
        'timber': [
          MarketActivityNote(
            kind: MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
            factionId: 'gp1',
            commodityId: 'timber',
            quantity: 1,
          ),
        ],
      },
    ),
    refs: '#3115',
  ),
  DealMatcherScenario.expect(
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
    expect: const DealMatchExpectation(
      firstFilledDeal: FilledDealExpectation(quantity: 4),
      activityNotesEmptyForCommodities: ['timber'],
    ),
    refs: '#3115',
  ),
];
