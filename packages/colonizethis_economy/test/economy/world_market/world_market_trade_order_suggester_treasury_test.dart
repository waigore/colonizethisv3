// Table-driven treasury-cap tests for TradeOrderSuggester.suggest (Refs #3856).
//
// Per `SPEC/program/world-market-resolution.md` § Trade order suggestion API
// and `SPEC/game/world-market.md` rule 7. Refs #3123.

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TradeOrderSuggester.suggest — cumulative treasury cap (rule 5)', () {
    for (final scenario in tradeOrderSuggesterTreasuryCapScenarios()) {
      test(scenario.label, () {
        runTradeOrderSuggesterScenario(scenario);
      });
    }
  });
}
