// FRR DealMatcher scenarios (Refs #3836, #3939).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../frr_scenarios/frr_credits_test_support.dart';
import 'deal_matcher_expectations.dart';
import 'deal_matcher_scenario.dart';
import 'deal_matcher_test_support.dart';

const _frrTileKey = kFrrMatcherTestTileKey;

/// FRR matcher integration from `world_market_deal_matcher_first_right_test.dart`.
List<DealMatcherScenario> dealMatcherFirstRightScenarios() => [
  ...dealMatcherFirstRightRoutingScenarios(),
  ...dealMatcherFirstRightMultiBidScenarios(),
];

List<DealMatcherScenario> dealMatcherFirstRightRoutingScenarios() => [
  frrPartialFillRow(
    label:
        'partial FRR fill: residual offer quantity becomes available for '
        'other GPs at their normal priority tier',
  ),
  frrCargoCapRow(
    label:
        'cargo limit caps FRR fill (per-buyer cumulative cargo still applies)',
  ),
  frrNoFrrFallbackRow(
    label: 'offer without originTileKey is unaffected by FRR even when index '
        'has matching attributions',
    offersByFactionId: {
      'sellerX': [matcherOffer('timber', 10)],
    },
    purchasedTileIndex: frrMatcherTestIndex(),
  ),
  frrNoFrrFallbackRow(
    label: 'offer with originTileKey not present in index falls back to normal '
        'matching (no FRR)',
    offersByFactionId: {
      'M2': [
        matcherOffer('timber', 10, originTileKey: 'oldWorld|M2|7|3'),
      ],
    },
    purchasedTileIndex: frrMatcherTestIndex(),
  ),
  frrNoFrrFallbackRow(
    label: 'null purchasedTileIndex disables FRR (legacy behavior preserved)',
    offersByFactionId: {
      'M1': [matcherOffer('timber', 10, originTileKey: _frrTileKey)],
    },
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
      purchasedTileIndex: frrMatcherTestIndexDual(),
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
