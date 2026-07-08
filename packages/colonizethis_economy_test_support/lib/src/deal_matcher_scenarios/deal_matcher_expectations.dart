// Compact DealMatcher result assertions (Refs #3939 phase 3 slice 10+).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Per-deal field pins for data-driven [DealMatchExpectation] rows.
class FilledDealExpectation {
  const FilledDealExpectation({
    this.buyerFactionId,
    this.sellerFactionId,
    this.commodityId,
    this.quantity,
    this.pricePerUnit,
    this.isFtpMatch,
    this.isFirstRightOfRefusalMatch,
  });

  final String? buyerFactionId;
  final String? sellerFactionId;
  final String? commodityId;
  final int? quantity;
  final double? pricePerUnit;
  final bool? isFtpMatch;
  final bool? isFirstRightOfRefusalMatch;
}

void _assertFilledDealExpectation(
  FilledDeal deal,
  FilledDealExpectation expectation,
) {
  if (expectation.buyerFactionId != null) {
    expect(deal.buyerFactionId, expectation.buyerFactionId);
  }
  if (expectation.sellerFactionId != null) {
    expect(deal.sellerFactionId, expectation.sellerFactionId);
  }
  if (expectation.commodityId != null) {
    expect(deal.commodityId, expectation.commodityId);
  }
  if (expectation.quantity != null) {
    expect(deal.quantity, expectation.quantity);
  }
  if (expectation.pricePerUnit != null) {
    expect(deal.pricePerUnit, expectation.pricePerUnit);
  }
  if (expectation.isFtpMatch != null) {
    expect(deal.isFtpMatch, expectation.isFtpMatch);
  }
  if (expectation.isFirstRightOfRefusalMatch != null) {
    expect(deal.isFirstRightOfRefusalMatch, expectation.isFirstRightOfRefusalMatch);
  }
}

/// Data-driven expectations for [DealMatchResult] scenario rows.
class DealMatchExpectation {
  const DealMatchExpectation({
    this.filledDeals,
    this.filledDealsLength,
    this.filledDealsEmpty = false,
    this.filledDealExpectations,
    this.filledDealCommodityIds,
    this.frrFilledDeal,
    this.nonFrrFilledDeal,
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
  final List<FilledDealExpectation>? filledDealExpectations;
  final List<CommodityId>? filledDealCommodityIds;
  final FilledDealExpectation? frrFilledDeal;
  final FilledDealExpectation? nonFrrFilledDeal;
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
  if (expectation.filledDealExpectations != null) {
    expect(
      result.filledDeals,
      hasLength(expectation.filledDealExpectations!.length),
    );
    for (var i = 0; i < expectation.filledDealExpectations!.length; i++) {
      _assertFilledDealExpectation(
        result.filledDeals[i],
        expectation.filledDealExpectations![i],
      );
    }
  }
  if (expectation.filledDealCommodityIds != null) {
    expect(
      result.filledDeals.map((d) => d.commodityId).toList(),
      expectation.filledDealCommodityIds,
    );
  }
  if (expectation.frrFilledDeal != null) {
    final frrDeal = result.filledDeals.firstWhere(
      (d) => d.isFirstRightOfRefusalMatch,
    );
    _assertFilledDealExpectation(frrDeal, expectation.frrFilledDeal!);
  }
  if (expectation.nonFrrFilledDeal != null) {
    final regularDeal = result.filledDeals.firstWhere(
      (d) => !d.isFirstRightOfRefusalMatch,
    );
    _assertFilledDealExpectation(regularDeal, expectation.nonFrrFilledDeal!);
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
