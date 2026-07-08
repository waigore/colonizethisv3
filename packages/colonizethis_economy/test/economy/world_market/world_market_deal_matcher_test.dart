import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Consolidated DealMatcher runners (Refs #3939 phase 3).
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

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — empty inputs',
    dealMatcherEmptyAndBasicScenarios().take(3),
    runDealMatcherScenario,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — basic fills',
    dealMatcherEmptyAndBasicScenarios().skip(3),
    runDealMatcherScenario,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — cargo enforcement',
    dealMatcherCargoScenarios(),
    runDealMatcherScenario,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — priority and FTP precedence',
    dealMatcherPriorityAndFtpScenarios(),
    runDealMatcherScenario,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — multi-commodity',
    dealMatcherMultiCommodityScenarios(),
    runDealMatcherScenario,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — lock-recovery seller priority (Refs #2924 F12)',
    dealMatcherLockRecoveryScenarios(),
    runDealMatcherScenario,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — activity bookkeeping',
    dealMatcherActivityScenarios(),
    runDealMatcherScenario,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — treasury clamp (Refs #3115)',
    dealMatcherTreasuryScenarios(),
    runDealMatcherScenario,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — #3753 R7.3 sell-priority relation',
    dealMatcherSellPriorityScenarios(),
    runDealMatcherScenario,
  );

  runLabeledScenarioGroup(
    'DealMatcher.matchDeals — #3753 R6 boycott exclusion',
    dealMatcherBoycottScenarios(),
    runDealMatcherScenario,
  );
}
