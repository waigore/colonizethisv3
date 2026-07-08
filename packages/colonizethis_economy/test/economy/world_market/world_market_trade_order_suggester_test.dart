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

  group('TradeOrderSuggester.suggest — cumulative treasury cap (rule 5)', () {
    for (final scenario in tradeOrderSuggesterTreasuryCapScenarios()) {
      test(scenario.label, () {
        runTradeOrderSuggesterScenario(scenario);
      });
    }
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
    for (final scenario in commoditiesWithBidAndOfferScenarios()) {
      test(scenario.label, () {
        final excluded = commoditiesWithBidAndOffer(scenario.proposedOrders);
        expect(excluded, scenario.expected);
      });
    }
  });

  group('admittedBidCommodityIdsInSubmissionOrder (rule 4)', () {
    for (final scenario in admittedBidCommodityIdsScenarios()) {
      test(scenario.label, () {
        verifyAdmittedBidCommodityIdsScenario(scenario);
      });
    }
  });

  group('offerCapByCommodityId (Refs #3093)', () {
    for (final scenario in offerCapByCommodityIdScenarios()) {
      test(scenario.label, () {
        verifyOfferCapScenario(scenario);
      });
    }
  });

  group('stagedOfferQuantitiesByCommodityId (Refs #3093)', () {
    for (final scenario in stagedOfferQuantitiesByCommodityIdScenarios()) {
      test(scenario.label, () {
        verifyStagedOfferQuantitiesScenario(scenario);
      });
    }
  });

  group('sellableHeadroomByCommodityId (Refs #3093)', () {
    for (final scenario in sellableHeadroomByCommodityIdScenarios()) {
      test(scenario.label, () {
        verifySellableHeadroomScenario(scenario);
      });
    }
  });
}
