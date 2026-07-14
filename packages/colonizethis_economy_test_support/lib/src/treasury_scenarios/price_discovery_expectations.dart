// dart format off
// Compact PriceDiscovery market-activity assertions (Refs #3939 phase 3 slice 19).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
/// Data-driven expectations for [PriceDiscovery.computeMarketActivity] rows.
class PriceDiscoveryMarketActivityExpectation {
  const PriceDiscoveryMarketActivityExpectation({this.totalBidQuantity, this.totalOfferQuantity, this.filledQuantity, this.priceChangePercent, this.priceChangePercentCloseTo, this.equalsEmpty = false});
  final int? totalBidQuantity;
  final int? totalOfferQuantity;
  final int? filledQuantity;
  final double? priceChangePercent;
  final double? priceChangePercentCloseTo;
  final bool equalsEmpty;
}
void assertPriceDiscoveryMarketActivityExpectation(MarketActivity activity, PriceDiscoveryMarketActivityExpectation expectation) {
  if (expectation.totalBidQuantity != null) {
    expect(activity.totalBidQuantity, expectation.totalBidQuantity);
  }
  if (expectation.totalOfferQuantity != null) {
    expect(activity.totalOfferQuantity, expectation.totalOfferQuantity);
  }
  if (expectation.filledQuantity != null) {
    expect(activity.filledQuantity, expectation.filledQuantity);
  }
  if (expectation.priceChangePercent != null) {
    expect(activity.priceChangePercent, expectation.priceChangePercent);
  }
  if (expectation.priceChangePercentCloseTo != null) {
    expect(activity.priceChangePercent, closeTo(expectation.priceChangePercentCloseTo!, 1e-9));
  }
  if (expectation.equalsEmpty) {
    expect(activity, equals(MarketActivity.empty));
  }
}
// dart format on
