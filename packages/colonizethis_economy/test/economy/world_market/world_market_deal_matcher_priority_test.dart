import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('DealMatcher.matchDeals — priority and FTP precedence', () {
    for (final scenario in dealMatcherPriorityAndFtpScenarios()) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });

  group('DealMatcher.matchDeals — multi-commodity', () {
    for (final scenario in dealMatcherMultiCommodityScenarios()) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });

  group(
    'DealMatcher.matchDeals — lock-recovery seller priority (Refs #2924 F12)',
    () {
      for (final scenario in dealMatcherLockRecoveryScenarios()) {
        test(scenario.label, () => runDealMatcherScenario(scenario));
      }
    },
  );

  group('DealMatcher.matchDeals — activity bookkeeping', () {
    for (final scenario in dealMatcherActivityScenarios()) {
      test(scenario.label, () => runDealMatcherScenario(scenario));
    }
  });
}
