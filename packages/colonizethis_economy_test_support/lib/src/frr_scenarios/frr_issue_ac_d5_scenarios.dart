// Issue #2992 D5 acceptance-criteria scenario tables (Refs #3856 phase-2 slice 8).
//
// Each list maps 1:1 to the five numbered AC groups in
// `first_right_of_refusal_issue_acceptance_criteria_d5_test.dart` so
// `verify-github-issue` can audit AC↔test coverage without cross-referencing
// slice files.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../deal_matcher_scenarios/deal_matcher_core_scenarios.dart';
import '../deal_matcher_scenarios/deal_matcher_expectations.dart';
import '../deal_matcher_scenarios/deal_matcher_test_support.dart';
import 'frr_credits_expectations.dart';
import 'frr_credits_scenarios.dart';
import 'frr_credits_test_support.dart';

const String kFrrIssueAcD5GpA = 'gpA';
const String kFrrIssueAcD5GpB = 'gpB';
const String kFrrIssueAcD5GpC = 'gpC';
const String kFrrIssueAcD5GpFtp = 'gpFtp';
const String kFrrIssueAcD5MinorM1 = 'M1';
const String kFrrIssueAcD5MinorM2 = 'M2';
const String kFrrIssueAcD5TileK1 = 'oldWorld|M1|0|0';
const String kFrrIssueAcD5TileK2 = 'oldWorld|M1|1|0';
const String kFrrIssueAcD5TileK3 = 'oldWorld|M2|0|0';
const String kFrrIssueAcD5ProvinceM1 = 'oldWorld|M1';
const String kFrrIssueAcD5ProvinceM2 = 'oldWorld|M2';

PurchasedTileAttribution _d5Attr(
  String tileKey,
  String owningGpId,
  String sourceFactionId, [
  String provinceId = kFrrIssueAcD5ProvinceM1,
]) => attr(
  tileKey: tileKey,
  owningGpId: owningGpId,
  sourceFactionId: sourceFactionId,
  provinceId: provinceId,
);

