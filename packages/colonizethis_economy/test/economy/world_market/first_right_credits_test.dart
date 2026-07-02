
import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

int _alwaysZero(String _, String __) => 0;

void main() {
  group('computeFirstRightCredits (#2992 D4)', () {
    test('empty input returns FirstRightCreditsResult.empty (no deals)', () {
      final result = computeFirstRightCredits(
        filledDeals: const <FilledDeal>[],
        purchasedTileIndex: idx([
          attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
        ]),
        relationScoreFor: _alwaysZero,
      );
      expect(result.creditedDeals, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
      expect(result.totalProfitTreasury, 0.0);
    });

    test(
      'empty purchased-tile index returns FirstRightCreditsResult.empty',
      () {
        final result = computeFirstRightCredits(
          filledDeals: [deal(buyer: 'gpB', sellerOriginTileKey: 'k1')],
          purchasedTileIndex: idx(const <PurchasedTileAttribution>[]),
          relationScoreFor: _alwaysZero,
        );
        expect(result.creditedDeals, isEmpty);
        expect(result.treasuryCreditByGpId, isEmpty);
      },
    );

    test('null purchased-tile index returns FirstRightCreditsResult.empty', () {
      final result = computeFirstRightCredits(
        filledDeals: [deal(buyer: 'gpB', sellerOriginTileKey: 'k1')],
        purchasedTileIndex: null,
        relationScoreFor: _alwaysZero,
      );
      expect(result.creditedDeals, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
    });

    // Relation 75 / 100 / 0 credit-formula scenarios (rate + treasury), plus
    // the "buyer == owning GP (D2 match) is excluded from D4" case, are pinned
    // 1:1 by the issue-AC audit file
    // `first_right_of_refusal_issue_acceptance_criteria_d5_test.dart`
    // (groups AC #2, AC #3, AC #4) and are intentionally not duplicated here.
    // This slice file retains only the defensive/skip branches the d5 contract
    // does not exercise.

    test('negative — deal with null sellerOriginTileKey is skipped', () {
      final result = computeFirstRightCredits(
        filledDeals: [deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
        purchasedTileIndex: idx([
          attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
        ]),
        relationScoreFor: (_, __) => 100,
      );
      expect(result.creditedDeals, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
    });

    test(
      'negative — deal with unmapped tile key is skipped (no attribution)',
      () {
        final result = computeFirstRightCredits(
          filledDeals: [deal(buyer: 'gpB', sellerOriginTileKey: 'unmapped')],
          purchasedTileIndex: idx([
            attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
          ]),
          relationScoreFor: (_, __) => 100,
        );
        expect(result.creditedDeals, isEmpty);
        expect(result.treasuryCreditByGpId, isEmpty);
      },
    );

    test('negative — zero quantity or zero price deals are skipped', () {
      final tileAttr = attr(
        tileKey: 'k1',
        owningGpId: 'gpA',
        sourceFactionId: 'M1',
      );
      final zeroQty = deal(
        buyer: 'gpB',
        quantity: 0,
        pricePerUnit: 20.0,
        sellerOriginTileKey: 'k1',
      );
      final zeroPrice = deal(
        buyer: 'gpB',
        quantity: 10,
        pricePerUnit: 0.0,
        sellerOriginTileKey: 'k1',
      );
      final result = computeFirstRightCredits(
        filledDeals: [zeroQty, zeroPrice],
        purchasedTileIndex: idx([tileAttr]),
        relationScoreFor: (_, __) => 100,
      );
      expect(result.creditedDeals, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
    });

    // Multi-deal aggregation, multi-GP precedence, and determinism cases
    // live in `first_right_credits_aggregation_test.dart` to keep this
    // file under the `repo.logic_test_file_size` 400-line cap.
  });
}
