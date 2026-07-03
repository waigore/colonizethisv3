// Table-driven unit tests for TradeOrderSuggester.suggest (Refs #3856).
//
// Treasury-cap (rule 5) cases live in
// `world_market_trade_order_suggester_treasury_test.dart` (Refs #3123).

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TradeOrderSuggester.suggest — empty / defensive paths', () {
    for (final scenario in tradeOrderSuggesterEmptyDefensiveScenarios()) {
      test(scenario.label, () {
        runTradeOrderSuggesterScenario(scenario);
      });
    }
  });

  group('TradeOrderSuggester.suggest — surplus offer detection', () {
    for (final scenario in tradeOrderSuggesterSurplusOfferScenarios()) {
      test(scenario.label, () {
        runTradeOrderSuggesterScenario(scenario);
      });
    }
  });

  group('TradeOrderSuggester.suggest — deficit bid detection', () {
    for (final scenario in tradeOrderSuggesterDeficitBidScenarios()) {
      test(scenario.label, () {
        runTradeOrderSuggesterScenario(scenario);
      });
    }
  });

  group('TradeOrderSuggester.suggest — bid type cap (rule 4)', () {
    for (final scenario in tradeOrderSuggesterBidTypeCapScenarios()) {
      test(scenario.label, () {
        runTradeOrderSuggesterScenario(scenario);
      });
    }
  });

  group('TradeOrderSuggester.suggest — cumulative cargo cap (rule 5)', () {
    for (final scenario in tradeOrderSuggesterCargoCapScenarios()) {
      test(scenario.label, () {
        runTradeOrderSuggesterScenario(scenario);
      });
    }
  });

  group('TradeOrderSuggester — validator-clean by construction', () {
    for (final scenario in tradeOrderSuggesterValidatorCleanScenarios()) {
      test(scenario.label, () {
        runTradeOrderSuggesterScenario(scenario);
      });
    }
  });
}
