// Table-driven DealMatcher scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../scenario_runner.dart';
import '../frr_scenarios/frr_credits_test_support.dart';
import 'deal_matcher_expectations.dart';
import 'deal_matcher_test_support.dart';

/// One row in a DealMatcher scenario table.
class DealMatcherScenario implements RefsScenario {
  const DealMatcherScenario({
    required this.label,
    required this.inputs,
    required this.verify,
    this.deterministicRerun = false,
    this.refs,
  });

  DealMatcherScenario.expect({
    required String label,
    required DealMatchInputs inputs,
    required DealMatchExpectation expect,
    bool deterministicRerun = false,
    String? refs,
  }) : this(
          label: label,
          inputs: inputs,
          verify: (result) => assertDealMatchExpectation(result, expect),
          deterministicRerun: deterministicRerun,
          refs: refs,
        );

  final String label;
  final DealMatchInputs inputs;
  final void Function(DealMatchResult result) verify;
  final bool deterministicRerun;
  final String? refs;
}

void runDealMatcherScenario(DealMatcherScenario scenario) {
  final result = DealMatcher.matchDeals(scenario.inputs);
  scenario.verify(result);
  if (scenario.deterministicRerun) {
    final rerun = DealMatcher.matchDeals(scenario.inputs);
    expect(result.filledDeals, equals(rerun.filledDeals));
    expect(
      result.unfilledBidsByFactionId.keys.toList()..sort(),
      equals(rerun.unfilledBidsByFactionId.keys.toList()..sort()),
    );
  }
}

/// Empty-input and basic-fill scenarios from `world_market_deal_matcher_test.dart`.
List<DealMatcherScenario> dealMatcherEmptyAndBasicScenarios() => [
  DealMatcherScenario.expect(
    label: 'no offers and no bids returns DealMatchResult.empty',
    inputs: matcherInputs(),
    expect: const DealMatchExpectation(resultEqualsEmpty: true),
  ),
  DealMatcherScenario.expect(
    label: 'offers only (no bids) carries every offer forward, no deals',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 5)],
      },
    ),
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledBidsEmpty: true,
      unfilledOffersByFactionId: {
        'a': [matcherOffer('timber', 5)],
      },
      activityByCommodityId: const {
        'timber': MarketActivity(totalOfferQuantity: 5),
      },
    ),
  ),
  DealMatcherScenario.expect(
    label: 'bids only (no offers) carries every bid forward, no deals',
    inputs: matcherInputs(
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: {'b': 100},
    ),
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledOffersEmpty: true,
      unfilledBidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
      activityByCommodityId: const {
        'timber': MarketActivity(totalBidQuantity: 5),
      },
    ),
  ),
  DealMatcherScenario.expect(
    label: 'single offer 10 vs single bid 5 fills 5, offer carries 5 forward',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: {'b': 100},
    ),
    expect: DealMatchExpectation(
      filledDeals: const [
        FilledDeal(
          sellerFactionId: 'a',
          buyerFactionId: 'b',
          commodityId: 'timber',
          quantity: 5,
          pricePerUnit: 30.0,
        ),
      ],
      unfilledBidsEmpty: true,
      unfilledOffersByFactionId: {
        'a': [matcherOffer('timber', 5)],
      },
      activityByCommodityId: const {
        'timber': MarketActivity(
          totalBidQuantity: 5,
          totalOfferQuantity: 10,
          filledQuantity: 5,
        ),
      },
    ),
  ),
  DealMatcherScenario.expect(
    label: 'missing price for commodity records pricePerUnit = 0.0',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('iron', 5)],
      },
      bidsByFactionId: {
        'b': [matcherBid('iron', 5)],
      },
      tradeCapacityByFactionId: {'b': 100},
      pricesByCommodityId: const <CommodityId, double>{},
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(pricePerUnit: 0.0),
    ),
  ),
  DealMatcherScenario.expect(
    label: 'zero-quantity offer emits no deal and no carry-forward',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 0)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: {'b': 100},
    ),
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledOffersEmpty: true,
      unfilledBidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
    ),
  ),
];

