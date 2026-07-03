import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('DealMatcher.pairKey', () {
    test('returns canonical key regardless of argument order', () {
      expect(
        DealMatcher.pairKey('alpha', 'zeta'),
        DealMatcher.pairKey('zeta', 'alpha'),
      );
      expect(DealMatcher.pairKey('alpha', 'zeta'), 'alpha|zeta');
    });

    test('handles equal ids (degenerate self-pair) deterministically', () {
      expect(DealMatcher.pairKey('a', 'a'), 'a|a');
    });
  });

  group('DealMatcher.matchDeals — empty inputs', () {
    for (final scenario in dealMatcherEmptyAndBasicScenarios().take(3)) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });

  group('DealMatcher.matchDeals — basic fills', () {
    for (final scenario in dealMatcherEmptyAndBasicScenarios().skip(3)) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });

  group('DealMatcher.matchDeals — cargo enforcement', () {
    for (final scenario in dealMatcherCargoScenarios()) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });
}
