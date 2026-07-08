// Compact DealMatcher result assertions (Refs #3939 phase 3 slice 10).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Data-driven expectations for [DealMatchResult] scenario rows.
class DealMatchExpectation {
  const DealMatchExpectation({
    this.filledDeals,
    this.filledDealsLength,
    this.filledDealsEmpty = false,
    this.unfilledOffersByFactionId,
    this.unfilledBidsByFactionId,
    this.unfilledOffersEmpty = false,
    this.unfilledBidsEmpty = false,
    this.activityByCommodityId,
    this.singleFilledDeal,
    this.custom,
  });

  final List<FilledDeal>? filledDeals;
  final int? filledDealsLength;
  final bool filledDealsEmpty;
  final Map<String, List<TradeOrder>>? unfilledOffersByFactionId;
  final Map<String, List<TradeOrder>>? unfilledBidsByFactionId;
  final bool unfilledOffersEmpty;
  final bool unfilledBidsEmpty;
  final Map<CommodityId, MarketActivity>? activityByCommodityId;
  final void Function(FilledDeal deal)? singleFilledDeal;
  final void Function(DealMatchResult result)? custom;
}

void assertDealMatchExpectation(
  DealMatchResult result,
  DealMatchExpectation expectation,
) {
  if (expectation.filledDealsEmpty) {
    expect(result.filledDeals, isEmpty);
  }
  if (expectation.filledDealsLength != null) {
    expect(result.filledDeals, hasLength(expectation.filledDealsLength));
  }
  if (expectation.filledDeals != null) {
    expect(result.filledDeals, expectation.filledDeals);
  }
  if (expectation.unfilledOffersEmpty) {
    expect(result.unfilledOffersByFactionId, isEmpty);
  }
  if (expectation.unfilledBidsEmpty) {
    expect(result.unfilledBidsByFactionId, isEmpty);
  }
  if (expectation.unfilledOffersByFactionId != null) {
    expect(
      result.unfilledOffersByFactionId,
      expectation.unfilledOffersByFactionId,
    );
  }
  if (expectation.unfilledBidsByFactionId != null) {
    expect(
      result.unfilledBidsByFactionId,
      expectation.unfilledBidsByFactionId,
    );
  }
  if (expectation.activityByCommodityId != null) {
    for (final MapEntry(:key, :value)
        in expectation.activityByCommodityId!.entries) {
      expect(result.activityByCommodityId[key], value);
    }
  }
  if (expectation.singleFilledDeal != null) {
    expectation.singleFilledDeal!(result.filledDeals.single);
  }
  expectation.custom?.call(result);
}
