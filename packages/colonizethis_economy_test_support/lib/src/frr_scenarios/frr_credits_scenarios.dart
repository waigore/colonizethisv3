// Table-driven First Right credits scenarios (Refs #3836, #3939 slice 44).

import 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        FirstRightCreditsResult,
        PurchasedTileIndex,
        computeFirstRightCredits,
        kFirstRightMaxProfitRate;
import 'package:colonizethis_models/colonizethis_models.dart' show FilledDeal;
import 'package:colonizethis_test/test.dart';

import 'frr_credits_expectations.dart';
import 'frr_credits_test_support.dart';
import 'frr_d5_test_support.dart';

/// One row for `computeFirstRightCredits` scenario tables.
class FrrCreditsScenario {
  const FrrCreditsScenario({
    required this.label,
    required this.filledDeals,
    required this.purchasedTileIndex,
    required this.relationScoreFor,
    required this.verify,
    this.embassyGpRelationsFor,
    this.deterministicRerunFirstKey,
    this.refs,
  });

  final List<FilledDeal> filledDeals;
  final PurchasedTileIndex? purchasedTileIndex;
  final num Function(String owningGpId, String sourceFactionId)
  relationScoreFor;
  final Map<String, num> Function(String sourceFactionId)?
  embassyGpRelationsFor;
  final String label;
  final void Function(FirstRightCreditsResult result) verify;
  final String? deterministicRerunFirstKey;
  final String? refs;
}

void runFrrCreditsScenario(FrrCreditsScenario scenario) {
  FirstRightCreditsResult run() => computeFirstRightCredits(
    filledDeals: scenario.filledDeals,
    purchasedTileIndex: scenario.purchasedTileIndex,
    relationScoreFor: scenario.relationScoreFor,
    embassyGpRelationsFor: scenario.embassyGpRelationsFor,
  );
  final result = run();
  scenario.verify(result);
  final firstKey = scenario.deterministicRerunFirstKey;
  if (firstKey != null) {
    final second = run();
    expect(
      result.treasuryCreditByGpId.keys.toList(),
      equals(second.treasuryCreditByGpId.keys.toList()),
    );
    for (final key in result.treasuryCreditByGpId.keys) {
      expect(
        result.treasuryCreditByGpId[key],
        equals(second.treasuryCreditByGpId[key]),
      );
    }
    expect(result.creditedDeals.length, second.creditedDeals.length);
    expect(
      result.treasuryCreditByGpId.keys.first,
      firstKey,
      reason: 'insertion order tracks first deal mentioning each owning GP',
    );
  }
}

/// Compact FRR credits row builder (Refs #3939 slice 44 / 57 / 60).
FrrCreditsScenario frrCreditsRow({
  required String label,
  required FrrCreditsExpectation expect,
  List<FilledDeal>? filledDeals,
  PurchasedTileIndex? purchasedTileIndex,
  bool nullPurchasedTileIndex = false,
  num Function(String owningGpId, String sourceFactionId)? relationScoreFor,
  int? constantRelation,
  Map<String, num> Function(String sourceFactionId)? embassyGpRelationsFor,
  String? deterministicRerunFirstKey,
  String? refs,
}) {
  final num Function(String, String) relation =
      relationScoreFor ??
      (constantRelation != null
          ? frrConstantRelation(constantRelation)
          : frrAlwaysZeroRelation);
  return FrrCreditsScenario(
    label: label,
    filledDeals: filledDeals ?? [dealOn('k1', buyer: 'gpB')],
    purchasedTileIndex: nullPurchasedTileIndex
        ? null
        : (purchasedTileIndex ?? frrIdxK1GpA()),
    relationScoreFor: relation,
    embassyGpRelationsFor: embassyGpRelationsFor,
    deterministicRerunFirstKey: deterministicRerunFirstKey,
    verify: (result) => assertFrrCreditsExpectation(result, expect),
    refs: refs,
  );
}

/// Empty-result defensive row (Refs #3939 slice 60).
FrrCreditsScenario frrEmptyCreditsRow({
  required String label,
  List<FilledDeal>? filledDeals,
  PurchasedTileIndex? purchasedTileIndex,
  bool nullPurchasedTileIndex = false,
  int? constantRelation,
  double? totalProfitTreasury,
  String? refs = '#2992',
}) => frrCreditsRow(
  label: label,
  filledDeals: filledDeals,
  purchasedTileIndex: purchasedTileIndex,
  nullPurchasedTileIndex: nullPurchasedTileIndex,
  constantRelation: constantRelation,
  expect: FrrCreditsExpectation(
    empty: true,
    totalProfitTreasury: totalProfitTreasury,
  ),
  refs: refs,
);

