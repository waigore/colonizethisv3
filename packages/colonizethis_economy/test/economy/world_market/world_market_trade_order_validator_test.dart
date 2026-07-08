import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Consolidated TradeOrderValidator runners (Refs #3939 phase 3 slice 2).
///
/// Tests for `TradeOrderValidator` rules 1–7 plus cross-rule precedence per
/// `SPEC/program/world-market-resolution.md` § Trade order validation.
/// Refs #2989 A5, #3093, #3123, #3856.
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

  group('TradeOrderValidator.validate — rule 5: bid treasury cap', () {
    for (final scenario in tradeOrderValidatorTreasuryScenarios()) {
      test(scenario.label, () => runTradeOrderValidatorScenario(scenario));
    }
  });

  group('tradeOrderValidationContextFromGame (Refs #3123)', () {
    for (final scenario in tradeOrderValidatorContextTreasuryScenarios()) {
      test(
        scenario.label,
        () => runTradeOrderValidatorContextScenario(scenario),
      );
    }
  });

  group('effectiveMarketPriceForCommodityId — catalog default coverage '
      '(Refs #3123)', () {
    test('a representative raw and manufactured commodity resolve to a '
        'non-null, non-negative effective price from the catalog default '
        'when no live market price exists', () {
      final rules = ResourceRules.defaultRules;
      for (final commodityId in <String>[
        CommodityCatalog.timber.id,
        CommodityCatalog.lumber.id,
      ]) {
        final effective = effectiveMarketPriceForCommodityId(
          commodityId: commodityId,
          worldMarket: const WorldMarketState(),
          resourceRules: rules,
        );
        expect(
          effective,
          isNotNull,
          reason:
              'commodity $commodityId must resolve to a non-null catalog '
              'default so rule 5 can price it',
        );
        expect(
          effective! >= 0,
          isTrue,
          reason: 'catalog default for $commodityId must be non-negative',
        );
      }
    });
  });
}
