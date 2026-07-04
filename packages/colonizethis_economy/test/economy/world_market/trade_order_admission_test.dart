// Table-driven unit tests for world-market admission helpers (Refs #3856).
//
// SPEC anchors:
//   - SPEC/program/world-market-resolution.md § Trade order validation
//     (rules 2 / 3 / 4).
//   - SPEC/game/world-market.md § Tradeable commodities.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
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
}