/// Cargo-enforcement scenarios from `world_market_deal_matcher_test.dart`.
List<DealMatcherScenario> dealMatcherCargoScenarios() => [
  DealMatcherScenario.expect(
    label: 'buyer with no tradeCapacity entry treated as zero cargo',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
    ),
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledBidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
    ),
  ),
  DealMatcherScenario.expect(
    label: 'cross-commodity cargo: A=8 priority-1, B=10 priority-2 with '
        'tradeCapacity 15 -> A fills 8, B partial 7, B carry 3',
    inputs: matcherInputs(
      offersByFactionId: {
        'sellerA': [matcherOffer('alpha', 100, priority: 1)],
        'sellerB': [matcherOffer('beta', 100, priority: 2)],
      },
      bidsByFactionId: {
        'buyer': [
          matcherBid('alpha', 8, priority: 1),
          matcherBid('beta', 10, priority: 2),
        ],
      },
      tradeCapacityByFactionId: {'buyer': 15},
      pricesByCommodityId: const {'alpha': 5.0, 'beta': 10.0},
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 2,
      filledDealQuantityByCommodityId: const {'alpha': 8, 'beta': 7},
      unfilledBidsByFactionId: {
        'buyer': [matcherBid('beta', 3, priority: 2)],
      },
      activityByCommodityId: const {
        'alpha': MarketActivity(
          totalBidQuantity: 8,
          totalOfferQuantity: 100,
          filledQuantity: 8,
        ),
        'beta': MarketActivity(
          totalBidQuantity: 10,
          totalOfferQuantity: 100,
          filledQuantity: 7,
        ),
      },
    ),
    refs: null,
  ),
  DealMatcherScenario.expect(
    label: 'negative tradeCapacity is clamped to zero',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 5)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: {'b': -50},
    ),
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledBidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
    ),
  ),
];

