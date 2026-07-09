// Compact OrderEngine validateTrade assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'order_engine_validate_trade_expectation_shorthand.dart';

/// Pins for [orderEngineValidateTradeScenarios] rows.
enum OrderEngineValidateTradeTarget {
  acceptsAValidOfferWhenStockpileCoversQuantity,
  rejectsMutualExclusionWhenBidAndOfferShareACommodity,
  rejectsOfferExceedingAvailableStockpile,
  acceptsFirstBidWhenPlayerHasNoEmbassy,
  rejectsSecondDistinctCommodityBidWhenNoEmbassy,
}

void runOrderEngineValidateTradeExpectation(
  OrderEngineValidateTradeTarget target,
) {
  switch (target) {
    case OrderEngineValidateTradeTarget
        .acceptsAValidOfferWhenStockpileCoversQuantity:
        final game = vetGameWith(
          player: vetGp1(
            stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 10}),
          ),
        );
        final engine = vetTradeEngine()
          ..addTradeOrderWithContext(
            game,
            vetTopology,
            'gp1',
            validatorOffer(CommodityCatalog.timber.id, 5),
          );
        final results = vetValidate(game, engine);
        expect(results, hasLength(1));
        vetExpectAccepted(results.single);
    case OrderEngineValidateTradeTarget
        .rejectsMutualExclusionWhenBidAndOfferShareACommodity:
        final game = vetGameWith(
          player: vetGp1(
            stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 20}),
          ),
          overtures: vetEmbassyOverture,
        );
        final engine = vetTradeEngine()
          ..addTradeOrderWithContext(
            game,
            vetTopology,
            'gp1',
            validatorOffer(CommodityCatalog.timber.id, 5),
          )
          ..addTradeOrderWithContext(
            game,
            vetTopology,
            'gp1',
            validatorBid(CommodityCatalog.timber.id, 3),
          );
        vetExpectAllRejected(
          vetValidate(game, engine),
          reasons: {TradeOrderRejectionReasons.mutualExclusion},
        );
    case OrderEngineValidateTradeTarget.rejectsOfferExceedingAvailableStockpile:
        final game = vetGameWith(
          player: vetGp1(
            stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 3}),
          ),
        );
        vetExpectRejected(
          vetAddTrade(
            game,
            vetTradeEngine(),
            validatorOffer(CommodityCatalog.timber.id, 10),
          ),
          reason: TradeOrderRejectionReasons.offerExceedsStockpile,
        );
    case OrderEngineValidateTradeTarget.acceptsFirstBidWhenPlayerHasNoEmbassy:
        final game = vetGameWith(
          player: vetGp1(treasury: 500),
        );
        vetExpectAccepted(
          vetAddTrade(
            game,
            vetTradeEngine(),
            validatorBid(CommodityCatalog.timber.id, 1),
          ),
          reason:
              'Baseline kWorldMarketBaselineBidTypeCap == 1 admits exactly '
              'one bid even for a no-embassy GP.',
        );
    case OrderEngineValidateTradeTarget
        .rejectsSecondDistinctCommodityBidWhenNoEmbassy:
        final game = vetGameWith(
          player: vetGp1(treasury: 500),
        );
        final engine = vetTradeEngine()
          ..addTradeOrderWithContext(
            game,
            vetTopology,
            'gp1',
            validatorBid(CommodityCatalog.timber.id, 1),
          );
        vetExpectRejected(
          vetAddTrade(game, engine, validatorBid(CommodityCatalog.iron.id, 1)),
          reason: TradeOrderRejectionReasons.bidTypeCapExceeded,
        );
  }
}
