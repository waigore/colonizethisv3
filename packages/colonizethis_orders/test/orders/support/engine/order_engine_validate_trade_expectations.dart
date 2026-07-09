// Compact OrderEngine validateTrade assertions (Refs #3949 wave 3).

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
      vetExpectValidOfferAccepted();
    case OrderEngineValidateTradeTarget
        .rejectsMutualExclusionWhenBidAndOfferShareACommodity:
      vetExpectMutualExclusionRejected();
    case OrderEngineValidateTradeTarget.rejectsOfferExceedingAvailableStockpile:
      vetExpectOfferExceedsStockpileRejected();
    case OrderEngineValidateTradeTarget.acceptsFirstBidWhenPlayerHasNoEmbassy:
      vetExpectFirstBidAcceptedNoEmbassy();
    case OrderEngineValidateTradeTarget
        .rejectsSecondDistinctCommodityBidWhenNoEmbassy:
      vetExpectSecondBidRejectedNoEmbassy();
  }
}
