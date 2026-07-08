// Table-driven First Right credits scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        FirstRightCreditsResult,
        PurchasedTileAttribution,
        PurchasedTileIndex,
        computeFirstRightCredits;
import 'package:colonizethis_models/colonizethis_models.dart' show FilledDeal;
import 'package:colonizethis_test/test.dart';

import 'frr_credits_expectations.dart';
import 'frr_credits_test_support.dart';

int _alwaysZero(String _, String __) => 0;

/// One row for `computeFirstRightCredits` scenario tables.
class FrrCreditsScenario {
  const FrrCreditsScenario({
    required this.label,
    required this.filledDeals,
    required this.purchasedTileIndex,
    required this.relationScoreFor,
    required this.verify,
    this.embassyGpRelationsFor,
    this.refs,
  });

  FrrCreditsScenario.expect({
    required String label,
    required List<FilledDeal> filledDeals,
    required PurchasedTileIndex? purchasedTileIndex,
    required num Function(String owningGpId, String sourceFactionId)
        relationScoreFor,
    required FrrCreditsExpectation expect,
    Map<String, num> Function(String sourceFactionId)? embassyGpRelationsFor,
    String? refs,
  }) : this(
          label: label,
          filledDeals: filledDeals,
          purchasedTileIndex: purchasedTileIndex,
          relationScoreFor: relationScoreFor,
          embassyGpRelationsFor: embassyGpRelationsFor,
          verify: (result) => assertFrrCreditsExpectation(result, expect),
          refs: refs,
        );

  final List<FilledDeal> filledDeals;
  final PurchasedTileIndex? purchasedTileIndex;
  final num Function(String owningGpId, String sourceFactionId) relationScoreFor;
  final Map<String, num> Function(String sourceFactionId)? embassyGpRelationsFor;
  final String label;
  final void Function(FirstRightCreditsResult result) verify;
  final String? refs;
}

void runFrrCreditsScenario(FrrCreditsScenario scenario) {
  final result = computeFirstRightCredits(
    filledDeals: scenario.filledDeals,
    purchasedTileIndex: scenario.purchasedTileIndex,
    relationScoreFor: scenario.relationScoreFor,
    embassyGpRelationsFor: scenario.embassyGpRelationsFor,
  );
  scenario.verify(result);
}

/// Defensive / skip branches from `first_right_credits_test.dart`.
List<FrrCreditsScenario> frrCreditsDefensiveScenarios() => [
  FrrCreditsScenario.expect(
    label: 'empty input returns FirstRightCreditsResult.empty (no deals)',
    filledDeals: const <FilledDeal>[],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: _alwaysZero,
    expect: const FrrCreditsExpectation(
      empty: true,
      totalProfitTreasury: 0.0,
    ),
    refs: '#2992',
  ),
  FrrCreditsScenario.expect(
    label: 'empty purchased-tile index returns FirstRightCreditsResult.empty',
    filledDeals: [deal(buyer: 'gpB', sellerOriginTileKey: 'k1')],
    purchasedTileIndex: idx(const <PurchasedTileAttribution>[]),
    relationScoreFor: _alwaysZero,
    expect: const FrrCreditsExpectation.emptyResult(),
    refs: '#2992',
  ),
  FrrCreditsScenario.expect(
    label: 'null purchased-tile index returns FirstRightCreditsResult.empty',
    filledDeals: [deal(buyer: 'gpB', sellerOriginTileKey: 'k1')],
    purchasedTileIndex: null,
    relationScoreFor: _alwaysZero,
    expect: const FrrCreditsExpectation.emptyResult(),
    refs: '#2992',
  ),
  FrrCreditsScenario.expect(
    label: 'negative — deal with null sellerOriginTileKey is skipped',
    filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: (_, __) => 100,
    expect: const FrrCreditsExpectation.emptyResult(),
    refs: '#2992',
  ),
  FrrCreditsScenario.expect(
    label: 'negative — deal with unmapped tile key is skipped (no attribution)',
    filledDeals: [deal(buyer: 'gpB', sellerOriginTileKey: 'unmapped')],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: (_, __) => 100,
    expect: const FrrCreditsExpectation.emptyResult(),
    refs: '#2992',
  ),
  FrrCreditsScenario.expect(
    label: 'negative — zero quantity or zero price deals are skipped',
    filledDeals: [
      deal(
        buyer: 'gpB',
        quantity: 0,
        pricePerUnit: 20.0,
        sellerOriginTileKey: 'k1',
      ),
      deal(
        buyer: 'gpB',
        quantity: 10,
        pricePerUnit: 0.0,
        sellerOriginTileKey: 'k1',
      ),
    ],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: (_, __) => 100,
    expect: const FrrCreditsExpectation.emptyResult(),
    refs: '#2992',
  ),
];

