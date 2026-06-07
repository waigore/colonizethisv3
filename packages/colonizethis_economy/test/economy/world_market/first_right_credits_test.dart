import 'package:colonizethis_economy/src/economy/world_market/first_right_credits.dart';
import 'package:colonizethis_economy/src/economy/world_market/first_right_profit.dart';
import 'package:colonizethis_economy/src/economy/world_market/purchased_tile_index.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Builds a [PurchasedTileIndex] for D4 helper tests via the
/// `forTesting` constructor so each test can declare exactly the
/// attribution rows it cares about without spinning up a full [Game].
PurchasedTileIndex _idx(Iterable<PurchasedTileAttribution> rows) =>
    PurchasedTileIndex.forTesting(rows);

PurchasedTileAttribution _attr({
  required String tileKey,
  required String owningGpId,
  required String sourceFactionId,
  String provinceId = 'oldWorld|p1',
}) => PurchasedTileAttribution(
  tileKey: tileKey,
  owningGpId: owningGpId,
  sourceFactionId: sourceFactionId,
  provinceId: provinceId,
);

FilledDeal _deal({
  String seller = 'M1',
  required String buyer,
  CommodityId commodityId = 'timber',
  int quantity = 10,
  double pricePerUnit = 20.0,
  bool isFtpMatch = false,
  bool isFirstRightOfRefusalMatch = false,
  String? sellerOriginTileKey,
}) => FilledDeal(
  sellerFactionId: seller,
  buyerFactionId: buyer,
  commodityId: commodityId,
  quantity: quantity,
  pricePerUnit: pricePerUnit,
  isFtpMatch: isFtpMatch,
  isFirstRightOfRefusalMatch: isFirstRightOfRefusalMatch,
  sellerOriginTileKey: sellerOriginTileKey,
);

int _alwaysZero(String _, String __) => 0;

void main() {
  group('computeFirstRightCredits (#2992 D4)', () {
    test('empty input returns FirstRightCreditsResult.empty (no deals)', () {
      final result = computeFirstRightCredits(
        filledDeals: const <FilledDeal>[],
        purchasedTileIndex: _idx([
          _attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
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
          filledDeals: [_deal(buyer: 'gpB', sellerOriginTileKey: 'k1')],
          purchasedTileIndex: _idx(const <PurchasedTileAttribution>[]),
          relationScoreFor: _alwaysZero,
        );
        expect(result.creditedDeals, isEmpty);
        expect(result.treasuryCreditByGpId, isEmpty);
      },
    );

    test('null purchased-tile index returns FirstRightCreditsResult.empty', () {
      final result = computeFirstRightCredits(
        filledDeals: [_deal(buyer: 'gpB', sellerOriginTileKey: 'k1')],
        purchasedTileIndex: null,
        relationScoreFor: _alwaysZero,
      );
      expect(result.creditedDeals, isEmpty);
      expect(result.treasuryCreditByGpId, isEmpty);
    });

    test('positive — owning GP credited for other-GP buy at relation 75', () {
      final result = computeFirstRightCredits(
        filledDeals: [
          _deal(
            buyer: 'gpB',
            quantity: 10,
            pricePerUnit: 20.0,
            sellerOriginTileKey: 'k1',
          ),
        ],
        purchasedTileIndex: _idx([
          _attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
        ]),
        relationScoreFor: (gp, src) => gp == 'gpA' && src == 'M1' ? 75 : 0,
      );
      expect(result.creditedDeals, hasLength(1));
      final credit = result.creditedDeals.single;
      expect(credit.owningGpId, 'gpA');
      expect(credit.sourceFactionId, 'M1');
      expect(credit.relationScore, 75);
      expect(credit.profit.profitRate, closeTo(0.30, 1e-12));
      // 10 * 20 * 0.30 = 60
      expect(credit.profit.profitTreasury, closeTo(60.0, 1e-12));
      expect(result.treasuryCreditByGpId, {'gpA': closeTo(60.0, 1e-12)});
      expect(result.totalProfitTreasury, closeTo(60.0, 1e-12));
    });

    test(
      'upper bound — relation 100 credits 40% of sale value to owning GP',
      () {
        final result = computeFirstRightCredits(
          filledDeals: [
            _deal(
              buyer: 'gpB',
              quantity: 5,
              pricePerUnit: 8.0,
              sellerOriginTileKey: 'k1',
            ),
          ],
          purchasedTileIndex: _idx([
            _attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
          ]),
          relationScoreFor: (gp, src) => 100,
        );
        // 5 * 8 * 0.40 = 16.0
        expect(result.totalProfitTreasury, closeTo(16.0, 1e-12));
        expect(
          result.creditedDeals.single.profit.profitRate,
          kFirstRightMaxProfitRate,
        );
      },
    );

    test('negative — buyer == owning GP (D2 FRR-match path) is excluded', () {
      final result = computeFirstRightCredits(
        filledDeals: [
          _deal(
            buyer: 'gpA',
            isFirstRightOfRefusalMatch: true,
            quantity: 10,
            pricePerUnit: 20.0,
            sellerOriginTileKey: 'k1',
          ),
        ],
        purchasedTileIndex: _idx([
          _attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
        ]),
        relationScoreFor: (_, __) => 100,
      );
      expect(
        result.creditedDeals,
        isEmpty,
        reason:
            'D4 only fires when the owning GP is not the buyer; FRR '
            'pre-pass matches are handled by D2 and never re-credited.',
      );
      expect(result.treasuryCreditByGpId, isEmpty);
    });

    test('negative — relation 0 yields a zero-treasury credit record only', () {
      final result = computeFirstRightCredits(
        filledDeals: [
          _deal(
            buyer: 'gpB',
            quantity: 10,
            pricePerUnit: 20.0,
            sellerOriginTileKey: 'k1',
          ),
        ],
        purchasedTileIndex: _idx([
          _attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
        ]),
        relationScoreFor: (_, __) => 0,
      );
      expect(result.creditedDeals, hasLength(1));
      expect(result.creditedDeals.single.profit, FirstRightProfit.zero);
      // owning GP appears in the map with 0.0 so phase handler / Deal
      // Book can still see the audit row, but no treasury moves.
      expect(result.treasuryCreditByGpId, {'gpA': 0.0});
      expect(result.totalProfitTreasury, 0.0);
    });

    test('negative — deal with null sellerOriginTileKey is skipped', () {
      final result = computeFirstRightCredits(
        filledDeals: [_deal(buyer: 'gpB', quantity: 10, pricePerUnit: 20.0)],
        purchasedTileIndex: _idx([
          _attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
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
          filledDeals: [_deal(buyer: 'gpB', sellerOriginTileKey: 'unmapped')],
          purchasedTileIndex: _idx([
            _attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
          ]),
          relationScoreFor: (_, __) => 100,
        );
        expect(result.creditedDeals, isEmpty);
        expect(result.treasuryCreditByGpId, isEmpty);
      },
    );

    test('negative — zero quantity or zero price deals are skipped', () {
      final attr = _attr(
        tileKey: 'k1',
        owningGpId: 'gpA',
        sourceFactionId: 'M1',
      );
      final zeroQty = _deal(
        buyer: 'gpB',
        quantity: 0,
        pricePerUnit: 20.0,
        sellerOriginTileKey: 'k1',
      );
      final zeroPrice = _deal(
        buyer: 'gpB',
        quantity: 10,
        pricePerUnit: 0.0,
        sellerOriginTileKey: 'k1',
      );
      final result = computeFirstRightCredits(
        filledDeals: [zeroQty, zeroPrice],
        purchasedTileIndex: _idx([attr]),
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
