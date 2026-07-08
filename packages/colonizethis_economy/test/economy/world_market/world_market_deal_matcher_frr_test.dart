import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// SPEC: SPEC/game/world-market-first-right-of-refusal.md § Rules
/// (#2992 D2 — First Right of Refusal absolute-priority override in
/// `DealMatcher.matchDeals`). Consolidated FRR matcher runners (Refs #3939).
void main() {
  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — First Right of Refusal (#2992 D2)',
    dealMatcherFirstRightScenarios(),
    runDealMatcherScenario,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — FRR activity bookkeeping (#2992 D2)',
    dealMatcherFrrActivityScenarios(),
    runDealMatcherScenario,
  );

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