/// Boycott exclusion scenarios from `world_market_deal_matcher_boycott_test.dart`.
List<DealMatcherScenario> dealMatcherBoycottScenarios() => [
  DealMatcherScenario.expect(
    label: 'blocks trade where target GP buys goods a colony Tribe sells',
    inputs: matcherInputs(
      offersByFactionId: {
        'tribeT': [matcherOffer('timber', 10, priority: 1)],
      },
      bidsByFactionId: {
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpB': 100},
      boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')},
    ),
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledOffersByFactionId: {
        'tribeT': [matcherOffer('timber', 10, priority: 1)],
      },
      unfilledBidsByFactionId: {
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'block is bidirectional (colony Tribe buying goods target GP sells)',
    inputs: matcherInputs(
      offersByFactionId: {
        'gpB': [matcherOffer('timber', 10, priority: 1)],
      },
      bidsByFactionId: {
        'tribeT': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {'tribeT': 100},
      boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')},
    ),
    expect: const DealMatchExpectation(filledDealsEmpty: true),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'only the boycotted GP is blocked; other buyers still trade',
    inputs: matcherInputs(
      offersByFactionId: {
        'tribeT': [matcherOffer('timber', 10, priority: 1)],
      },
      bidsByFactionId: {
        'gpB': [matcherBid('timber', 10, priority: 1)],
        'gpD': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpB': 100, 'gpD': 100},
      boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')},
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: const FilledDealExpectation(
        sellerFactionId: 'tribeT',
        buyerFactionId: 'gpD',
        quantity: 10,
      ),
      unfilledBidsByFactionId: {
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'empty blocked set is a no-op (legacy matching preserved)',
    inputs: matcherInputs(
      offersByFactionId: {
        'tribeT': [matcherOffer('timber', 10, priority: 1)],
      },
      bidsByFactionId: {
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpB': 100},
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(
        buyerFactionId: 'gpB',
        quantity: 10,
      ),
    ),
    refs: '#3753',
  ),
];

/// Priority and FTP precedence from `world_market_deal_matcher_priority_test.dart`.
List<DealMatcherScenario> dealMatcherPriorityAndFtpScenarios() => [
  DealMatcherScenario.expect(
    label: 'priority integer absolutely beats FTP across tiers',
    inputs: matcherInputs(
      offersByFactionId: {
        'sellerLow': [matcherOffer('timber', 10, priority: 1)],
        'sellerFtp': [matcherOffer('timber', 10, priority: 2)],
      },
      bidsByFactionId: {
        'buyerLow': [matcherBid('timber', 10, priority: 1)],
        'buyerFtp': [matcherBid('timber', 10, priority: 2)],
      },
      tradeCapacityByFactionId: {'buyerLow': 100, 'buyerFtp': 100},
      ftpPairKeys: {DealMatcher.pairKey('sellerFtp', 'buyerFtp')},
    ),
    expect: const DealMatchExpectation(
      filledDealExpectations: [
        FilledDealExpectation(buyerFactionId: 'buyerLow', isFtpMatch: false),
        FilledDealExpectation(buyerFactionId: 'buyerFtp', isFtpMatch: true),
      ],
    ),
  ),
  DealMatcherScenario.expect(
    label: 'within a tier, FTP pair fills first as tiebreaker',
    inputs: matcherInputs(
      offersByFactionId: {
        'sellerA': [matcherOffer('timber', 5, priority: 1)],
      },
      bidsByFactionId: {
        'buyerFtp': [matcherBid('timber', 5, priority: 1)],
        'buyerOther': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: {'buyerFtp': 100, 'buyerOther': 100},
      ftpPairKeys: {DealMatcher.pairKey('sellerA', 'buyerFtp')},
    ),
    expect: DealMatchExpectation(
      filledDealExpectations: const [
        FilledDealExpectation(
          buyerFactionId: 'buyerFtp',
          isFtpMatch: true,
        ),
      ],
      unfilledBidsByFactionId: {
        'buyerOther': [matcherBid('timber', 5, priority: 1)],
      },
    ),
  ),
  DealMatcherScenario.expect(
    label:
        'three GPs: FTP A↔B fills before C at same tier; C carry-forward when exhausted (#2989 FTP AC)',
    inputs: matcherInputs(
      offersByFactionId: {
        'gpA': [matcherOffer('timber', 10, priority: 1)],
      },
      bidsByFactionId: {
        'gpB': [matcherBid('timber', 10, priority: 1)],
        'gpC': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpB': 100, 'gpC': 100},
      ftpPairKeys: {DealMatcher.pairKey('gpA', 'gpB')},
    ),
    expect: DealMatchExpectation(
      filledDealExpectations: const [
        FilledDealExpectation(
          sellerFactionId: 'gpA',
          buyerFactionId: 'gpB',
          isFtpMatch: true,
        ),
      ],
      unfilledBidsByFactionId: {
        'gpC': [matcherBid('timber', 10, priority: 1)],
      },
    ),
    refs: '#2989',
  ),
  DealMatcherScenario.expect(
    label: 'FTP pair at tier 2 does not fill before non-FTP at tier 1',
    inputs: matcherInputs(
      offersByFactionId: {
        'sellerFtp': [matcherOffer('timber', 10, priority: 2)],
        'sellerOther': [matcherOffer('timber', 10, priority: 1)],
      },
      bidsByFactionId: {
        'buyerFtp': [matcherBid('timber', 10, priority: 2)],
        'buyerOther': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'buyerFtp': 100, 'buyerOther': 100},
      ftpPairKeys: {DealMatcher.pairKey('sellerFtp', 'buyerFtp')},
    ),
    expect: const DealMatchExpectation(
      firstFilledDeal: FilledDealExpectation(
        buyerFactionId: 'buyerOther',
        isFtpMatch: false,
      ),
    ),
  ),
  DealMatcherScenario.expect(
    label:
        'FTP membership is order-independent (set keyed via canonical pairKey)',
    inputs: matcherInputs(
      offersByFactionId: {
        'zeta': [matcherOffer('timber', 5)],
      },
      bidsByFactionId: {
        'alpha': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: {'alpha': 100},
      ftpPairKeys: {DealMatcher.pairKey('alpha', 'zeta')},
    ),
    expect: const DealMatchExpectation(
      filledDealExpectations: [
        FilledDealExpectation(isFtpMatch: true),
      ],
    ),
  ),
];

/// Multi-commodity and carry-forward from priority test file.
List<DealMatcherScenario> dealMatcherMultiCommodityScenarios() => [
  DealMatcherScenario.expect(
    label: 'commodities are iterated in alphabetical order (deterministic)',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('zeta', 5), matcherOffer('alpha', 5)],
      },
      bidsByFactionId: {
        'b': [matcherBid('alpha', 5), matcherBid('zeta', 5)],
      },
      tradeCapacityByFactionId: {'b': 100},
      pricesByCommodityId: const {'alpha': 1.0, 'zeta': 2.0},
    ),
    expect: const DealMatchExpectation(
      filledDealCommodityIds: ['alpha', 'zeta'],
    ),
  ),
  DealMatcherScenario.expect(
    label: 'partial fills produce carry-forward orders with copyWith semantics',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 4, priority: 3)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 9, priority: 3)],
      },
      tradeCapacityByFactionId: {'b': 100},
    ),
    expect: DealMatchExpectation(
      filledDealExpectations: const [FilledDealExpectation(quantity: 4)],
      unfilledOffersEmpty: true,
      unfilledBidsByFactionId: {
        'b': [matcherBid('timber', 5, priority: 3)],
      },
    ),
  ),
];

/// Lock-recovery seller priority (Refs #2924 F12).
List<DealMatcherScenario> dealMatcherLockRecoveryScenarios() => [
  DealMatcherScenario.expect(
    label: 'fills lock-recovery seller before earlier-id affluent seller',
    inputs: matcherInputs(
      offersByFactionId: {
        'gp1': [matcherOffer('grain', 10, priority: 2)],
        'gp4': [matcherOffer('grain', 10, priority: 2)],
      },
      bidsByFactionId: {
        'gp2': [matcherBid('grain', 3, priority: 2)],
      },
      tradeCapacityByFactionId: const {'gp2': 3},
      pricesByCommodityId: const {'grain': 10.0},
      lockRecoverySellerPriorityIds: const {'gp1', 'gp4'},
      treasuryByFactionId: const {'gp1': 100, 'gp4': -50},
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(
        sellerFactionId: 'gp4',
        quantity: 3,
      ),
    ),
    refs: '#2924',
  ),
];

/// Activity bookkeeping from priority test file.
List<DealMatcherScenario> dealMatcherActivityScenarios() => [
  DealMatcherScenario.expect(
    label: 'activity totals reflect input quantities, not just fills',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 3)],
        'c': [matcherBid('timber', 4)],
      },
      tradeCapacityByFactionId: {'b': 100, 'c': 100},
    ),
    expect: DealMatchExpectation(
      activityByCommodityId: const {
        'timber': MarketActivity(
          totalBidQuantity: 7,
          totalOfferQuantity: 10,
          filledQuantity: 7,
        ),
      },
      unfilledBidsEmpty: true,
      unfilledOffersByFactionId: {
        'a': [matcherOffer('timber', 3)],
      },
    ),
  ),
  DealMatcherScenario.expect(
    label:
        'priceChangePercent stays 0.0 (composed separately by phase handler)',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 20)],
      },
      tradeCapacityByFactionId: {'b': 100},
    ),
    expect: const DealMatchExpectation(
      activityPriceChangePercent: {'timber': 0.0},
    ),
  ),
];