/// Aggregation cases from `first_right_credits_aggregation_test.dart`.
List<FrrCreditsScenario> frrCreditsAggregationScenarios() => [
  FrrCreditsScenario.expect(
    label: 'multi-tile — two owning GPs aggregate credits independently',
    filledDeals: [
      deal(
        buyer: 'gpC',
        quantity: 10,
        pricePerUnit: 10.0,
        sellerOriginTileKey: 'k1',
      ),
      deal(
        buyer: 'gpC',
        quantity: 4,
        pricePerUnit: 5.0,
        sellerOriginTileKey: 'k2',
      ),
      deal(
        buyer: 'gpC',
        quantity: 2,
        pricePerUnit: 3.0,
        sellerOriginTileKey: 'k3',
      ),
    ],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
      attr(tileKey: 'k2', owningGpId: 'gpB', sourceFactionId: 'M1'),
      attr(tileKey: 'k3', owningGpId: 'gpA', sourceFactionId: 'M2'),
    ]),
    relationScoreFor: (gp, src) {
      if (gp == 'gpA' && src == 'M1') return 100;
      if (gp == 'gpB' && src == 'M1') return 50;
      if (gp == 'gpA' && src == 'M2') return 25;
      return 0;
    },
    expect: const FrrCreditsExpectation(
      treasuryCreditKeysContainAll: ['gpA', 'gpB'],
      treasuryCreditCloseTo: {'gpA': 101.5, 'gpB': 10.0},
      totalProfitTreasury: 111.5,
      creditedDealsLength: 3,
    ),
    refs: '#3753',
  ),
  FrrCreditsScenario.expect(
    label:
        'multi-GP precedence — buyer == owning GP for one tile, other-GP buyer for another',
    filledDeals: [
      deal(
        buyer: 'gpA',
        isFirstRightOfRefusalMatch: true,
        quantity: 4,
        pricePerUnit: 10.0,
        sellerOriginTileKey: 'k1',
      ),
      deal(
        buyer: 'gpB',
        quantity: 6,
        pricePerUnit: 10.0,
        sellerOriginTileKey: 'k1',
      ),
    ],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: (_, _) => 100,
    expect: const FrrCreditsExpectation(
      creditedDealsLength: 1,
      singleCreditedDealBuyer: 'gpB',
      treasuryCreditCloseTo: {'gpA': 60.0},
      totalProfitTreasury: 60.0,
    ),
    refs: '#3753',
  ),
  FrrCreditsScenario(
    label:
        'deterministic — identical inputs return identical credit/aggregation order',
    filledDeals: [
      deal(
        buyer: 'gpC',
        quantity: 1,
        pricePerUnit: 5.0,
        sellerOriginTileKey: 'k2',
      ),
      deal(
        buyer: 'gpC',
        quantity: 2,
        pricePerUnit: 5.0,
        sellerOriginTileKey: 'k1',
      ),
      deal(
        buyer: 'gpC',
        quantity: 3,
        pricePerUnit: 5.0,
        sellerOriginTileKey: 'k2',
      ),
    ],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
      attr(tileKey: 'k2', owningGpId: 'gpB', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: (_, _) => 100,
    verify: (result) {
      FirstRightCreditsResult run() => computeFirstRightCredits(
        filledDeals: [
          deal(
            buyer: 'gpC',
            quantity: 1,
            pricePerUnit: 5.0,
            sellerOriginTileKey: 'k2',
          ),
          deal(
            buyer: 'gpC',
            quantity: 2,
            pricePerUnit: 5.0,
            sellerOriginTileKey: 'k1',
          ),
          deal(
            buyer: 'gpC',
            quantity: 3,
            pricePerUnit: 5.0,
            sellerOriginTileKey: 'k2',
          ),
        ],
        purchasedTileIndex: idx([
          attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
          attr(tileKey: 'k2', owningGpId: 'gpB', sourceFactionId: 'M1'),
        ]),
        relationScoreFor: (_, _) => 100,
      );
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
        'gpB',
        reason: 'insertion order tracks first deal mentioning each owning GP',
      );
    },
    refs: '#3753',
  ),
];

