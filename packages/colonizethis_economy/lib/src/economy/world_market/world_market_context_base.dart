/// Shared base for the world-market pure-context inputs.
///
/// `TradeOrderValidationContext` (`trade_order_validation_context.dart`) and
/// `TradeSuggestionContext` (`trade_order_suggester.dart`) both carry the same
/// four numeric/identity fields (`playerId`, `bidTypeCap`,
/// `tradeCargoCapacity`, `availableStockpileByCommodityId`). This base holds
/// them once (issue #3396 cluster 4) so the two context types stay
/// independently constructible — the validator keeps
/// `availableStockpileByCommodityId` required, the suggester keeps its empty
/// default — while sharing the field declarations and their documentation.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Common world-market pure-context fields shared by the validator and
/// suggester contexts.
abstract class WorldMarketContextBase {
  const WorldMarketContextBase({
    required this.playerId,
    required this.bidTypeCap,
    required this.tradeCargoCapacity,
    this.availableStockpileByCommodityId = const <CommodityId, int>{},
  });

  /// Submitting faction id. Informational; world-market context consumers do
  /// no cross-player checks.
  final String playerId;

  /// `0 / 3 / 6` cap on distinct bid commodities for this player this turn.
  /// Pre-computed via `worldMarketBidTypeCap` in `world_market/bid_type_cap.dart`.
  final int bidTypeCap;

  /// Cross-commodity cargo budget for this player's bids this turn (units).
  /// Per `SPEC/game/world-market.md` § Cargo:
  /// `max(0, totalHomeFleetCargoHolds - overseasExtractionActualTonnage)`.
  final int tradeCargoCapacity;

  /// Per-commodity quantity available to **offer** this turn, after committed
  /// industry allocation has been subtracted from the projected
  /// post-production stockpile (`stockpile[id] - industryAllocation[id]`,
  /// clamped at 0). Missing entries are treated as `0`. Riches commodities are
  /// ignored (rule 2).
  final Map<CommodityId, int> availableStockpileByCommodityId;
}
