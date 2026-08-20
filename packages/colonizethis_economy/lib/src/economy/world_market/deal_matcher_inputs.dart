/// Inputs for a single [DealMatcher.matchDeals] pass.
///
/// SPEC/game/world-market.md § Trade orders / Cargo / FTP,
/// SPEC/program/world-market-resolution.md § Deal matching engine.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'purchased_tile_index.dart';

/// All maps are read-only from the matcher's perspective; the matcher never
/// mutates input collections. `tradeCapacityByFactionId` MUST be the
/// pre-computed per-faction cross-commodity trade cargo capacity
/// (`max(0, totalHomeFleetCargoHolds - overseasExtractionActualTonnage)`
/// per `SPEC/game/world-market.md` § Cargo). `treasuryBudgetByBuyerFactionId`
/// MUST be each buyer's `Player.treasury` at phase 13 start, clamped at `0`
/// for negative balances (`SPEC/program/world-market-resolution.md` § Step C
/// treasury clamp, Refs #3115). Buyers omitted from this map are treated as
/// having a `0` treasury budget — mirroring the `tradeCapacityByFactionId`
/// edge case — so no fills are emitted and every bid carries forward.
/// `pricesByCommodityId` MUST be the `oldPrice` map valid for the current
/// turn (deals clear at oldPrice). `ftpPairKeys` MUST contain canonical
/// bilateral keys produced via [DealMatcher.pairKey]. `purchasedTileIndex`,
/// when supplied, gates the First Right of Refusal absolute-priority pass —
/// pass `null` to disable FRR (legacy behavior; matches pre-#2992 callers).
typedef DealMatchInputs = ({
  Map<String, List<TradeOrder>> offersByFactionId,
  Map<String, List<TradeOrder>> bidsByFactionId,
  Map<String, int> tradeCapacityByFactionId,
  Map<String, int> treasuryBudgetByBuyerFactionId,
  Map<CommodityId, double> pricesByCommodityId,
  Set<String> ftpPairKeys,
  PurchasedTileIndex? purchasedTileIndex,

  /// Faction ids whose sell-side orders are sorted ahead of other offers
  /// within the same priority tier (Refs #2924 F12 — lock-recovery sellers).
  Set<String> lockRecoverySellerPriorityIds,

  /// Treasury at phase start for lock-recovery sub-ordering (poorest first).
  Map<String, int> treasuryByFactionId,

  /// #3753 R7.3 sell-priority relation tiebreaker. Maps a Minor/Tribe seller
  /// faction id to the consulate-holding (or higher) buyer GPs and their
  /// relation score with that seller (`SPEC/game/world-market.md` §
  /// Sell-priority relation tiebreaker). When an offer's `sellerFactionId`
  /// is present, its tier-bids are reordered so consulate-holding buyers are
  /// served first by descending relation (ties by ascending buyer faction id,
  /// then faction-local index), followed by consulate-less buyers in default
  /// order. An empty map (or a seller absent from it — e.g. all GP sellers)
  /// preserves the legacy ordering.
  Map<String, Map<String, num>> sellPriorityRelationByMinorTribeSeller,

  /// #3753 R6 boycott colony trade embargo. Canonical [DealMatcher.pairKey]
  /// keys for every `(colonyTribeId, boycottedTargetGpId)` pair derived from
  /// `Game.boycottStates` × `Game.colonyStates`. A match attempt whose
  /// `pairKey(sellerFactionId, buyerFactionId)` is present is skipped (no
  /// `FilledDeal`; both orders carry forward), blocking all trade between a
  /// boycotted Great Power and the issuer's colony Tribes in both directions.
  /// An empty set disables the exclusion (legacy behavior — identical
  /// matching). SPEC/program/world-market-resolution.md § Deal matching engine.
  Set<String> boycottBlockedPairKeys,
});