/// Embassy kickback cases from `first_right_credits_kickback_test.dart`.
List<FrrCreditsScenario> frrCreditsKickbackScenarios() => [
  FrrCreditsScenario.expect(
    label:
        'non-owner embassy GP receives 10% kickback while tile owner gets full '
        'share and no kickback',
    filledDeals: [
      deal(
        buyer: 'gpB',
        quantity: 10,
        pricePerUnit: 20.0,
        sellerOriginTileKey: 'k1',
      ),
    ],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: (gp, src) => gp == 'gpA' && src == 'M1' ? 100 : 0,
    embassyGpRelationsFor: (src) =>
        src == 'M1' ? const {'gpA': 100, 'gpC': 50} : const {},
    expect: const FrrCreditsExpectation(
      treasuryCreditCloseTo: {'gpA': 200.0},
      noEmbassyKickbackFor: ['gpA'],
      embassyKickbackCloseTo: {'gpC': 10.0},
      totalEmbassyKickback: 10.0,
    ),
    refs: '#3753',
  ),
  FrrCreditsScenario.expect(
    label: 'R8.6 — kickback applies on Minor/Tribe sale with no purchased tile',
    filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
    purchasedTileIndex: idx(const []),
    relationScoreFor: (_, _) => 0,
    embassyGpRelationsFor: (src) =>
        src == 'M1' ? const {'gpC': 50} : const {},
    expect: const FrrCreditsExpectation(
      treasuryCreditEmpty: true,
      embassyKickbackCloseTo: {'gpC': 10.0},
    ),
    refs: '#3753',
  ),
  FrrCreditsScenario.expect(
    label:
        'R8.7 — buyer == tile owner: no tile-owner share, other embassy GPs '
        'still get kickbacks',
    filledDeals: [
      deal(
        buyer: 'gpA',
        quantity: 10,
        pricePerUnit: 20.0,
        sellerOriginTileKey: 'k1',
      ),
    ],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: (_, _) => 100,
    embassyGpRelationsFor: (src) =>
        src == 'M1' ? const {'gpA': 100, 'gpC': 50} : const {},
    expect: const FrrCreditsExpectation(
      treasuryCreditEmpty: true,
      noEmbassyKickbackFor: ['gpA'],
      embassyKickbackCloseTo: {'gpC': 10.0},
    ),
    refs: '#3753',
  ),
  FrrCreditsScenario.expect(
    label: 'no embassy holders → no kickbacks (empty callback result)',
    filledDeals: [
      deal(
        buyer: 'gpB',
        quantity: 10,
        pricePerUnit: 20.0,
        sellerOriginTileKey: 'k1',
      ),
    ],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: (_, _) => 100,
    embassyGpRelationsFor: (_) => const {},
    expect: const FrrCreditsExpectation(
      embassyKickbackEmpty: true,
      totalEmbassyKickback: 0.0,
      treasuryCreditCloseTo: {'gpA': 200.0},
    ),
    refs: '#3753',
  ),
  FrrCreditsScenario.expect(
    label: 'relation-0 embassy holder records no kickback',
    filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
    purchasedTileIndex: idx(const []),
    relationScoreFor: (_, _) => 0,
    embassyGpRelationsFor: (src) =>
        src == 'M1' ? const {'gpC': 0} : const {},
    expect: const FrrCreditsExpectation(sameAsEmpty: true),
    refs: '#3753',
  ),
];
