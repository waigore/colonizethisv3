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
    runLabeledScenarios(tradeOrderValidatorEmptyAcceptScenarios(), (scenario) {
      runTradeOrderValidatorScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderValidator.validate — rule 1: invalid quantity', () {
    runLabeledScenarios(tradeOrderValidatorRule1Scenarios(), (scenario) {
      runTradeOrderValidatorScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderValidator.validate — rule 2: riches not tradeable', () {
    runLabeledScenarios(tradeOrderValidatorRule2Scenarios(), (scenario) {
      runTradeOrderValidatorScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderValidator.validate — rule 3: mutual exclusion', () {
    runLabeledScenarios(tradeOrderValidatorRule3Scenarios(), (scenario) {
      runTradeOrderValidatorScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderValidator.validate — rule 4: bid type cap', () {
    runLabeledScenarios(tradeOrderValidatorCapScenarios().take(5), (scenario) {
      runTradeOrderValidatorScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderValidator.validate — rule 6: bid cargo cap', () {
    runLabeledScenarios(tradeOrderValidatorCapScenarios().skip(5).take(3), (
      scenario,
    ) {
      runTradeOrderValidatorScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderValidator.validate — rule 7: offer stockpile', () {
    runLabeledScenarios(tradeOrderValidatorCapScenarios().skip(8).take(3), (
      scenario,
    ) {
      runTradeOrderValidatorScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderValidator.validate — rule precedence', () {
    runLabeledScenarios(tradeOrderValidatorCapScenarios().skip(11), (scenario) {
      runTradeOrderValidatorScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderValidator.validate — rule 5: bid treasury cap', () {
    runLabeledScenarios(tradeOrderValidatorTreasuryScenarios(), (scenario) {
      runTradeOrderValidatorScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('tradeOrderValidationContextFromGame (Refs #3123)', () {
    runLabeledScenarios(tradeOrderValidatorContextTreasuryScenarios(), (
      scenario,
    ) {
      runTradeOrderValidatorContextScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderValidator.validate — rule 5 determinism (Refs #3123)', () {
    test('identical inputs produce identical result lists across two '
        'validate() calls (Refs #3123 AC: validator determinism)', () {
      final context = validatorCtx(
        treasuryBudgetForBids: 100,
        tradeCargoCapacity: 100,
        worldMarketState: WorldMarketState(
          prices: {
            CommodityCatalog.timber.id: 30,
            CommodityCatalog.iron.id: 10,
          },
        ),
      );
      final orders = [
        validatorBid(CommodityCatalog.timber.id, 4),
        validatorBid(CommodityCatalog.iron.id, 1),
      ];
      final first = TradeOrderValidator.validate(
        context: context,
        proposedOrders: orders,
      );
      final second = TradeOrderValidator.validate(
        context: context,
        proposedOrders: orders,
      );
      expect(second, hasLength(first.length));
      for (var i = 0; i < first.length; i++) {
        expect(second[i].isAccepted, first[i].isAccepted);
        expect(second[i].reason, first[i].reason);
      }
    });
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

    test('every non-riches commodity in the catalog resolves to a non-null '
        'effective price via the default ResourceRules (no hidden gaps that '
        "would force a rule-5 'unknown price' rejection in normal play)", () {
      final rules = ResourceRules.defaultRules;
      for (final commodity in CommodityCatalog.all) {
        if (richesCommodityIds.contains(commodity.id)) continue;
        final effective = effectiveMarketPriceForCommodityId(
          commodityId: commodity.id,
          worldMarket: const WorldMarketState(),
          resourceRules: rules,
        );
        expect(
          effective,
          isNotNull,
          reason:
              'commodity ${commodity.id} (non-riches) must resolve to a '
              'non-null catalog default so rule 5 can price it',
        );
        expect(
          effective! >= 0,
          isTrue,
          reason: 'catalog default for ${commodity.id} must be non-negative',
        );
      }
    });
  });
}
