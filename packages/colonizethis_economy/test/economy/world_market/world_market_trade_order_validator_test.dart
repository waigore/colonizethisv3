import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Tests for `TradeOrderValidator` rules 1–3 (invalid quantity, riches not
/// tradeable, mutual exclusion) plus empty / accept paths per
/// `SPEC/program/world-market-resolution.md` § Trade order validation.
/// Cap-related rules (4–6) and precedence cases live in
/// `world_market_trade_order_validator_caps_test.dart`.
/// Refs #2989 A5, #3856 slice 8.
void main() {
  group('TradeOrderValidator.validate — empty / accept paths', () {
    for (final scenario in tradeOrderValidatorEmptyAcceptScenarios()) {
      test(scenario.label, () => runTradeOrderValidatorScenario(scenario));
    }
  });

  group('TradeOrderValidator.validate — rule 1: invalid quantity', () {
    for (final scenario in tradeOrderValidatorRule1Scenarios()) {
      test(scenario.label, () => runTradeOrderValidatorScenario(scenario));
    }
  });

  group('TradeOrderValidator.validate — rule 2: riches not tradeable', () {
    for (final scenario in tradeOrderValidatorRule2Scenarios()) {
      test(scenario.label, () => runTradeOrderValidatorScenario(scenario));
    }
  });

  group('TradeOrderValidator.validate — rule 3: mutual exclusion', () {
    for (final scenario in tradeOrderValidatorRule3Scenarios()) {
      test(scenario.label, () => runTradeOrderValidatorScenario(scenario));
    }
  });
}