/// Sell-priority relation tiebreaker from
/// `world_market_deal_matcher_sell_priority_test.dart`.
List<DealMatcherScenario> dealMatcherSellPriorityScenarios() => [
  DealMatcherScenario.expect(
    label: 'higher-relation consulate-holding buyer wins limited supply',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [matcherOffer('timber', 5, priority: 1)],
      },
      bidsByFactionId: {
        'gpHigh': [matcherBid('timber', 5, priority: 1)],
        'gpLow': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpHigh': 100, 'gpLow': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'gpHigh': 80, 'gpLow': 40},
      },
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gpHigh',
        quantity: 5,
      ),
      unfilledBidsByFactionId: {
        'gpLow': [matcherBid('timber', 5, priority: 1)],
      },
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'relation order overrides default ascending-faction-id order',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [matcherOffer('timber', 4, priority: 1)],
      },
      bidsByFactionId: {
        'aBuyer': [matcherBid('timber', 4, priority: 1)],
        'zBuyer': [matcherBid('timber', 4, priority: 1)],
      },
      tradeCapacityByFactionId: const {'aBuyer': 100, 'zBuyer': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'aBuyer': 30, 'zBuyer': 90},
      },
    ),
    expect: const DealMatchExpectation(
      firstFilledDeal: FilledDealExpectation(buyerFactionId: 'zBuyer'),
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'consulate-less buyer falls back behind consulate-holding buyer',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [matcherOffer('timber', 5, priority: 1)],
      },
      bidsByFactionId: {
        'gpHigh': [matcherBid('timber', 5, priority: 1)],
        'gpLow': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpHigh': 100, 'gpLow': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'gpLow': 40},
      },
    ),
    expect: DealMatchExpectation(
      firstFilledDeal: const FilledDealExpectation(buyerFactionId: 'gpLow'),
      unfilledBidsByFactionId: {
        'gpHigh': [matcherBid('timber', 5, priority: 1)],
      },
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'relation tie breaks deterministically by ascending faction id',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [matcherOffer('timber', 5, priority: 1)],
      },
      bidsByFactionId: {
        'gpB': [matcherBid('timber', 5, priority: 1)],
        'gpA': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpA': 100, 'gpB': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'gpA': 55, 'gpB': 55},
      },
    ),
    expect: const DealMatchExpectation(
      firstFilledDeal: FilledDealExpectation(buyerFactionId: 'gpA'),
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'seller absent from map keeps legacy ordering (no reorder)',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorN': [matcherOffer('timber', 5, priority: 1)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 5, priority: 1)],
        'gpZ': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpA': 100, 'gpZ': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'gpA': 1, 'gpZ': 99},
      },
    ),
    expect: const DealMatchExpectation(
      firstFilledDeal: FilledDealExpectation(buyerFactionId: 'gpA'),
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'empty relation map preserves legacy ordering for minor seller',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [matcherOffer('timber', 5, priority: 1)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 5, priority: 1)],
        'gpZ': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpA': 100, 'gpZ': 100},
    ),
    expect: const DealMatchExpectation(
      firstFilledDeal: FilledDealExpectation(buyerFactionId: 'gpA'),
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'priority tier remains absolute over relation tiebreaker',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [
          matcherOffer('timber', 5, priority: 1),
          matcherOffer('timber', 5, priority: 2),
        ],
      },
      bidsByFactionId: {
        'gpHigh': [matcherBid('timber', 5, priority: 2)],
        'gpLow': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpHigh': 100, 'gpLow': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'gpHigh': 90, 'gpLow': 10},
      },
    ),
    expect: const DealMatchExpectation(
      filledDealExpectations: [
        FilledDealExpectation(buyerFactionId: 'gpLow'),
        FilledDealExpectation(buyerFactionId: 'gpHigh'),
      ],
    ),
    refs: '#3753',
  ),
];

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

