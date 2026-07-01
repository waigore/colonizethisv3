import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Activity bookkeeping and [PurchasedTileIndex.forTesting] coverage for
/// #2992 D2 (split from [world_market_deal_matcher_first_right_test.dart] to
/// satisfy repo logic test file size limits).
void main() {
  late final PurchasedTileIndex frrIndex;
  const frrTileKey = 'oldWorld|M1|0|0';

  setUpAll(() {
    frrIndex = frrMatcherTestIndex();
  });

  group('DealMatcher.matchDeals — FRR activity bookkeeping (#2992 D2)', () {
    test(
      'FRR fills count toward filledQuantity in the per-commodity activity',
      () {
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'M1': [matcherOffer('timber', 10, originTileKey: frrTileKey)],
            },
            bidsByFactionId: {
              'gpA': [matcherBid('timber', 6, priority: 5)],
              'gpB': [matcherBid('timber', 6, priority: 1)],
            },
            tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
            purchasedTileIndex: frrIndex,
          ),
        );

        // 6 fill via FRR, 4 fill via tier matching → 10 total filled.
        expect(
          result.activityByCommodityId['timber'],
          const MarketActivity(
            totalBidQuantity: 12,
            totalOfferQuantity: 10,
            filledQuantity: 10,
          ),
        );
      },
    );
  });

  // The `forTesting` build path and empty-index case are exercised pervasively
  // by the matcher/credits/d5 suites (and the `fromGame` empty case is pinned
  // in `economy/world_market/purchased_tile_index_test.dart`). Only the
  // first-wins-on-duplicate-tileKey dedup contract is unique to `forTesting`,
  // so a single minimal pin remains here.
  group('PurchasedTileIndex.forTesting (#2992 D2 test helper)', () {
    test('first attribution per tileKey wins on duplicates', () {
      const first = PurchasedTileAttribution(
        tileKey: 'oldWorld|M1|0|0',
        owningGpId: 'gpA',
        sourceFactionId: 'M1',
        provinceId: 'oldWorld|M1',
      );
      const second = PurchasedTileAttribution(
        tileKey: 'oldWorld|M1|0|0',
        owningGpId: 'gpB',
        sourceFactionId: 'M1',
        provinceId: 'oldWorld|M1',
      );
      final index = PurchasedTileIndex.forTesting([first, second]);
      expect(index.length, 1);
      expect(index.attributionForTileKey('oldWorld|M1|0|0'), first);
    });

    test('empty input yields empty index', () {
      final index = PurchasedTileIndex.forTesting(const []);
      expect(index.length, 0);
      expect(index.isEmpty, isTrue);
    });
  });
}