/// Defensive / skip branches from `first_right_credits_test.dart`.
List<FrrCreditsScenario> frrCreditsDefensiveScenarios() => [
  frrEmptyCreditsRow(
    label: 'empty input returns FirstRightCreditsResult.empty (no deals)',
    filledDeals: const <FilledDeal>[],
    totalProfitTreasury: 0.0,
  ),
  frrEmptyCreditsRow(
    label: 'empty purchased-tile index returns FirstRightCreditsResult.empty',
    purchasedTileIndex: idx(const []),
  ),
  frrEmptyCreditsRow(
    label: 'null purchased-tile index returns FirstRightCreditsResult.empty',
    nullPurchasedTileIndex: true,
  ),
  frrEmptyCreditsRow(
    label: 'negative — deal with null sellerOriginTileKey is skipped',
    filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
    constantRelation: 100,
  ),
  frrEmptyCreditsRow(
    label: 'negative — deal with unmapped tile key is skipped (no attribution)',
    filledDeals: [dealOn('unmapped', buyer: 'gpB')],
    constantRelation: 100,
  ),
  frrEmptyCreditsRow(
    label: 'negative — zero quantity or zero price deals are skipped',
    filledDeals: [
      dealOn('k1', buyer: 'gpB', quantity: 0, pricePerUnit: 20.0),
      dealOn('k1', buyer: 'gpB', quantity: 10, pricePerUnit: 0.0),
    ],
    constantRelation: 100,
  ),
];

FrrCreditsScenario _frrCreditsDeterminismScenario() => frrCreditsRow(
  label:
      'deterministic — identical inputs return identical credit/aggregation order',
  filledDeals: [
    dealOn('k2', buyer: 'gpC', quantity: 1, pricePerUnit: 5.0),
    dealOn('k1', buyer: 'gpC', quantity: 2, pricePerUnit: 5.0),
    dealOn('k2', buyer: 'gpC', quantity: 3, pricePerUnit: 5.0),
  ],
  purchasedTileIndex: idx([
    attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    attr(tileKey: 'k2', owningGpId: 'gpB', sourceFactionId: 'M1'),
  ]),
  relationScoreFor: (_, __) => 100,
  expect: const FrrCreditsExpectation(),
  deterministicRerunFirstKey: 'gpB',
  refs: '#3753',
);

/// Aggregation cases from `first_right_credits_aggregation_test.dart`.
List<FrrCreditsScenario> frrCreditsAggregationScenarios() => [
  frrCreditsRow(
    label: 'multi-tile — two owning GPs aggregate credits independently',
    filledDeals: [
      dealOn('k1', buyer: 'gpC', quantity: 10, pricePerUnit: 10.0),
      dealOn('k2', buyer: 'gpC', quantity: 4, pricePerUnit: 5.0),
      dealOn('k3', buyer: 'gpC', quantity: 2, pricePerUnit: 3.0),
    ],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
      attr(tileKey: 'k2', owningGpId: 'gpB', sourceFactionId: 'M1'),
      attr(tileKey: 'k3', owningGpId: 'gpA', sourceFactionId: 'M2'),
    ]),
    relationScoreFor: frrRelationTable(const {
      'gpA': {'M1': 100, 'M2': 25},
      'gpB': {'M1': 50},
    }),
    expect: const FrrCreditsExpectation(
      treasuryCreditKeysContainAll: ['gpA', 'gpB'],
      treasuryCreditCloseTo: {'gpA': 101.5, 'gpB': 10.0},
      totalProfitTreasury: 111.5,
      creditedDealsLength: 3,
    ),
    refs: '#3753',
  ),
  frrCreditsRow(
    label:
        'multi-GP precedence — buyer == owning GP for one tile, other-GP buyer for another',
    filledDeals: [
      dealOn(
        'k1',
        buyer: 'gpA',
        isFirstRightOfRefusalMatch: true,
        quantity: 4,
        pricePerUnit: 10.0,
      ),
      dealOn('k1', buyer: 'gpB', quantity: 6, pricePerUnit: 10.0),
    ],
    constantRelation: 100,
    expect: const FrrCreditsExpectation(
      creditedDealsLength: 1,
      singleCreditedDealBuyer: 'gpB',
      treasuryCreditCloseTo: {'gpA': 60.0},
      totalProfitTreasury: 60.0,
    ),
    refs: '#3753',
  ),
  _frrCreditsDeterminismScenario(),
];

