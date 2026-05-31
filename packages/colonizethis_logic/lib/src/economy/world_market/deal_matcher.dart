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
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'purchased_tile_index.dart';

/// Inputs for a single [DealMatcher.matchDeals] pass.
///
/// All maps are read-only from the matcher's perspective; the matcher never
/// mutates input collections. `tradeCapacityByFactionId` MUST be the
/// pre-computed per-faction cross-commodity trade cargo capacity
/// (`max(0, totalHomeFleetCargoHolds - overseasExtractionActualTonnage)`
/// per `SPEC/game/world-market.md` § Cargo). `pricesByCommodityId` MUST be
/// the `oldPrice` map valid for the current turn (deals clear at oldPrice).
/// `ftpPairKeys` MUST contain canonical bilateral keys produced via
/// [DealMatcher.pairKey]. `purchasedTileIndex`, when supplied, gates the
/// First Right of Refusal absolute-priority pass — pass `null` to disable
/// FRR (legacy behavior; matches pre-#2992 callers).
typedef DealMatchInputs = ({
  Map<String, List<TradeOrder>> offersByFactionId,
  Map<String, List<TradeOrder>> bidsByFactionId,
  Map<String, int> tradeCapacityByFactionId,
  Map<CommodityId, double> pricesByCommodityId,
  Set<String> ftpPairKeys,
  PurchasedTileIndex? purchasedTileIndex,
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

    final filled = <FilledDeal>[];
    final activity = <CommodityId, MarketActivity>{};

    final offerStatesByFaction = _indexOrdersByFaction(inputs.offersByFactionId);
    final bidStatesByFaction = _indexOrdersByFaction(inputs.bidsByFactionId);

    final purchasedTileIndex = inputs.purchasedTileIndex;
    final firstRightEnabled =
        purchasedTileIndex != null && purchasedTileIndex.isNotEmpty;

    for (final commodityId in commodityIds) {
      final commodityOffers = _orderedStatesForCommodity(
        offerStatesByFaction,
        commodityId,
      );
      final commodityBids = _orderedStatesForCommodity(
        bidStatesByFaction,
        commodityId,
      );

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
            filledOut: filled,
          );
        }

        final tiers = _collectPriorityTiers(commodityOffers, commodityBids);

        for (final tier in tiers) {
          final tierOffers = commodityOffers
              .where((s) => s.order.priority == tier && s.remaining > 0)
              .toList(growable: false);
          final tierBids = commodityBids
              .where((s) => s.order.priority == tier && s.remaining > 0)
              .toList(growable: false);

          filledQuantity += _runTierMatching(
            tierOffers: tierOffers,
            tierBids: tierBids,
            commodityId: commodityId,
            pricePerUnit: price,
            ftpPairKeys: inputs.ftpPairKeys,
            remainingCargo: remainingCargo,
            filledOut: filled,
          );
        }
      }

      if (totalOfferQuantity > 0 ||
          totalBidQuantity > 0 ||
          filledQuantity > 0) {
        activity[commodityId] = MarketActivity(
          totalBidQuantity: totalBidQuantity,
          totalOfferQuantity: totalOfferQuantity,
          filledQuantity: filledQuantity,
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

  /// Runs the First Right of Refusal absolute-priority pass for one
  /// commodity per `SPEC/game/world-market-first-right-of-refusal.md` and
  /// `SPEC/program/world-market-resolution.md` § Step B (absolute-priority
  /// tier above tier 1).
  ///
  /// For each offer whose `originTileKey` resolves through
  /// [purchasedTileIndex], iterate the owning Great Power's bids for the
  /// same commodity in their submitted (`factionLocalIndex`) order and
  /// match them ahead of any integer-priority tier. FTP membership is
  /// ignored — FRR overrides FTP per `SPEC/game/world-market.md`.
  /// `FilledDeal.isFirstRightOfRefusalMatch` is set to true on emitted
  /// deals so D4 treasury transfers and the Deal Book UI can identify
  /// FRR-applied flows. Cargo is consumed normally per buyer.
  ///
  /// Offers iterate in `(sellerFactionId, factionLocalIndex)` order to
  /// preserve determinism. Bids iterate in `factionLocalIndex` order
  /// within the owning GP's bid list.
  static int _runFirstRightMatching({
    required List<_OrderState> commodityOffers,
    required List<_OrderState> commodityBids,
    required CommodityId commodityId,
    required double pricePerUnit,
    required PurchasedTileIndex purchasedTileIndex,
    required Map<String, int> remainingCargo,
    required List<FilledDeal> filledOut,
  }) {
    if (commodityOffers.isEmpty || commodityBids.isEmpty) return 0;
    var filledQuantity = 0;

    int attemptFrrMatch(_OrderState offer, _OrderState bid) {
      if (offer.remaining <= 0 || bid.remaining <= 0) return 0;
      final cargoLeft = remainingCargo[bid.factionId] ?? 0;
      if (cargoLeft <= 0) return 0;
      final matchQty = _min3(offer.remaining, bid.remaining, cargoLeft);
      if (matchQty <= 0) return 0;
      filledOut.add(
        FilledDeal(
          sellerFactionId: offer.factionId,
          buyerFactionId: bid.factionId,
          commodityId: commodityId,
          quantity: matchQty,
          pricePerUnit: pricePerUnit,
          isFirstRightOfRefusalMatch: true,
          sellerOriginTileKey: offer.order.originTileKey,
        ),
      );
      offer.remaining -= matchQty;
      bid.remaining -= matchQty;
      remainingCargo[bid.factionId] = cargoLeft - matchQty;
      return matchQty;
    }

    for (final offer in commodityOffers) {
      if (offer.remaining <= 0) continue;
      final originTileKey = offer.order.originTileKey;
      if (originTileKey == null) continue;
      final attribution = purchasedTileIndex.attributionForTileKey(
        originTileKey,
      );
      if (attribution == null) continue;
      final owningGpId = attribution.owningGpId;
      // FRR overlays the owning GP's purchase intent on the seller's tile;
      // a buyer == seller scenario would mean the GP somehow auto-offered
      // its own land, which the index already filters out (purchased tiles
      // currently owned by a GP are excluded). Guard defensively anyway.
      if (owningGpId == offer.factionId) continue;
      for (final bid in commodityBids) {
        if (offer.remaining <= 0) break;
        if (bid.factionId != owningGpId) continue;
        if (bid.remaining <= 0) continue;
        filledQuantity += attemptFrrMatch(offer, bid);
      }
    }

    return filledQuantity;
  }

  static int _runTierMatching({
    required List<_OrderState> tierOffers,
    required List<_OrderState> tierBids,
    required CommodityId commodityId,
    required double pricePerUnit,
    required Set<String> ftpPairKeys,
    required Map<String, int> remainingCargo,
    required List<FilledDeal> filledOut,
  }) {
    if (tierOffers.isEmpty || tierBids.isEmpty) return 0;
    var filledQuantity = 0;

    bool ftpEligible(_OrderState offer, _OrderState bid) =>
        ftpPairKeys.contains(pairKey(offer.factionId, bid.factionId));

    int attemptMatch(_OrderState offer, _OrderState bid, {required bool ftp}) {
      if (offer.remaining <= 0 || bid.remaining <= 0) return 0;
      final cargoLeft = remainingCargo[bid.factionId] ?? 0;
      if (cargoLeft <= 0) return 0;
      final matchQty = _min3(offer.remaining, bid.remaining, cargoLeft);
      if (matchQty <= 0) return 0;
      filledOut.add(
        FilledDeal(
          sellerFactionId: offer.factionId,
          buyerFactionId: bid.factionId,
          commodityId: commodityId,
          quantity: matchQty,
          pricePerUnit: pricePerUnit,
          isFtpMatch: ftp,
          sellerOriginTileKey: offer.order.originTileKey,
        ),
      );
      offer.remaining -= matchQty;
      bid.remaining -= matchQty;
      remainingCargo[bid.factionId] = cargoLeft - matchQty;
      return matchQty;
    }

    // Pass 1: FTP-eligible matches only.
    for (final offer in tierOffers) {
      if (offer.remaining <= 0) continue;
      for (final bid in tierBids) {
        if (offer.remaining <= 0) break;
        if (bid.remaining <= 0) continue;
        if (!ftpEligible(offer, bid)) continue;
        filledQuantity += attemptMatch(offer, bid, ftp: true);
      }
    }

    // Pass 2: any remaining matches.
    for (final offer in tierOffers) {
      if (offer.remaining <= 0) continue;
      for (final bid in tierBids) {
        if (offer.remaining <= 0) break;
        if (bid.remaining <= 0) continue;
        filledQuantity += attemptMatch(
          offer,
          bid,
          ftp: ftpEligible(offer, bid),
        );
      }
    }

    return filledQuantity;
  }

  static List<CommodityId> _collectCommodityIds(
    Map<String, List<TradeOrder>> offers,
    Map<String, List<TradeOrder>> bids,
  ) {
    final set = <CommodityId>{};
    for (final list in offers.values) {
      for (final order in list) {
        set.add(order.commodityId);
      }
    }
    for (final list in bids.values) {
      for (final order in list) {
        set.add(order.commodityId);
      }
    }
    final sorted = set.toList()..sort();
    return sorted;
  }

  static Map<String, List<_OrderState>> _indexOrdersByFaction(
    Map<String, List<TradeOrder>> ordersByFaction,
  ) {
    final sortedFactionIds = ordersByFaction.keys.toList()..sort();
    final result = <String, List<_OrderState>>{};
    for (final factionId in sortedFactionIds) {
      final orders = ordersByFaction[factionId] ?? const <TradeOrder>[];
      final states = <_OrderState>[];
      for (var i = 0; i < orders.length; i++) {
        states.add(
          _OrderState(
            factionId: factionId,
            order: orders[i],
            factionLocalIndex: i,
          ),
        );
      }
      result[factionId] = states;
    }
    return result;
  }

  static List<_OrderState> _orderedStatesForCommodity(
    Map<String, List<_OrderState>> statesByFaction,
    CommodityId commodityId,
  ) {
    final out = <_OrderState>[];
    for (final entry in statesByFaction.entries) {
      for (final state in entry.value) {
        if (state.order.commodityId == commodityId) {
          out.add(state);
        }
      }
    }
    return out;
  }

  static List<int> _collectPriorityTiers(
    List<_OrderState> offers,
    List<_OrderState> bids,
  ) {
    final tiers = <int>{};
    for (final state in offers) {
      tiers.add(state.order.priority);
    }
    for (final state in bids) {
      tiers.add(state.order.priority);
    }
    final sorted = tiers.toList()..sort();
    return sorted;
  }

  static int _sumInputQuantity(List<_OrderState> states) {
    var total = 0;
    for (final state in states) {
      total += state.order.quantity;
    }
    return total;
  }

  static Map<String, List<TradeOrder>> _carryForwardByFaction(
    Map<String, List<_OrderState>> statesByFaction,
  ) {
    final result = <String, List<TradeOrder>>{};
    for (final entry in statesByFaction.entries) {
      final remaining = <TradeOrder>[];
      for (final state in entry.value) {
        if (state.remaining > 0) {
          remaining.add(state.asCarryForward());
        }
      }
      if (remaining.isNotEmpty) {
        result[entry.key] = List.unmodifiable(remaining);
      }
    }
    return Map.unmodifiable(result);
  }

  static int _min3(int a, int b, int c) {
    var m = a < b ? a : b;
    if (c < m) m = c;
    return m;
  }
}
