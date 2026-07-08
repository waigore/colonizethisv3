// Compact TradeOrderSuggester result assertions (Refs #3939 phase 3 slice 14).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Pins for a single suggested offer or bid row.
typedef SuggesterOrderPin = ({
  String commodityId,
  int? quantity,
  TradeOrderType? type,
  int? priority,
  bool? isFtp,
});

/// Ordered bid quantity pins for multi-bid cargo/treasury scenarios.
typedef SuggesterBidQuantityPin = ({String commodityId, int quantity});

/// Data-driven expectations for [TradeOrderSuggesterScenario] rows.
class SuggesterExpectation {
  const SuggesterExpectation({
    this.isEmpty,
    this.offersEmpty,
    this.bidsEmpty,
    this.offersNotEmpty,
    this.bidsNotEmpty,
    this.offersLength,
    this.bidsLength,
    this.offerCommodityIds,
    this.bidCommodityIds,
    this.bidQuantities,
    this.singleOffer,
    this.singleBid,
    this.validatorAllAccepted,
    this.offerBidDisjoint,
    this.offersContain,
    this.bidsContainAll,
    this.custom,
  });

  final bool? isEmpty;
  final bool? offersEmpty;
  final bool? bidsEmpty;
  final bool? offersNotEmpty;
  final bool? bidsNotEmpty;
  final int? offersLength;
  final int? bidsLength;
  final List<String>? offerCommodityIds;
  final List<String>? bidCommodityIds;
  final List<SuggesterBidQuantityPin>? bidQuantities;
  final SuggesterOrderPin? singleOffer;
  final SuggesterOrderPin? singleBid;
  final bool? validatorAllAccepted;
  final bool? offerBidDisjoint;
  final Set<String>? offersContain;
  final Set<String>? bidsContainAll;
  final void Function(
    TradeSuggestionContext context,
    TradeSuggestionResult result,
  )?
  custom;
}

void assertSuggesterExpectation(
  TradeSuggestionContext context,
  TradeSuggestionResult result,
  SuggesterExpectation expectation,
) {
  if (expectation.isEmpty != null) {
    expect(result.isEmpty, expectation.isEmpty);
  }
  if (expectation.offersEmpty != null) {
    expect(result.offers, expectation.offersEmpty! ? isEmpty : isNotEmpty);
  }
  if (expectation.bidsEmpty != null) {
    expect(result.bids, expectation.bidsEmpty! ? isEmpty : isNotEmpty);
  }
  if (expectation.offersNotEmpty != null && expectation.offersNotEmpty!) {
    expect(result.offers, isNotEmpty);
  }
  if (expectation.bidsNotEmpty != null && expectation.bidsNotEmpty!) {
    expect(result.bids, isNotEmpty);
  }
  if (expectation.offersLength != null) {
    expect(result.offers, hasLength(expectation.offersLength!));
  }
  if (expectation.bidsLength != null) {
    expect(result.bids, hasLength(expectation.bidsLength!));
  }
  if (expectation.offerCommodityIds != null) {
    expect(result.offers.map((o) => o.commodityId).toList(),
        expectation.offerCommodityIds);
  }
  if (expectation.bidCommodityIds != null) {
    expect(
      result.bids.map((b) => b.commodityId).toList(),
      expectation.bidCommodityIds,
    );
  }
  if (expectation.bidQuantities != null) {
    expect(result.bids, hasLength(expectation.bidQuantities!.length));
    for (var i = 0; i < expectation.bidQuantities!.length; i++) {
      final pin = expectation.bidQuantities![i];
      expect(result.bids[i].commodityId, pin.commodityId);
      expect(result.bids[i].quantity, pin.quantity);
    }
  }
  if (expectation.singleOffer != null) {
    final pin = expectation.singleOffer!;
    final offer = result.offers.single;
    expect(offer.commodityId, pin.commodityId);
    if (pin.quantity != null) {
      expect(offer.quantity, pin.quantity);
    }
    if (pin.type != null) {
      expect(offer.type, pin.type);
    }
    if (pin.priority != null) {
      expect(offer.priority, pin.priority);
    }
    if (pin.isFtp != null) {
      expect(offer.isFtp, pin.isFtp);
    }
  }
  if (expectation.singleBid != null) {
    final pin = expectation.singleBid!;
    final bid = result.bids.single;
    expect(bid.commodityId, pin.commodityId);
    if (pin.quantity != null) {
      expect(bid.quantity, pin.quantity);
    }
    if (pin.type != null) {
      expect(bid.type, pin.type);
    }
    if (pin.priority != null) {
      expect(bid.priority, pin.priority);
    }
    if (pin.isFtp != null) {
      expect(bid.isFtp, pin.isFtp);
    }
  }
  if (expectation.validatorAllAccepted != null &&
      expectation.validatorAllAccepted!) {
    final all = <TradeOrder>[...result.offers, ...result.bids];
    final validatorResults = TradeOrderValidator.validate(
      context: TradeOrderValidationContext(
        playerId: context.playerId,
        bidTypeCap: context.bidTypeCap,
        tradeCargoCapacity: context.tradeCargoCapacity,
        availableStockpileByCommodityId:
            context.availableStockpileByCommodityId,
        treasuryBudgetForBids: context.treasuryBudgetForBids,
        worldMarketState: context.worldMarketState,
        resourceRules: context.resourceRules ?? ResourceRules.defaultRules,
      ),
      proposedOrders: all,
    );
    for (final r in validatorResults) {
      expect(r.isAccepted, isTrue, reason: r.reason);
    }
  }
  if (expectation.offerBidDisjoint != null && expectation.offerBidDisjoint!) {
    final offerIds = result.offers.map((o) => o.commodityId).toSet();
    final bidIds = result.bids.map((b) => b.commodityId).toSet();
    expect(offerIds.intersection(bidIds), isEmpty);
  }
  if (expectation.offersContain != null) {
    final offerIds = result.offers.map((o) => o.commodityId).toSet();
    expect(offerIds, containsAll(expectation.offersContain!));
  }
  if (expectation.bidsContainAll != null) {
    final bidIds = result.bids.map((b) => b.commodityId).toSet();
    expect(bidIds, containsAll(expectation.bidsContainAll!));
  }
  expectation.custom?.call(context, result);
}