/// Embassy kickback cases from `first_right_credits_kickback_test.dart`.
List<FrrCreditsScenario> frrCreditsKickbackScenarios() => [
  frrCreditsRow(
    label:
        'non-owner embassy GP receives 10% kickback while tile owner gets full '
        'share and no kickback',
    relationScoreFor: frrRelationTable(const {
      'gpA': {'M1': 100},
    }),
    embassyGpRelationsFor: frrEmbassyForM1(const {'gpA': 100, 'gpC': 50}),
    expect: const FrrCreditsExpectation(
      treasuryCreditCloseTo: {'gpA': 200.0},
      noEmbassyKickbackFor: ['gpA'],
      embassyKickbackCloseTo: {'gpC': 10.0},
      totalEmbassyKickback: 10.0,
    ),
    refs: '#3753',
  ),
  frrCreditsRow(
    label: 'R8.6 — kickback applies on Minor/Tribe sale with no purchased tile',
    filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
    purchasedTileIndex: idx(const []),
    embassyGpRelationsFor: frrEmbassyForM1(const {'gpC': 50}),
    expect: const FrrCreditsExpectation(
      treasuryCreditEmpty: true,
      embassyKickbackCloseTo: {'gpC': 10.0},
    ),
    refs: '#3753',
  ),
  frrCreditsRow(
    label:
        'R8.7 — buyer == tile owner: no tile-owner share, other embassy GPs '
        'still get kickbacks',
    filledDeals: [dealOn('k1', buyer: 'gpA', quantity: 10, pricePerUnit: 20.0)],
    constantRelation: 100,
    embassyGpRelationsFor: frrEmbassyForM1(const {'gpA': 100, 'gpC': 50}),
    expect: const FrrCreditsExpectation(
      treasuryCreditEmpty: true,
      noEmbassyKickbackFor: ['gpA'],
      embassyKickbackCloseTo: {'gpC': 10.0},
    ),
    refs: '#3753',
  ),
  frrCreditsRow(
    label: 'no embassy holders → no kickbacks (empty callback result)',
    constantRelation: 100,
    embassyGpRelationsFor: (_) => const {},
    expect: const FrrCreditsExpectation(
      embassyKickbackEmpty: true,
      totalEmbassyKickback: 0.0,
      treasuryCreditCloseTo: {'gpA': 200.0},
    ),
    refs: '#3753',
  ),
  frrCreditsRow(
    label: 'relation-0 embassy holder records no kickback',
    filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
    purchasedTileIndex: idx(const []),
    embassyGpRelationsFor: frrEmbassyForM1(const {'gpC': 0}),
    expect: const FrrCreditsExpectation(sameAsEmpty: true),
    refs: '#3753',
  ),
];

