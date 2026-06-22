/// Single `Game`→player world-market numeric snapshot facade.
///
/// SPEC/program/economy-models.md § Package locations,
/// SPEC/program/world-market-resolution.md § Trade order validation /
/// suggestion.
///
/// Builds the *shared* per-player world-market scalars once from live [Game]
/// state (bid-type cap, cross-commodity cargo capacity, treasury bid budget,
/// market prices/rules) so the validator and suggester context factories stop
/// re-learning the import graph (`bid_type_cap`, `sea_transport`,
/// `treasury_bid_budget`). Per-context *availability* lists differ by concern —
/// the validator uses offer caps (`offerCapByCommodityId`) while the suggester
/// uses raw post-production stockpile — so they are intentionally NOT part of
/// this snapshot and stay supplied by each factory. (Refs #3615 Cluster 2.)
library;

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../sea_transport.dart' show cargoHoldsForHomeFleet;
import 'bid_type_cap.dart' show worldMarketBidTypeCap;
import 'trade_order_suggester.dart' show TradeSuggestionContext;
import 'trade_order_validation_context.dart'
    show TradeOrderValidationContext;
import 'sellable_quantity.dart' show offerCapByCommodityId;
import 'treasury_bid_budget.dart'
    show stagedBidTotalSpendByPlayer, treasuryAvailableForBidsByPlayer;

/// Shared per-player world-market numeric snapshot built from [Game].
///
/// Holds only the scalars that are computed identically for the validator and
/// suggester contexts. Availability maps are concern-specific and are not held
/// here (see library doc).
class WorldMarketPlayerContext {
  const WorldMarketPlayerContext({
    required this.playerId,
    required this.bidTypeCap,
    required this.tradeCargoCapacity,
    required this.treasuryBudgetForBids,
    required this.worldMarketState,
    required this.resourceRules,
  });

  /// Submitting faction id.
  final String playerId;

  /// `0 / 3 / 6` cap on distinct bid commodities this turn
  /// (`worldMarketBidTypeCap`).
  final int bidTypeCap;

  /// Cross-commodity cargo budget for this player's bids this turn
  /// (`cargoHoldsForHomeFleet`).
  final int tradeCargoCapacity;

  /// Maximum `Σ (quantity × effectiveMarketPrice)` across admitted bids this
  /// turn (`treasuryAvailableForBidsByPlayer`, staged when applicable).
  final int treasuryBudgetForBids;

  /// Market prices used to price bid spend.
  final WorldMarketState worldMarketState;

  /// Catalog fallback prices when [worldMarketState] lacks an entry.
  final data.ResourceRules resourceRules;
}

/// Builds the shared [WorldMarketPlayerContext] from live [Game] state.
///
/// [treasuryBudgetForBids] uses the same staged-budget composition as the
/// Trade UI: when [stagedOrders] and [projectedTreasuryDelta] are both
/// supplied, this player's running bid spend is added back to the projected
/// delta before recomputing the available-for-bids budget. When either is
/// omitted the budget is raw treasury only. The Game-scoped build path lives
/// here (not in `orders`/`turn`) so `colonizethis_economy` stays free of any
/// `orders`/`turn` dependency per
/// `SPEC/program/logic-package-split-phase0.md` § economy ↔ orders.
WorldMarketPlayerContext worldMarketPlayerContextFromGame(
  Game game,
  String playerId, {
  Orders? stagedOrders,
  int? projectedTreasuryDelta,
}) {
  final rules = data.ResourceRules.defaultRules;
  var treasuryBudget = treasuryAvailableForBidsByPlayer(
    game: game,
    playerId: playerId,
  );
  if (stagedOrders != null && projectedTreasuryDelta != null) {
    final int bidSpend = stagedBidTotalSpendByPlayer(
      orders: stagedOrders,
      playerId: playerId,
      game: game,
      resourceRules: rules,
    );
    treasuryBudget = treasuryAvailableForBidsByPlayer(
      game: game,
      playerId: playerId,
      projectedNonBidTreasuryDelta: projectedTreasuryDelta + bidSpend,
    );
  }
  return WorldMarketPlayerContext(
    playerId: playerId,
    bidTypeCap: worldMarketBidTypeCap(game, playerId),
    tradeCargoCapacity: cargoHoldsForHomeFleet(game, playerId),
    treasuryBudgetForBids: treasuryBudget,
    worldMarketState: game.worldMarketState,
    resourceRules: rules,
  );
}

/// Builds a [TradeOrderValidationContext] from live [Game] state for order
/// submission and `OrderEngine` validation.
///
/// Thin wrapper over [worldMarketPlayerContextFromGame] that adds the
/// validator-specific offer caps (`offerCapByCommodityId`). Treasury-budget
/// staging semantics are identical to the snapshot factory.
TradeOrderValidationContext tradeOrderValidationContextFromGame(
  Game game,
  String playerId, {
  Orders? stagedOrders,
  int? projectedTreasuryDelta,
}) {
  final base = worldMarketPlayerContextFromGame(
    game,
    playerId,
    stagedOrders: stagedOrders,
    projectedTreasuryDelta: projectedTreasuryDelta,
  );
  return TradeOrderValidationContext(
    playerId: base.playerId,
    bidTypeCap: base.bidTypeCap,
    tradeCargoCapacity: base.tradeCargoCapacity,
    availableStockpileByCommodityId: offerCapByCommodityId(
      game: game,
      playerId: playerId,
    ),
    treasuryBudgetForBids: base.treasuryBudgetForBids,
    worldMarketState: base.worldMarketState,
    resourceRules: base.resourceRules,
  );
}

/// Builds a [TradeSuggestionContext] from live [Game] state so AI/order layers
/// stop hand-wiring the shared world-market scalars.
///
/// The caller supplies [availableStockpileByCommodityId] because the suggester
/// availability source is concern-specific (raw post-production stockpile),
/// distinct from the validator offer caps. [commodityNeedByCommodityId] and the
/// priority overrides keep the suggester's existing defaults when omitted.
TradeSuggestionContext tradeSuggestionContextFromGame(
  Game game,
  String playerId, {
  required Map<CommodityId, int> availableStockpileByCommodityId,
  Map<CommodityId, int> commodityNeedByCommodityId =
      const <CommodityId, int>{},
  int offerPriority = TradeSuggestionContext.defaultOfferPriority,
  int bidPriority = TradeSuggestionContext.defaultBidPriority,
  Orders? stagedOrders,
  int? projectedTreasuryDelta,
}) {
  final base = worldMarketPlayerContextFromGame(
    game,
    playerId,
    stagedOrders: stagedOrders,
    projectedTreasuryDelta: projectedTreasuryDelta,
  );
  return TradeSuggestionContext(
    playerId: base.playerId,
    bidTypeCap: base.bidTypeCap,
    tradeCargoCapacity: base.tradeCargoCapacity,
    availableStockpileByCommodityId: availableStockpileByCommodityId,
    commodityNeedByCommodityId: commodityNeedByCommodityId,
    treasuryBudgetForBids: base.treasuryBudgetForBids,
    worldMarketState: base.worldMarketState,
    resourceRules: base.resourceRules,
    offerPriority: offerPriority,
    bidPriority: bidPriority,
  );
}
