import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Activity bookkeeping and [PurchasedTileIndex.forTesting] coverage for
/// #2992 D2 (split from [world_market_deal_matcher_first_right_test.dart] to
/// satisfy repo logic test file size limits).
void main() {
  group('DealMatcher.matchDeals — FRR activity bookkeeping (#2992 D2)', () {
    for (final scenario in dealMatcherFrrActivityScenarios()) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });

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