/// D5 credits AC2–AC5 rows (Refs #2992 D5, #3939 slice 57).
List<FrrCreditsScenario> frrIssueAcD5CreditsScenarios() => [
  frrCreditsRow(
    label: 'credits helper produces rate 0.75 + treasury 150.0 for gpA',
    filledDeals: [frrD5OtherBuyDeal()],
    purchasedTileIndex: frrD5IdxK1GpA(),
    relationScoreFor: frrRelationTable(const {
      kFrrIssueAcD5GpA: {kFrrIssueAcD5MinorM1: 75},
    }),
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
  frrCreditsRow(
    label:
        'credits helper produces rate kFirstRightMaxProfitRate (1.0) and '
        'treasury == quantity * pricePerUnit (full share)',
    filledDeals: [frrD5OtherBuyDeal(quantity: 5, pricePerUnit: 8.0)],
    purchasedTileIndex: frrD5IdxK1GpA(),
    constantRelation: 100,
    expect: FrrCreditsExpectation(
      creditedDealsLength: 1,
      singleCreditedDealProfitRateCloseTo: kFirstRightMaxProfitRate,
      treasuryCreditCloseTo: {kFrrIssueAcD5GpA: 40.0},
      totalProfitTreasury: 40.0,
    ),
    refs: '#2992 D5 AC3',
  ),
  frrCreditsRow(
    label:
        'credits helper records audit row but transfers 0 treasury (Deal '
        'Book can still surface the no-credit case)',
    filledDeals: [frrD5OtherBuyDeal()],
    purchasedTileIndex: frrD5IdxK1GpA(),
    constantRelation: 0,
    expect: const FrrCreditsExpectation(
      creditedDealsLength: 1,
      singleCreditedDealProfitIsZero: true,
      treasuryCreditByGpId: {kFrrIssueAcD5GpA: 0.0},
      totalProfitTreasury: 0.0,
    ),
    refs: '#2992 D5 AC4',
  ),
  frrCreditsRow(
    label:
        'negative — buyer == owning GP (D2 FRR-match path) excluded from '
        'D4 aggregation: no double-credit when gpA wins the offer itself',
    filledDeals: [frrD5FrrMatchDeal()],
    purchasedTileIndex: frrD5IdxK1GpA(),
    constantRelation: 100,
    expect: const FrrCreditsExpectation(
      creditedDealsEmpty: true,
      treasuryCreditEmpty: true,
      totalProfitTreasury: 0.0,
    ),
    refs: '#2992 D5 AC4',
  ),
  frrCreditsRow(
    label:
        'k1 (gpA, relation 100) + k2 (gpB, relation 50) → gpA 60.0, gpB '
        '20.0; neither GP is credited for the other GP\'s purchased tile',
    filledDeals: [
      frrD5OtherBuyDeal(
        buyer: kFrrIssueAcD5GpC,
        quantity: 6,
        pricePerUnit: 10.0,
        sellerOriginTileKey: kFrrIssueAcD5TileK1,
      ),
      frrD5OtherBuyDeal(
        buyer: kFrrIssueAcD5GpC,
        quantity: 4,
        pricePerUnit: 10.0,
        sellerOriginTileKey: kFrrIssueAcD5TileK2,
      ),
    ],
    purchasedTileIndex: idx([
      frrD5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
      frrD5Attr(kFrrIssueAcD5TileK2, kFrrIssueAcD5GpB, kFrrIssueAcD5MinorM1),
    ]),
    relationScoreFor: frrRelationTable(const {
      kFrrIssueAcD5GpA: {kFrrIssueAcD5MinorM1: 100},
      kFrrIssueAcD5GpB: {kFrrIssueAcD5MinorM1: 50},
    }),
    expect: const FrrCreditsExpectation(
      treasuryCreditKeysContainAll: [kFrrIssueAcD5GpA, kFrrIssueAcD5GpB],
      treasuryCreditCloseTo: {kFrrIssueAcD5GpA: 60.0, kFrrIssueAcD5GpB: 20.0},
      totalProfitTreasury: 80.0,
    ),
    refs: '#2992 D5 AC5',
  ),
  frrCreditsRow(
    label:
        'same owning GP across two minors aggregates per source relation '
        'independently (k1@M1 relation 100 + k3@M2 relation 25 → gpA 45.0)',
    filledDeals: [
      frrD5OtherBuyDeal(
        buyer: kFrrIssueAcD5GpC,
        quantity: 5,
        pricePerUnit: 8.0,
        sellerOriginTileKey: kFrrIssueAcD5TileK1,
      ),
      frrD5OtherBuyDeal(
        seller: kFrrIssueAcD5MinorM2,
        buyer: kFrrIssueAcD5GpC,
        quantity: 2,
        pricePerUnit: 10.0,
        sellerOriginTileKey: kFrrIssueAcD5TileK3,
      ),
    ],
    purchasedTileIndex: idx([
      frrD5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
      frrD5Attr(
        kFrrIssueAcD5TileK3,
        kFrrIssueAcD5GpA,
        kFrrIssueAcD5MinorM2,
        kFrrIssueAcD5ProvinceM2,
      ),
    ]),
    relationScoreFor: frrRelationTable(const {
      kFrrIssueAcD5GpA: {kFrrIssueAcD5MinorM1: 100, kFrrIssueAcD5MinorM2: 25},
    }),
    expect: const FrrCreditsExpectation(
      creditedDealsLength: 2,
      treasuryCreditKeysExact: [kFrrIssueAcD5GpA],
      treasuryCreditCloseTo: {kFrrIssueAcD5GpA: 45.0},
      totalProfitTreasury: 45.0,
    ),
    refs: '#2992 D5 AC5',
  ),
];