const _frrTileKey = 'oldWorld|M1|0|0';

/// FRR matcher integration from `world_market_deal_matcher_first_right_test.dart`.
List<DealMatcherScenario> dealMatcherFirstRightScenarios() => [
  ...dealMatcherFirstRightRoutingScenarios(),
  ...dealMatcherFirstRightMultiBidScenarios(),
];

List<DealMatcherScenario> dealMatcherFirstRightRoutingScenarios() => [
  DealMatcherScenario.expect(
    label:
        'partial FRR fill: residual offer quantity becomes available for '
        'other GPs at their normal priority tier',
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [matcherOffer('timber', 10, originTileKey: _frrTileKey)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 4, priority: 5)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
      purchasedTileIndex: frrMatcherTestIndex(),
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 2,
      frrFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gpA',
        quantity: 4,
      ),
      nonFrrFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gpB',
        quantity: 6,
      ),
      unfilledBidsByFactionId: {
        'gpB': [matcherBid('timber', 4, priority: 1)],
      },
      unfilledOffersEmpty: true,
    ),
    refs: '#2992',
  ),
  DealMatcherScenario.expect(
    label:
        'cargo limit caps FRR fill (per-buyer cumulative cargo still applies)',
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [matcherOffer('timber', 10, originTileKey: _frrTileKey)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 1)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 3, 'gpB': 100},
      purchasedTileIndex: frrMatcherTestIndex(),
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 2,
      frrFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gpA',
        quantity: 3,
      ),
      nonFrrFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gpB',
        quantity: 7,
      ),
      unfilledBidsPinsByFactionId: {
        'gpA': [matcherBid('timber', 7, priority: 1)],
      },
    ),
    refs: '#2992',
  ),
  DealMatcherScenario.expect(
    label: 'offer without originTileKey is unaffected by FRR even when index '
        'has matching attributions',
    inputs: matcherInputs(
      offersByFactionId: {
        'sellerX': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 5)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
      purchasedTileIndex: frrMatcherTestIndex(),
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(
        buyerFactionId: 'gpB',
        isFirstRightOfRefusalMatch: false,
      ),
    ),
    refs: '#2992',
  ),
  DealMatcherScenario.expect(
    label: 'offer with originTileKey not present in index falls back to normal '
        'matching (no FRR)',
    inputs: matcherInputs(
      offersByFactionId: {
        'M2': [
          matcherOffer('timber', 10, originTileKey: 'oldWorld|M2|7|3'),
        ],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 5)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
      purchasedTileIndex: frrMatcherTestIndex(),
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(
        buyerFactionId: 'gpB',
        isFirstRightOfRefusalMatch: false,
      ),
    ),
    refs: '#2992',
  ),
  DealMatcherScenario.expect(
    label: 'null purchasedTileIndex disables FRR (legacy behavior preserved)',
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [matcherOffer('timber', 10, originTileKey: _frrTileKey)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 5)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(
        buyerFactionId: 'gpB',
        isFirstRightOfRefusalMatch: false,
      ),
    ),
    refs: '#2992',
  ),
];

