/// [WorldMarketState] equality and hash helpers extracted so the aggregate
/// stays under the models physical-line cap (Refs #4334 wave 3).
library;

import '../model_collection_equality.dart';
import 'world_market_state.dart';

bool worldMarketStateEquals(WorldMarketState state, Object other) =>
    identical(state, other) ||
    other is WorldMarketState &&
        state.runtimeType == other.runtimeType &&
        modelMapEquals(state.prices, other.prices) &&
        modelMapEquals(state.lastTurnActivity, other.lastTurnActivity) &&
        modelMapOfListEquals(
          state.carryForwardOffersByFactionId,
          other.carryForwardOffersByFactionId,
        ) &&
        modelMapOfListEquals(
          state.carryForwardBidsByFactionId,
          other.carryForwardBidsByFactionId,
        ) &&
        modelSetEquals(state.completedTradePairKeys, other.completedTradePairKeys) &&
        modelMapOfListEquals(
          state.lastTurnOverseasProfitCreditsByGpId,
          other.lastTurnOverseasProfitCreditsByGpId,
        );

int worldMarketStateHashCode(WorldMarketState state) {
  final priceEntries = state.prices.entries
      .map((e) => Object.hash(e.key, e.value))
      .toList(growable: false);
  final activityEntries = state.lastTurnActivity.entries
      .map((e) => Object.hash(e.key, e.value))
      .toList(growable: false);
  return Object.hash(
    Object.hashAll(priceEntries),
    Object.hashAll(activityEntries),
    Object.hashAll(state.carryForwardOffersByFactionId.keys),
    Object.hashAll(state.carryForwardBidsByFactionId.keys),
    Object.hashAll(state.completedTradePairKeys),
    Object.hashAll(state.lastTurnOverseasProfitCreditsByGpId.keys),
  );
}