FilledDeal _d5OtherBuyDeal({
  String seller = kFrrIssueAcD5MinorM1,
  String buyer = kFrrIssueAcD5GpB,
  int quantity = 10,
  double pricePerUnit = 20.0,
  String sellerOriginTileKey = kFrrIssueAcD5TileK1,
}) => deal(
  seller: seller,
  buyer: buyer,
  quantity: quantity,
  pricePerUnit: pricePerUnit,
  sellerOriginTileKey: sellerOriginTileKey,
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

/// AC #1 — owning-GP bid wins above priority tiers AND FTP.
List<DealMatcherScenario> frrIssueAcD5MatcherScenarios() => [
  DealMatcherScenario.expect(
    label:
        'rival priority-1 bid loses to owning-GP priority-5 bid; rival '
        'priority-1 bid carries forward intact',
    inputs: _d5MatcherInputs(
      offersByFactionId: {
        kFrrIssueAcD5MinorM1: [
          matcherOffer(
            'timber',
            10,
            originTileKey: kFrrIssueAcD5TileK1,
          ),
        ],
      },
      bidsByFactionId: {
        kFrrIssueAcD5GpA: [matcherBid('timber', 10, priority: 5)],
        kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {
        kFrrIssueAcD5GpA: 100,
        kFrrIssueAcD5GpB: 100,
      },
      purchasedTileIndex: idx([
        _d5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
      ]),
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      frrFilledDeal: const FilledDealExpectation(
        buyerFactionId: kFrrIssueAcD5GpA,
        quantity: 10,
        isFirstRightOfRefusalMatch: true,
        isFtpMatch: false,
      ),
      unfilledBidsByFactionId: {
        kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
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
        kFrrIssueAcD5MinorM1: [
          matcherOffer(
            'timber',
            6,
            originTileKey: kFrrIssueAcD5TileK1,
          ),
        ],
      },
      bidsByFactionId: {
        kFrrIssueAcD5GpA: [matcherBid('timber', 6, priority: 1)],
        kFrrIssueAcD5GpFtp: [matcherBid('timber', 6, priority: 1)],
      },
      tradeCapacityByFactionId: const {
        kFrrIssueAcD5GpA: 100,
        kFrrIssueAcD5GpFtp: 100,
      },
      ftpPairKeys: {
        DealMatcher.pairKey(kFrrIssueAcD5MinorM1, kFrrIssueAcD5GpFtp),
      },
      purchasedTileIndex: idx([
        _d5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
      ]),
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      frrFilledDeal: const FilledDealExpectation(
        buyerFactionId: kFrrIssueAcD5GpA,
        isFirstRightOfRefusalMatch: true,
        isFtpMatch: false,
      ),
      unfilledBidsByFactionId: {
        kFrrIssueAcD5GpFtp: [matcherBid('timber', 6, priority: 1)],
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
        kFrrIssueAcD5MinorM1: [
          matcherOffer(
            'timber',
            10,
            originTileKey: kFrrIssueAcD5TileK1,
          ),
        ],
      },
      bidsByFactionId: {
        kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {kFrrIssueAcD5GpB: 100},
      purchasedTileIndex: idx([
        _d5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
      ]),
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      nonFrrFilledDeal: FilledDealExpectation(
        buyerFactionId: kFrrIssueAcD5GpB,
        isFirstRightOfRefusalMatch: false,
      ),
    ),
    refs: '#2992 D5 AC1',
  ),
];

/// AC #2 — relation 75 credits 10*20*0.75 = 150 treasury (full share).
List<FrrCreditsScenario> frrIssueAcD5CreditsAc2Scenarios() => [
  FrrCreditsScenario.expect(
    label: 'credits helper produces rate 0.75 + treasury 150.0 for gpA',
    filledDeals: [_d5OtherBuyDeal()],
    purchasedTileIndex: idx([
      _d5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
    ]),
    relationScoreFor: (gp, src) =>
        gp == kFrrIssueAcD5GpA && src == kFrrIssueAcD5MinorM1 ? 75 : 0,
    expect: const FrrCreditsExpectation(
      creditedDealsLength: 1,
      singleCreditedDealOwningGpId: kFrrIssueAcD5GpA,
      singleCreditedDealSourceFactionId: kFrrIssueAcD5MinorM1,
      singleCreditedDealRelationScore: 75,
      singleCreditedDealProfitRateCloseTo: 0.75,
      singleCreditedDealProfitTreasuryCloseTo: 150.0,
      treasuryCreditCloseTo: {kFrrIssueAcD5GpA: 150.0},
      totalProfitTreasury: 150.0,
    ),
    refs: '#2992 D5 AC2',
  ),
];

/// AC #3 — relation 100 credits exactly 100% of sale value.
List<FrrCreditsScenario> frrIssueAcD5CreditsAc3Scenarios() => [
  FrrCreditsScenario.expect(
    label:
        'credits helper produces rate kFirstRightMaxProfitRate (1.0) and '
        'treasury == quantity * pricePerUnit (full share)',
    filledDeals: [_d5OtherBuyDeal(quantity: 5, pricePerUnit: 8.0)],
    purchasedTileIndex: idx([
      _d5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
    ]),
    relationScoreFor: (_, __) => 100,
    expect: FrrCreditsExpectation(
      creditedDealsLength: 1,
      singleCreditedDealProfitRateCloseTo: kFirstRightMaxProfitRate,
      treasuryCreditCloseTo: {kFrrIssueAcD5GpA: 40.0},
      totalProfitTreasury: 40.0,
    ),
    refs: '#2992 D5 AC3',
  ),
];

/// AC #4 — relation 0 credits 0 treasury (no overseas profit).
List<FrrCreditsScenario> frrIssueAcD5CreditsAc4Scenarios() => [
  FrrCreditsScenario.expect(
    label:
        'credits helper records audit row but transfers 0 treasury (Deal '
        'Book can still surface the no-credit case)',
    filledDeals: [_d5OtherBuyDeal()],
    purchasedTileIndex: idx([
      _d5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
    ]),
    relationScoreFor: (_, __) => 0,
    expect: const FrrCreditsExpectation(
      creditedDealsLength: 1,
      singleCreditedDealProfitIsZero: true,
      treasuryCreditByGpId: {kFrrIssueAcD5GpA: 0.0},
      totalProfitTreasury: 0.0,
    ),
    refs: '#2992 D5 AC4',
  ),
  FrrCreditsScenario.expect(
    label:
        'negative — buyer == owning GP (D2 FRR-match path) excluded from '
        'D4 aggregation: no double-credit when gpA wins the offer itself',
    filledDeals: [
      FilledDeal(
        sellerFactionId: kFrrIssueAcD5MinorM1,
        buyerFactionId: kFrrIssueAcD5GpA,
        commodityId: 'timber',
        quantity: 10,
        pricePerUnit: 20.0,
        isFirstRightOfRefusalMatch: true,
        sellerOriginTileKey: kFrrIssueAcD5TileK1,
      ),
    ],
    purchasedTileIndex: idx([
      _d5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
    ]),
    relationScoreFor: (_, __) => 100,
    expect: const FrrCreditsExpectation(
      creditedDealsEmpty: true,
      treasuryCreditEmpty: true,
      totalProfitTreasury: 0.0,
    ),
    refs: '#2992 D5 AC4',
  ),
];

/// AC #5 — multi-GP attribution, no cross-credit.
List<FrrCreditsScenario> frrIssueAcD5CreditsAc5Scenarios() => [
  FrrCreditsScenario.expect(
    label:
        'k1 (gpA, relation 100) + k2 (gpB, relation 50) → gpA 60.0, gpB '
        '20.0; neither GP is credited for the other GP\'s purchased tile',
    filledDeals: [
      _d5OtherBuyDeal(
        buyer: kFrrIssueAcD5GpC,
        quantity: 6,
        pricePerUnit: 10.0,
        sellerOriginTileKey: kFrrIssueAcD5TileK1,
      ),
      _d5OtherBuyDeal(
        buyer: kFrrIssueAcD5GpC,
        quantity: 4,
        pricePerUnit: 10.0,
        sellerOriginTileKey: kFrrIssueAcD5TileK2,
      ),
    ],
    purchasedTileIndex: idx([
      _d5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
      _d5Attr(kFrrIssueAcD5TileK2, kFrrIssueAcD5GpB, kFrrIssueAcD5MinorM1),
    ]),
    relationScoreFor: (gp, src) {
      if (gp == kFrrIssueAcD5GpA && src == kFrrIssueAcD5MinorM1) return 100;
      if (gp == kFrrIssueAcD5GpB && src == kFrrIssueAcD5MinorM1) return 50;
      return 0;
    },
    expect: const FrrCreditsExpectation(
      treasuryCreditKeysContainAll: [kFrrIssueAcD5GpA, kFrrIssueAcD5GpB],
      treasuryCreditCloseTo: {
        kFrrIssueAcD5GpA: 60.0,
        kFrrIssueAcD5GpB: 20.0,
      },
      totalProfitTreasury: 80.0,
    ),
    refs: '#2992 D5 AC5',
  ),
  FrrCreditsScenario.expect(
    label:
        'same owning GP across two minors aggregates per source relation '
        'independently (k1@M1 relation 100 + k3@M2 relation 25 → gpA 45.0)',
    filledDeals: [
      _d5OtherBuyDeal(
        buyer: kFrrIssueAcD5GpC,
        quantity: 5,
        pricePerUnit: 8.0,
        sellerOriginTileKey: kFrrIssueAcD5TileK1,
      ),
      FilledDeal(
        sellerFactionId: kFrrIssueAcD5MinorM2,
        buyerFactionId: kFrrIssueAcD5GpC,
        commodityId: 'timber',
        quantity: 2,
        pricePerUnit: 10.0,
        sellerOriginTileKey: kFrrIssueAcD5TileK3,
      ),
    ],
    purchasedTileIndex: idx([
      _d5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
      _d5Attr(
        kFrrIssueAcD5TileK3,
        kFrrIssueAcD5GpA,
        kFrrIssueAcD5MinorM2,
        kFrrIssueAcD5ProvinceM2,
      ),
    ]),
    relationScoreFor: (gp, src) {
      if (gp == kFrrIssueAcD5GpA && src == kFrrIssueAcD5MinorM1) return 100;
      if (gp == kFrrIssueAcD5GpA && src == kFrrIssueAcD5MinorM2) return 25;
      return 0;
    },
    expect: const FrrCreditsExpectation(
      creditedDealsLength: 2,
      treasuryCreditKeysExact: [kFrrIssueAcD5GpA],
      treasuryCreditCloseTo: {kFrrIssueAcD5GpA: 45.0},
      totalProfitTreasury: 45.0,
    ),
    refs: '#2992 D5 AC5',
  ),
];
