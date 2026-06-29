/// Deal matching engine for the world market phase.
///
/// SPEC/game/world-market.md § Trade orders / Cargo / FTP,
/// SPEC/game/world-market-first-right-of-refusal.md § Rules,
/// SPEC/program/world-market-resolution.md § Deal matching engine.
///
/// The matcher is pure: deterministic for fixed inputs and silent (no logger
/// calls). It is safe to call inside the deterministic turn-resolution
/// pipeline under the 15-second turn-resolution budget per
/// `.cursor/rules/colonizethis-turn-resolution-budget.mdc`.
///
/// This slice covers priority-queue fills, the same-tier FTP tiebreaker,
/// partial fills, per-buyer cross-commodity cargo tracking, and the First
/// Right of Refusal (FRR) absolute-priority override added by Issue D /
/// #2992 D2: when a minor/tribe offer carries a non-null
/// `originTileKey` that resolves through [PurchasedTileIndex], the owning
/// Great Power's bids for the same commodity match against that offer
/// before any integer-priority tier or FTP pair runs.
///
/// The matching passes and the order-indexing / treasury-affordability
/// helpers live in `part of` concern files
/// (`deal_matcher_matching.dart`, `deal_matcher_indexing.dart`) to keep
/// each file below the repo file-size policy (`SPEC/program/
/// dart-file-non-comment-line-size.md`); they share this library's private
/// scope so behaviour is unchanged (Refs #3290 Phase 0 file decomposition).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'purchased_tile_index.dart';

part 'deal_matcher_matching.dart';
part 'deal_matcher_indexing.dart';

/// Inputs for a single [DealMatcher.matchDeals] pass.
///
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
});

/// Internal mutable bookkeeping for a single order participating in matching.
class _OrderState {
  _OrderState({
    required this.factionId,
    required this.order,
    required this.factionLocalIndex,
  }) : remaining = order.quantity;

  final String factionId;
  final TradeOrder order;

  /// Stable index of this order inside the faction's input list, used as a
  /// tiebreaker so ordering is deterministic across runs.
  final int factionLocalIndex;

  int remaining;

  /// True once the treasury clamp has prevented this bid from fully
  /// filling at least one match attempt. Drives single-note emission per
  /// truncated bid per `SPEC/program/world-market-resolution.md` § Step C
  /// (Refs #3115); only used for bid states (offers leave this `false`).
  bool treasuryTruncated = false;

  TradeOrder asCarryForward() => order.copyWith(quantity: remaining);
}

/// Pure helpers and the canonical matching pass for the world market phase.
class DealMatcher {
  const DealMatcher._();

  /// Returns the canonical key for an unordered bilateral faction pair.
  ///
  /// FTP membership is symmetric — `pairKey('a', 'b') == pairKey('b', 'a')`.
  /// Callers populate `ftpPairKeys` with the result so the matcher does not
  /// need to query both orderings.
  static String pairKey(String a, String b) {
    if (a.compareTo(b) <= 0) {
      return '$a|$b';
    }
    return '$b|$a';
  }

