// Table-driven First Right credits scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        FirstRightCreditsResult,
        PurchasedTileAttribution,
        PurchasedTileIndex,
        computeFirstRightCredits;
import 'package:colonizethis_models/colonizethis_models.dart' show FilledDeal;
import 'package:colonizethis_test/test.dart';

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
  FrrCreditsScenario(
    label: 'empty input returns FirstRightCreditsResult.empty (no deals)',
    filledDeals: const <FilledDeal>[],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: _alwaysZero,
    verify: (result) {
      expect(result.creditedDeals, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
      expect(result.totalProfitTreasury, 0.0);
    },
    refs: '#2992',
  ),
  FrrCreditsScenario(
    label: 'empty purchased-tile index returns FirstRightCreditsResult.empty',
    filledDeals: [deal(buyer: 'gpB', sellerOriginTileKey: 'k1')],
    purchasedTileIndex: idx(const <PurchasedTileAttribution>[]),
    relationScoreFor: _alwaysZero,
    verify: (result) {
      expect(result.creditedDeals, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
    },
    refs: '#2992',
  ),
  FrrCreditsScenario(
    label: 'null purchased-tile index returns FirstRightCreditsResult.empty',
    filledDeals: [deal(buyer: 'gpB', sellerOriginTileKey: 'k1')],
    purchasedTileIndex: null,
    relationScoreFor: _alwaysZero,
    verify: (result) {
      expect(result.creditedDeals, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
    },
    refs: '#2992',
  ),
  FrrCreditsScenario(
    label: 'negative — deal with null sellerOriginTileKey is skipped',
    filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: (_, __) => 100,
    verify: (result) {
      expect(result.creditedDeals, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
    },
    refs: '#2992',
  ),
  FrrCreditsScenario(
    label: 'negative — deal with unmapped tile key is skipped (no attribution)',
    filledDeals: [deal(buyer: 'gpB', sellerOriginTileKey: 'unmapped')],
    purchasedTileIndex: idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]),
    relationScoreFor: (_, __) => 100,
    verify: (result) {
      expect(result.creditedDeals, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
    },
    refs: '#2992',
  ),
  FrrCreditsScenario(
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
    verify: (result) {
      expect(result.creditedDeals, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
    },
    refs: '#2992',
  ),
];

/// Aggregation cases from `first_right_credits_aggregation_test.dart`.
List<FrrCreditsScenario> frrCreditsAggregationScenarios() => [
  FrrCreditsScenario(
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
    verify: (result) {
      expect(result.treasuryCreditByGpId.keys, containsAll(['gpA', 'gpB']));
      expect(result.treasuryCreditByGpId['gpA']!, closeTo(101.5, 1e-12));
      expect(result.treasuryCreditByGpId['gpB']!, closeTo(10.0, 1e-12));
      expect(result.totalProfitTreasury, closeTo(111.5, 1e-12));
      expect(result.creditedDeals, hasLength(3));
    },
    refs: '#3753',
  ),
  FrrCreditsScenario(
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
    verify: (result) {
      expect(result.creditedDeals, hasLength(1));
      expect(result.creditedDeals.single.deal.buyerFactionId, 'gpB');
      expect(result.treasuryCreditByGpId, {'gpA': closeTo(60.0, 1e-12)});
      expect(result.totalProfitTreasury, closeTo(60.0, 1e-12));
    },
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
  FrrCreditsScenario(
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
    verify: (result) {
      expect(result.treasuryCreditByGpId['gpA'], closeTo(200.0, 1e-12));
      expect(result.embassyKickbackByGpId.containsKey('gpA'), isFalse);
      expect(result.embassyKickbackByGpId['gpC'], closeTo(10.0, 1e-12));
      expect(result.totalEmbassyKickback, closeTo(10.0, 1e-12));
    },
    refs: '#3753',
  ),
  FrrCreditsScenario(
    label: 'R8.6 — kickback applies on Minor/Tribe sale with no purchased tile',
    filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
    purchasedTileIndex: idx(const []),
    relationScoreFor: (_, _) => 0,
    embassyGpRelationsFor: (src) =>
        src == 'M1' ? const {'gpC': 50} : const {},
    verify: (result) {
      expect(result.treasuryCreditByGpId, isEmpty);
      expect(result.embassyKickbackByGpId['gpC'], closeTo(10.0, 1e-12));
    },
    refs: '#3753',
  ),
  FrrCreditsScenario(
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
    verify: (result) {
      expect(result.treasuryCreditByGpId, isEmpty);
      expect(result.embassyKickbackByGpId.containsKey('gpA'), isFalse);
      expect(result.embassyKickbackByGpId['gpC'], closeTo(10.0, 1e-12));
    },
    refs: '#3753',
  ),
  FrrCreditsScenario(
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
    verify: (result) {
      expect(result.embassyKickbackByGpId, isEmpty);
      expect(result.totalEmbassyKickback, 0.0);
      expect(result.treasuryCreditByGpId['gpA'], closeTo(200.0, 1e-12));
    },
    refs: '#3753',
  ),
  FrrCreditsScenario(
    label: 'relation-0 embassy holder records no kickback',
    filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
    purchasedTileIndex: idx(const []),
    relationScoreFor: (_, _) => 0,
    embassyGpRelationsFor: (src) =>
        src == 'M1' ? const {'gpC': 0} : const {},
    verify: (result) {
      expect(result, same(FirstRightCreditsResult.empty));
    },
    refs: '#3753',
  ),
];