List<DealMatcherScenario> dealMatcherFirstRightMultiBidScenarios() => [
  DealMatcherScenario.expect(
    label:
        'multiple purchased tiles owned by the same GP each route through FRR',
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [
          matcherOffer('timber', 5, originTileKey: _frrTileKey),
          matcherOffer('timber', 5, originTileKey: 'oldWorld|M1|1|0'),
        ],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100},
      purchasedTileIndex: PurchasedTileIndex.forTesting(const [
        PurchasedTileAttribution(
          tileKey: _frrTileKey,
          owningGpId: 'gpA',
          sourceFactionId: 'M1',
          provinceId: 'oldWorld|M1',
        ),
        PurchasedTileAttribution(
          tileKey: 'oldWorld|M1|1|0',
          owningGpId: 'gpA',
          sourceFactionId: 'M1',
          provinceId: 'oldWorld|M1',
        ),
      ]),
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 2,
      filledDealExpectations: const [
        FilledDealExpectation(
          buyerFactionId: 'gpA',
          quantity: 5,
          isFirstRightOfRefusalMatch: true,
        ),
        FilledDealExpectation(
          buyerFactionId: 'gpA',
          quantity: 5,
          isFirstRightOfRefusalMatch: true,
        ),
      ],
      unfilledOffersEmpty: true,
      unfilledBidsEmpty: true,
    ),
    refs: '#2992',
  ),
  DealMatcherScenario.expect(
    label:
        'FRR pass respects multiple bids from the owning GP in submission order',
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [matcherOffer('timber', 10, originTileKey: _frrTileKey)],
      },
      bidsByFactionId: {
        'gpA': [
          matcherBid('timber', 4, priority: 1),
          matcherBid('timber', 8, priority: 5),
        ],
      },
      tradeCapacityByFactionId: {'gpA': 100},
      purchasedTileIndex: frrMatcherTestIndex(),
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 2,
      filledDealExpectations: const [
        FilledDealExpectation(
          buyerFactionId: 'gpA',
          quantity: 4,
          isFirstRightOfRefusalMatch: true,
        ),
        FilledDealExpectation(
          buyerFactionId: 'gpA',
          quantity: 6,
          isFirstRightOfRefusalMatch: true,
        ),
      ],
      unfilledBidsByFactionId: {
        'gpA': [matcherBid('timber', 2, priority: 5)],
      },
    ),
    refs: '#2992',
  ),
];

