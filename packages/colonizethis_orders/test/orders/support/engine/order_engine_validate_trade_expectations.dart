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
      _acceptsAValidOfferWhenStockpileCoversQuantity();
    case OrderEngineValidateTradeTarget
        .rejectsMutualExclusionWhenBidAndOfferShareACommodity:
      _rejectsMutualExclusionWhenBidAndOfferShareACommodity();
    case OrderEngineValidateTradeTarget.rejectsOfferExceedingAvailableStockpile:
      _rejectsOfferExceedingAvailableStockpile();
    case OrderEngineValidateTradeTarget.acceptsFirstBidWhenPlayerHasNoEmbassy:
      _acceptsFirstBidWhenPlayerHasNoEmbassy();
    case OrderEngineValidateTradeTarget
        .rejectsSecondDistinctCommodityBidWhenNoEmbassy:
      _rejectsSecondDistinctCommodityBidWhenNoEmbassy();
  }
}

void _acceptsAValidOfferWhenStockpileCoversQuantity() {
  vetExpectValidOfferAccepted();
}

void _rejectsMutualExclusionWhenBidAndOfferShareACommodity() {
  vetExpectMutualExclusionRejected();
}

void _rejectsOfferExceedingAvailableStockpile() {
  vetExpectOfferExceedsStockpileRejected();
}

void _acceptsFirstBidWhenPlayerHasNoEmbassy() {
  vetExpectFirstBidAcceptedNoEmbassy();
}

void _rejectsSecondDistinctCommodityBidWhenNoEmbassy() {
  vetExpectSecondBidRejectedNoEmbassy();
}
