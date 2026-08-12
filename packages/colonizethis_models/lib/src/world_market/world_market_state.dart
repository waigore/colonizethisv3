/// Persisted world-market aggregate state.
///
/// First-class library (Refs #4068 Slice C). SPEC/game/world-market.md.

import '../stockpile.dart';
import 'market_activity.dart';
import 'overseas_profit_credit_record.dart';
import 'trade_order.dart';
import 'world_market_state_equality.dart';
import 'world_market_state_serialization.dart';

/// Aggregate market state stored on `Game` between turns.
///
/// `prices` stores integer per-commodity market prices (post-floor of the
/// price-discovery output). SPEC/game/world-market.md § Price discovery
/// requires the persisted price be floored to the nearest integer; the
/// inner floating-point math in [PriceDiscovery.computeNextPrice] is
/// retained for the supply/demand delta but the world-market phase floors
/// the result before storing it here. Older save files that wrote `double`
/// prices remain loadable: [fromJson] floors any incoming numeric value to
/// the nearest integer so the in-memory map is always int-valued.
class WorldMarketState {
  const WorldMarketState({
    this.prices = const <CommodityId, int>{},
    this.lastTurnActivity = const <CommodityId, MarketActivity>{},
    this.carryForwardOffersByFactionId = const <String, List<TradeOrder>>{},
    this.carryForwardBidsByFactionId = const <String, List<TradeOrder>>{},
    this.completedTradePairKeys = const <String>{},
    this.lastTurnOverseasProfitCreditsByGpId =
        const <String, List<OverseasProfitCreditRecord>>{},
  });

  final Map<CommodityId, int> prices;
  final Map<CommodityId, MarketActivity> lastTurnActivity;

  /// Per-faction unfilled offer carry-forwards from the previous turn's
  /// market phase. Re-entered into matching at the start of the next turn,
  /// subject to stockpile/cargo re-validation per `SPEC/game/world-market.md`
  /// § Order persistence.
  final Map<String, List<TradeOrder>> carryForwardOffersByFactionId;

  /// Per-faction unfilled bid carry-forwards from the previous turn's
  /// market phase. Re-entered into matching at the start of the next turn,
  /// subject to stockpile/cargo re-validation per `SPEC/game/world-market.md`
  /// § Order persistence.
  final Map<String, List<TradeOrder>> carryForwardBidsByFactionId;

  /// Canonical `min|max` faction pair keys for every pair that completed at
  /// least one world-market trade deal involving at least one Great Power on
  /// the turn this state was persisted. Consumed by the next turn's Diplomacy
  /// phase to apply the additive trade-deal relation boost (Refs #3753 R10)
  /// before per-turn decay, so trading pairs skip decay (skip-on-event).
  /// SPEC/game/diplomacy.md § Relation Model — Trade-deal relation boost;
  /// SPEC/program/world-market-resolution.md § Step F.
  final Set<String> completedTradePairKeys;

  /// Per-GP overseas-profit credit rows from the last resolved world-market
  /// phase (tile-owner share + embassy kickback). Replaced each phase pass.
  /// Refs #4226.
  final Map<String, List<OverseasProfitCreditRecord>>
  lastTurnOverseasProfitCreditsByGpId;

  static const empty = WorldMarketState();

  /// Builds an initial state seeded from `defaultMarketPrice` integers
  /// (one entry per non-riches commodity). Activity map starts empty.
  static WorldMarketState withDefaultPrices(Map<CommodityId, int> basePrices) {
    return WorldMarketState(
      prices: Map<CommodityId, int>.unmodifiable(basePrices),
      lastTurnActivity: const <CommodityId, MarketActivity>{},
    );
  }

  WorldMarketState copyWith({
    Map<CommodityId, int>? prices,
    Map<CommodityId, MarketActivity>? lastTurnActivity,
    Map<String, List<TradeOrder>>? carryForwardOffersByFactionId,
    Map<String, List<TradeOrder>>? carryForwardBidsByFactionId,
    Set<String>? completedTradePairKeys,
    Map<String, List<OverseasProfitCreditRecord>>?
    lastTurnOverseasProfitCreditsByGpId,
  }) {
    return WorldMarketState(
      prices: prices ?? this.prices,
      lastTurnActivity: lastTurnActivity ?? this.lastTurnActivity,
      carryForwardOffersByFactionId:
          carryForwardOffersByFactionId ?? this.carryForwardOffersByFactionId,
      carryForwardBidsByFactionId:
          carryForwardBidsByFactionId ?? this.carryForwardBidsByFactionId,
      completedTradePairKeys:
          completedTradePairKeys ?? this.completedTradePairKeys,
      lastTurnOverseasProfitCreditsByGpId:
          lastTurnOverseasProfitCreditsByGpId ??
          this.lastTurnOverseasProfitCreditsByGpId,
    );
  }

  Map<String, dynamic> toJson() => encodeWorldMarketStateToJson(this);

  static WorldMarketState fromJson(Map<String, dynamic> json) =>
      decodeWorldMarketStateFromJson(json);

  @override
  bool operator ==(Object other) => worldMarketStateEquals(this, other);

  @override
  int get hashCode => worldMarketStateHashCode(this);
}