/// FRR activity bookkeeping from supplement test file.
List<DealMatcherScenario> dealMatcherFrrActivityScenarios() => [
  DealMatcherScenario.expect(
    label:
        'FRR fills count toward filledQuantity in the per-commodity activity',
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [matcherOffer('timber', 10, originTileKey: _frrTileKey)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 6, priority: 5)],
        'gpB': [matcherBid('timber', 6, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
      purchasedTileIndex: frrMatcherTestIndex(),
    ),
    expect: const DealMatchExpectation(
      activityByCommodityId: {
        'timber': MarketActivity(
          totalBidQuantity: 12,
          totalOfferQuantity: 10,
          filledQuantity: 10,
        ),
      },
    ),
    refs: '#2992',
  ),
];
const String _kFrrIssueAcD5GpA = 'gpA';
const String _kFrrIssueAcD5GpB = 'gpB';
const String _kFrrIssueAcD5GpC = 'gpC';
const String _kFrrIssueAcD5GpFtp = 'gpFtp';
const String _kFrrIssueAcD5MinorM1 = 'M1';
const String _kFrrIssueAcD5MinorM2 = 'M2';
const String _kFrrIssueAcD5TileK1 = 'oldWorld|M1|0|0';
const String _kFrrIssueAcD5TileK2 = 'oldWorld|M1|1|0';
const String _kFrrIssueAcD5TileK3 = 'oldWorld|M2|0|0';
const String _kFrrIssueAcD5ProvinceM1 = 'oldWorld|M1';
const String _kFrrIssueAcD5ProvinceM2 = 'oldWorld|M2';

PurchasedTileAttribution _d5Attr(
  String tileKey,
  String owningGpId,
  String sourceFactionId, [
  String provinceId = _kFrrIssueAcD5ProvinceM1,
]) => attr(
  tileKey: tileKey,
  owningGpId: owningGpId,
  sourceFactionId: sourceFactionId,
  provinceId: provinceId,
);

DealMatchInputs _d5MatcherInputs({
  required Map<String, List<TradeOrder>> offersByFactionId,
  required Map<String, List<TradeOrder>> bidsByFactionId,
  required Map<String, int> tradeCapacityByFactionId,
  Map<String, int>? treasuryBudgetByBuyerFactionId,
  Set<String> ftpPairKeys = const {},
  PurchasedTileIndex? purchasedTileIndex,
}) => matcherInputs(
  offersByFactionId: offersByFactionId,
  bidsByFactionId: bidsByFactionId,
  tradeCapacityByFactionId: tradeCapacityByFactionId,
  treasuryBudgetByBuyerFactionId: treasuryBudgetByBuyerFactionId,
  pricesByCommodityId: const {'timber': 20.0},
  ftpPairKeys: ftpPairKeys,
  purchasedTileIndex: purchasedTileIndex,
);