  /// Runs a single matching pass over the supplied inputs.
  ///
  /// Returns the emitted [FilledDeal]s, the per-faction carry-forward orders
  /// (with `quantity` set to remaining units), and per-commodity activity
  /// totals. The matcher does not compute price change — the phase handler
  /// composes that separately via `PriceDiscovery.computeNextPrice` because
  /// only the handler knows which inputs are newly-submitted vs
  /// carry-forward (carry-forwards are excluded from the supply/demand
  /// signal per `SPEC/game/world-market.md` § Price discovery).
  static DealMatchResult matchDeals(DealMatchInputs inputs) {
    final commodityIds = _collectCommodityIds(
      inputs.offersByFactionId,
      inputs.bidsByFactionId,
    );
    if (commodityIds.isEmpty) {
      return DealMatchResult.empty;
    }

    final remainingCargo = <String, int>{
      for (final entry in inputs.tradeCapacityByFactionId.entries)
        entry.key: entry.value < 0 ? 0 : entry.value,
    };

    // Per-buyer running treasury accumulator (Refs #3115). Mirrors the
    // existing `remainingCargo` pattern: initialized from the buyer's
    // start-of-phase treasury budget (already clamped at 0 for negative
    // balances by the caller per
    // `SPEC/program/world-market-resolution.md` § Deal matching engine);
    // decremented by `round(matchQty × pricePerUnit)` after each emitted
    // `FilledDeal`. A defensive `< 0` clamp here mirrors the cargo
    // initialization in case a caller passes a stale negative value.
    final remainingTreasury = <String, int>{
      for (final entry in inputs.treasuryBudgetByBuyerFactionId.entries)
        entry.key: entry.value < 0 ? 0 : entry.value,
    };

    final filled = <FilledDeal>[];
    final activity = <CommodityId, MarketActivity>{};
    final notesByCommodity = <CommodityId, List<MarketActivityNote>>{};

    final offerStatesByFaction = _indexOrdersByFaction(
      inputs.offersByFactionId,
    );
    final bidStatesByFaction = _indexOrdersByFaction(inputs.bidsByFactionId);

    // Pre-build the per-commodity views once (Refs #3517 Cluster 3) so the
    // matching loop below is an O(1) lookup instead of re-scanning every order
    // state for each commodity.
    final offerStatesByCommodity = _indexStatesByCommodity(offerStatesByFaction);
    final bidStatesByCommodity = _indexStatesByCommodity(bidStatesByFaction);

    final purchasedTileIndex = inputs.purchasedTileIndex;
    final firstRightEnabled =
        purchasedTileIndex != null && purchasedTileIndex.isNotEmpty;

    for (final commodityId in commodityIds) {
      final commodityOffers =
          offerStatesByCommodity[commodityId] ?? const <_OrderState>[];
      final commodityBids =
          bidStatesByCommodity[commodityId] ?? const <_OrderState>[];

      final totalOfferQuantity = _sumInputQuantity(commodityOffers);
      final totalBidQuantity = _sumInputQuantity(commodityBids);
      var filledQuantity = 0;

      if (commodityOffers.isNotEmpty && commodityBids.isNotEmpty) {
        final price = inputs.pricesByCommodityId[commodityId] ?? 0.0;

        if (firstRightEnabled) {
          filledQuantity += _runFirstRightMatching(
            commodityOffers: commodityOffers,
            commodityBids: commodityBids,
            commodityId: commodityId,
            pricePerUnit: price,
            purchasedTileIndex: purchasedTileIndex,
            remainingCargo: remainingCargo,
            remainingTreasury: remainingTreasury,
            filledOut: filled,
          );
        }

        final tiers = _collectPriorityTiers(commodityOffers, commodityBids);

        for (final tier in tiers) {
          final tierOffers = commodityOffers
              .where((s) => s.order.priority == tier && s.remaining > 0)
              .toList();
          _sortOffersLockRecoverySellersFirst(
            tierOffers,
            lockRecoverySellerPriorityIds: inputs.lockRecoverySellerPriorityIds,
            treasuryByFactionId: inputs.treasuryByFactionId,
          );
          final tierBids = commodityBids
              .where((s) => s.order.priority == tier && s.remaining > 0)
              .toList(growable: false);

          filledQuantity += _runTierMatching(
            tierOffers: tierOffers,
            tierBids: tierBids,
            commodityId: commodityId,
            pricePerUnit: price,
            ftpPairKeys: inputs.ftpPairKeys,
            sellPriorityRelationByMinorTribeSeller:
                inputs.sellPriorityRelationByMinorTribeSeller,
            remainingCargo: remainingCargo,
            remainingTreasury: remainingTreasury,
            filledOut: filled,
          );
        }
      }

      // Emit one `bidPartialFillTreasuryInsufficient` note per truncated
      // bid (`SPEC/program/world-market-resolution.md` § Step C, Refs
      // #3115). Iteration order matches the offers-then-bids walks above;
      // we re-scan the bid states list to preserve original submission
      // order across factions (factions are alphabetically ordered by
      // `_indexOrdersByFaction`, so the resulting note sequence is
      // deterministic for fixed inputs).
      for (final state in commodityBids) {
        if (!state.treasuryTruncated) continue;
        final commodityNotes = notesByCommodity.putIfAbsent(
          commodityId,
          () => <MarketActivityNote>[],
        );
        commodityNotes.add(
          MarketActivityNote(
            kind: MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
            factionId: state.factionId,
            commodityId: commodityId,
            quantity: state.order.quantity,
          ),
        );
      }

      if (totalOfferQuantity > 0 ||
          totalBidQuantity > 0 ||
          filledQuantity > 0) {
        final commodityNotes = notesByCommodity[commodityId];
        activity[commodityId] = MarketActivity(
          totalBidQuantity: totalBidQuantity,
          totalOfferQuantity: totalOfferQuantity,
          filledQuantity: filledQuantity,
          notes: commodityNotes == null
              ? const <MarketActivityNote>[]
              : List<MarketActivityNote>.unmodifiable(commodityNotes),
        );
      }
    }

    return DealMatchResult(
      filledDeals: List.unmodifiable(filled),
      unfilledOffersByFactionId: _carryForwardByFaction(offerStatesByFaction),
      unfilledBidsByFactionId: _carryForwardByFaction(bidStatesByFaction),
      activityByCommodityId: Map.unmodifiable(activity),
    );
  }
}
