// Table-driven unit tests for sellable / offer-cap helpers (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('offerCapByCommodityId (Refs #3093)', () {
    for (final scenario in offerCapByCommodityIdScenarios()) {
      test(scenario.label, () {
        final game = buildStockpilePlayerGame(stockpile: scenario.stockpile);
        final cap = offerCapByCommodityId(
          game: game,
          playerId: scenario.playerId,
        );
        scenario.verify(cap);
      });
    }
  });

  group('stagedOfferQuantitiesByCommodityId (Refs #3093)', () {
    for (final scenario in stagedOfferQuantitiesByCommodityIdScenarios()) {
      test(scenario.label, () {
        final staged = stagedOfferQuantitiesByCommodityId(
          orders: humanOrdersWith(scenario.orders),
          playerId: humanPlayerId,
        );
        scenario.verify(staged);
      });
    }
  });

  group('sellableHeadroomByCommodityId (Refs #3093)', () {
    for (final scenario in sellableHeadroomByCommodityIdScenarios()) {
      test(scenario.label, () {
        final sellable = runSellableHeadroomScenario(scenario);
        scenario.verify(sellable);
      });
    }
  });
}
