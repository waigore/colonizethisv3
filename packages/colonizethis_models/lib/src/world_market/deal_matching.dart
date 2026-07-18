/// Deal matcher output types for the world market phase.
///
/// First-class library (Refs #4068 Slice C). SPEC/game/world-market.md.

import '../model_collection_equality.dart';
import '../stockpile.dart';
import 'filled_deal.dart';
import 'market_activity.dart';
import 'trade_order.dart';

/// Result envelope returned by the deal-matching engine for a turn.
class DealMatchResult {
  const DealMatchResult({
    this.filledDeals = const <FilledDeal>[],
    this.unfilledOffersByFactionId = const <String, List<TradeOrder>>{},
    this.unfilledBidsByFactionId = const <String, List<TradeOrder>>{},
    this.activityByCommodityId = const <CommodityId, MarketActivity>{},
  });

  final List<FilledDeal> filledDeals;
  final Map<String, List<TradeOrder>> unfilledOffersByFactionId;
  final Map<String, List<TradeOrder>> unfilledBidsByFactionId;
  final Map<CommodityId, MarketActivity> activityByCommodityId;

  static const empty = DealMatchResult();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DealMatchResult &&
          runtimeType == other.runtimeType &&
          modelListEquals(filledDeals, other.filledDeals) &&
          modelMapOfListEquals(
            unfilledOffersByFactionId,
            other.unfilledOffersByFactionId,
          ) &&
          modelMapOfListEquals(
            unfilledBidsByFactionId,
            other.unfilledBidsByFactionId,
          ) &&
          modelMapEquals(activityByCommodityId, other.activityByCommodityId);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(filledDeals),
    Object.hashAll(unfilledOffersByFactionId.keys),
    Object.hashAll(unfilledBidsByFactionId.keys),
    Object.hashAll(activityByCommodityId.keys),
  );
}
