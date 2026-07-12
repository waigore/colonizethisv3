// Consolidated TradeOrderSuggester and admission runners (Refs #3939 phase 3 slice 2).
//
// SPEC/program/world-market-resolution.md § Trade order suggestion API
// and § Trade order validation.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TradeOrderSuggester.suggest — empty / defensive paths', () {
    runLabeledScenarios(tradeOrderSuggesterEmptyDefensiveScenarios(), (
      scenario,
    ) {
      runTradeOrderSuggesterScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderSuggester.suggest — surplus offer detection', () {
    runLabeledScenarios(tradeOrderSuggesterSurplusOfferScenarios(), (scenario) {
      runTradeOrderSuggesterScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderSuggester.suggest — deficit bid detection', () {
    runLabeledScenarios(tradeOrderSuggesterDeficitBidScenarios(), (scenario) {
      runTradeOrderSuggesterScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderSuggester.suggest — bid type cap (rule 4)', () {
    runLabeledScenarios(tradeOrderSuggesterBidTypeCapScenarios(), (scenario) {
      runTradeOrderSuggesterScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderSuggester.suggest — cumulative cargo cap (rule 5)', () {
    runLabeledScenarios(tradeOrderSuggesterCargoCapScenarios(), (scenario) {
      runTradeOrderSuggesterScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderSuggester — validator-clean by construction', () {
    runLabeledScenarios(tradeOrderSuggesterValidatorCleanScenarios(), (
      scenario,
    ) {
      runTradeOrderSuggesterScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('TradeOrderSuggester.suggest — cumulative treasury cap (rule 5)', () {
    runLabeledScenarios(tradeOrderSuggesterTreasuryCapScenarios(), (scenario) {
      runTradeOrderSuggesterScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('isWorldMarketTradeableCommodity (rule 2)', () {
    test('non-riches commodity is tradeable', () {
      expect(isWorldMarketTradeableCommodity('timber'), isTrue);
      expect(isWorldMarketTradeableCommodity('iron'), isTrue);
    });

    test('every riches commodity is not tradeable', () {
      for (final richesId in data.richesCommodityIds) {
        expect(
          isWorldMarketTradeableCommodity(richesId),
          isFalse,
          reason: '$richesId should be excluded from the world market',
        );
      }
    });
  });

  group('commoditiesWithBidAndOffer (rule 3)', () {
    runLabeledScenarios(commoditiesWithBidAndOfferScenarios(), (scenario) {
      final excluded = commoditiesWithBidAndOffer(scenario.proposedOrders);
      expect(excluded, scenario.expected);
    }, labelOf: (s) => s.label);
  });

  group('admittedBidCommodityIdsInSubmissionOrder (rule 4)', () {
    runLabeledScenarios(admittedBidCommodityIdsScenarios(), (scenario) {
      verifyAdmittedBidCommodityIdsScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('offerCapByCommodityId (Refs #3093)', () {
    runLabeledScenarios(offerCapByCommodityIdScenarios(), (scenario) {
      verifyOfferCapScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('stagedOfferQuantitiesByCommodityId (Refs #3093)', () {
    runLabeledScenarios(stagedOfferQuantitiesByCommodityIdScenarios(), (
      scenario,
    ) {
      verifyStagedOfferQuantitiesScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('sellableHeadroomByCommodityId (Refs #3093)', () {
    runLabeledScenarios(sellableHeadroomByCommodityIdScenarios(), (scenario) {
      verifySellableHeadroomScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
