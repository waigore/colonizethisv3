import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Tests for `TradeOrderValidator` rules 4–6 (bid type cap, bid cargo cap,
/// offer stockpile) and cross-rule precedence per
/// `SPEC/program/world-market-resolution.md` § Trade order validation.
/// Empty / accept paths and rules 1–3 live in
/// `world_market_trade_order_validator_test.dart`.
/// Refs #2989 A5.
void main() {
  group('TradeOrderValidator.validate — rule 4: bid type cap', () {
    for (final scenario in tradeOrderValidatorCapScenarios().take(5)) {
      test(scenario.label, () => runTradeOrderValidatorScenario(scenario));
    }
  });

  group('TradeOrderValidator.validate — rule 6: bid cargo cap', () {
    for (final scenario in tradeOrderValidatorCapScenarios().skip(5).take(3)) {
      test(scenario.label, () => runTradeOrderValidatorScenario(scenario));
    }
  });

  group('TradeOrderValidator.validate — rule 7: offer stockpile', () {
    for (final scenario in tradeOrderValidatorCapScenarios().skip(8).take(3)) {
      test(scenario.label, () => runTradeOrderValidatorScenario(scenario));
    }
  });

  group('TradeOrderValidator.validate — rule precedence', () {
    for (final scenario in tradeOrderValidatorCapScenarios().skip(11)) {
      test(scenario.label, () => runTradeOrderValidatorScenario(scenario));
    }
  });
}