List<DealMatcherScenario> frrIssueAcD5MatcherScenarios() => [
  DealMatcherScenario.expect(
    label:
        'rival priority-1 bid loses to owning-GP priority-5 bid; rival '
        'priority-1 bid carries forward intact',
    inputs: _d5MatcherInputs(
      offersByFactionId: {
        _kFrrIssueAcD5MinorM1: [
          matcherOffer(
            'timber',
            10,
            originTileKey: _kFrrIssueAcD5TileK1,
          ),
        ],
      },
      bidsByFactionId: {
        _kFrrIssueAcD5GpA: [matcherBid('timber', 10, priority: 5)],
        _kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {
        _kFrrIssueAcD5GpA: 100,
        _kFrrIssueAcD5GpB: 100,
      },
      purchasedTileIndex: idx([
        _d5Attr(_kFrrIssueAcD5TileK1, _kFrrIssueAcD5GpA, _kFrrIssueAcD5MinorM1),
      ]),
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      frrFilledDeal: const FilledDealExpectation(
        buyerFactionId: _kFrrIssueAcD5GpA,
        quantity: 10,
        isFirstRightOfRefusalMatch: true,
        isFtpMatch: false,
      ),
      unfilledBidsByFactionId: {
        _kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
      },
    ),
    refs: '#2992 D5 AC1',
  ),
  DealMatcherScenario.expect(
    label:
        'FTP-paired rival bid at same priority loses to owning GP; FTP '
        'partner bid carries forward (FRR overrides FTP)',
    inputs: _d5MatcherInputs(
      offersByFactionId: {
        _kFrrIssueAcD5MinorM1: [
          matcherOffer(
            'timber',
            6,
            originTileKey: _kFrrIssueAcD5TileK1,
          ),
        ],
      },
      bidsByFactionId: {
        _kFrrIssueAcD5GpA: [matcherBid('timber', 6, priority: 1)],
        _kFrrIssueAcD5GpFtp: [matcherBid('timber', 6, priority: 1)],
      },
      tradeCapacityByFactionId: const {
        _kFrrIssueAcD5GpA: 100,
        _kFrrIssueAcD5GpFtp: 100,
      },
      ftpPairKeys: {
        DealMatcher.pairKey(_kFrrIssueAcD5MinorM1, _kFrrIssueAcD5GpFtp),
      },
      purchasedTileIndex: idx([
        _d5Attr(_kFrrIssueAcD5TileK1, _kFrrIssueAcD5GpA, _kFrrIssueAcD5MinorM1),
      ]),
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      frrFilledDeal: const FilledDealExpectation(
        buyerFactionId: _kFrrIssueAcD5GpA,
        isFirstRightOfRefusalMatch: true,
        isFtpMatch: false,
      ),
      unfilledBidsByFactionId: {
        _kFrrIssueAcD5GpFtp: [matcherBid('timber', 6, priority: 1)],
      },
    ),
    refs: '#2992 D5 AC1',
  ),
  DealMatcherScenario.expect(
    label:
        'negative — owning GP does NOT bid: purchased-tile offer falls '
        'back to standard tier matching (not FRR-flagged)',
    inputs: _d5MatcherInputs(
      offersByFactionId: {
        _kFrrIssueAcD5MinorM1: [
          matcherOffer(
            'timber',
            10,
            originTileKey: _kFrrIssueAcD5TileK1,
          ),
        ],
      },
      bidsByFactionId: {
        _kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {_kFrrIssueAcD5GpB: 100},
      purchasedTileIndex: idx([
        _d5Attr(_kFrrIssueAcD5TileK1, _kFrrIssueAcD5GpA, _kFrrIssueAcD5MinorM1),
      ]),
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      nonFrrFilledDeal: FilledDealExpectation(
        buyerFactionId: _kFrrIssueAcD5GpB,
        isFirstRightOfRefusalMatch: false,
      ),
    ),
    refs: '#2992 D5 AC1',
  ),
];
