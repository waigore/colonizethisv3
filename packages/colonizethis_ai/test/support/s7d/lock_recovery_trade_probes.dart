// S7-D lock-recovery diagnostic trade-order / market-offer counters (Refs #2847 / #3941 / #4079 Slice D).
// Split from the former monolithic lock_recovery_probes.dart.

import 'package:colonizethis_ai/src/planning/treasury_planner.dart'
    show kTreasuryOfferPriorityUrgent, otherGreatPowerOfferableFabricHeld;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'supply_probes.dart';

/// Tallies the per-GP submitted trade-order counters for one turn from the
/// merged order list the resolver will apply (Refs #2924 Step 0). Mirrors the
/// inline scan it replaced: each offer bumps [tradeOfferCount] (plus
/// [tradeUrgentOfferCount] / [improvementInputOffersEmitted] /
/// [castIronFeedstockOffersEmitted] where the order qualifies); each bid bumps
/// [tradeBidCount] (plus the regiment- / improvement-input and castIron-
/// feedstock bid counters where the commodity matches). Carry-forward
/// world-market re-injections are excluded by construction — the caller passes
/// only the AI-emitted merged orders. Read-only over the supplied maps except
/// for the counter bumps. Extracted to keep the diagnostic test file at or
/// below the repo non-comment line limit.
void recordSeed42S7dTradeOrderCounters({
  required List<String> gpIds,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required Set<String> regimentInputCommodityIds,
  required Set<String> improvementInputCommodityIds,
  required Set<String> castIronFeedstockIds,
  required Map<String, int> tradeOfferCount,
  required Map<String, int> tradeUrgentOfferCount,
  required Map<String, int> tradeBidCount,
  required Map<String, int> improvementInputOffersEmitted,
  required Map<String, int> castIronFeedstockOffersEmitted,
  required Map<String, int> regimentInputBidsEmitted,
  required Map<String, int> improvementInputBidsEmitted,
  required Map<String, int> castIronFeedstockBidsEmitted,
}) {
  for (final gpId in gpIds) {
    final tradeOrders = tradeOrdersByPlayerId[gpId];
    if (tradeOrders == null) continue;
    for (final order in tradeOrders) {
      _recordSeed42S7dTradeOrderCounter(
        gpId: gpId,
        order: order,
        regimentInputCommodityIds: regimentInputCommodityIds,
        improvementInputCommodityIds: improvementInputCommodityIds,
        castIronFeedstockIds: castIronFeedstockIds,
        tradeOfferCount: tradeOfferCount,
        tradeUrgentOfferCount: tradeUrgentOfferCount,
        tradeBidCount: tradeBidCount,
        improvementInputOffersEmitted: improvementInputOffersEmitted,
        castIronFeedstockOffersEmitted: castIronFeedstockOffersEmitted,
        regimentInputBidsEmitted: regimentInputBidsEmitted,
        improvementInputBidsEmitted: improvementInputBidsEmitted,
        castIronFeedstockBidsEmitted: castIronFeedstockBidsEmitted,
      );
    }
  }
}

/// Records the per-GP counter bumps for a single merged [order] (Refs #2924
/// Step 0). Extracted from [recordSeed42S7dTradeOrderCounters] so the scan loop
/// stays within the repo control-flow nesting-depth limit; behavior is
/// identical to the inline offer/bid handling it replaced. Read-only over the
/// supplied sets except for the counter bumps.
void _recordSeed42S7dTradeOrderCounter({
  required String gpId,
  required TradeOrder order,
  required Set<String> regimentInputCommodityIds,
  required Set<String> improvementInputCommodityIds,
  required Set<String> castIronFeedstockIds,
  required Map<String, int> tradeOfferCount,
  required Map<String, int> tradeUrgentOfferCount,
  required Map<String, int> tradeBidCount,
  required Map<String, int> improvementInputOffersEmitted,
  required Map<String, int> castIronFeedstockOffersEmitted,
  required Map<String, int> regimentInputBidsEmitted,
  required Map<String, int> improvementInputBidsEmitted,
  required Map<String, int> castIronFeedstockBidsEmitted,
}) {
  if (order.type == TradeOrderType.offer) {
    bumpCounter(tradeOfferCount, gpId);
    if (order.priority >= kTreasuryOfferPriorityUrgent) {
      bumpCounter(tradeUrgentOfferCount, gpId);
    }
    if (improvementInputCommodityIds.contains(order.commodityId)) {
      bumpCounter(improvementInputOffersEmitted, gpId);
    }
    if (castIronFeedstockIds.contains(order.commodityId)) {
      bumpCounter(castIronFeedstockOffersEmitted, gpId);
    }
    return;
  }
  if (order.type != TradeOrderType.bid) return;
  bumpCounter(tradeBidCount, gpId);
  if (regimentInputCommodityIds.contains(order.commodityId)) {
    bumpCounter(regimentInputBidsEmitted, gpId);
  }
  if (improvementInputCommodityIds.contains(order.commodityId)) {
    bumpCounter(improvementInputBidsEmitted, gpId);
  }
  if (castIronFeedstockIds.contains(order.commodityId)) {
    bumpCounter(castIronFeedstockBidsEmitted, gpId);
  }
}

/// Records buyer-side `fabric` bid emission for the S7-D peasant-recruit
/// localization (Refs #2847 § buyer-side fabric acquisition). On each
/// fabric-starved gp this turn with offerable counterparty fabric supply
/// (`otherGreatPowerOfferableFabricHeld > 0`), bumps [emittedTurns] when the gp
/// emitted a `fabric` bid in [tradeOrdersByPlayerId], else [absentTurns].
/// Read-only over `(game, tradeOrdersByPlayerId)` except the counter bumps;
/// extracted to keep the diagnostic test file at or below the repo non-comment
/// line limit.
void recordSeed42S7dFabricBidCounters({
  required Game game,
  required Set<String> fabricStarvedThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required Map<String, int> emittedTurns,
  required Map<String, int> absentTurns,
}) {
  const fabricCommodityId = 'fabric';
  for (final gpId in fabricStarvedThisTurn) {
    if (otherGreatPowerOfferableFabricHeld(game, gpId) <= 0) continue;
    final tradeOrders = tradeOrdersByPlayerId[gpId];
    final emittedFabricBid =
        tradeOrders != null &&
        tradeOrders.any(
          (order) =>
              order.type == TradeOrderType.bid &&
              order.commodityId == fabricCommodityId,
        );
    if (emittedFabricBid) {
      bumpCounter(emittedTurns, gpId);
    } else {
      bumpCounter(absentTurns, gpId);
    }
  }
}

/// Records castIron market-offer presence/absence for the S7-D
/// feedstock-extraction localization (Refs #2847 § castIron market-supply
/// wall). On each gp whose regiment-build-input feedstock-extraction gate is
/// active this turn ([feedstockGateActiveThisTurn]), scans
/// [tradeOrdersByPlayerId] for any *other* faction emitting a
/// [castIronCommodityId] offer this turn and bumps [presentTurns] when one
/// exists, else [absentTurns].
///
/// The level-0 `build_improvement` cost a locked seller must clear to extract
/// its fabric feedstock requires one unit of the manufactured `castIron`
/// (`work_order_costs.dart` § `workOrderCostBuildImprovement`). The treasury
/// planner's direct-acquisition branch
/// (`treasury_regiment_bootstrap.dart` Pass 1 → `_marketHasStandingOfferSupplyFromOthers`)
/// only bids `castIron` directly when some other Great Power offers it;
/// otherwise it falls back to bidding the production feedstock (`timber` +
/// `iron`) for a domestic run. A flat-zero [presentTurns] across the run proves
/// the direct-acquisition branch is permanently closed — every Great Power
/// consumes its `castIron` for Old World military builds and never offers a
/// surplus (corroborated by `gpCastIronHeldAtTurn99 == 0` for every GP) — so
/// the only remaining path to the improvement input is the domestic castIron
/// run, which the labour-aware `gpCastIronRecipeLabourFeasibleTurns == 0`
/// counter shows is itself labour-walled (`castIron` `labourPerOutput` exceeds
/// a lock-recovery seller's effective labour). Read-only over the supplied maps
/// except the counter bumps; extracted to keep the diagnostic test file at or
/// below the repo non-comment line limit.
void recordSeed42S7dCastIronMarketOfferCounters({
  required Set<String> feedstockGateActiveThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required String castIronCommodityId,
  required Map<String, int> presentTurns,
  required Map<String, int> absentTurns,
}) => recordSeed42S7dOtherFactionOfferCounters(
  activeThisTurn: feedstockGateActiveThisTurn,
  tradeOrdersByPlayerId: tradeOrdersByPlayerId,
  commodityId: castIronCommodityId,
  presentTurns: presentTurns,
  absentTurns: absentTurns,
);

/// Shared other-faction sell-offer present/absent tally backing the castIron
/// and `fabric` market-offer recorders (Refs #2847). For each gp in
/// [activeThisTurn], scans [tradeOrdersByPlayerId] for any *other* faction
/// emitting a [commodityId] sell offer this turn and bumps [presentTurns] when
/// one exists, else [absentTurns]. The gp's own offer never counts as supply,
/// and bids (demand) are ignored. Read-only over the supplied maps except the
/// counter bumps; extracted so the two single-commodity recorders share one
/// scan loop.
void recordSeed42S7dOtherFactionOfferCounters({
  required Set<String> activeThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required String commodityId,
  required Map<String, int> presentTurns,
  required Map<String, int> absentTurns,
}) {
  for (final gpId in activeThisTurn) {
    var offeredByOther = false;
    for (final entry in tradeOrdersByPlayerId.entries) {
      if (entry.key == gpId) continue;
      final offered = entry.value.any(
        (order) =>
            order.type == TradeOrderType.offer &&
            order.commodityId == commodityId,
      );
      if (offered) {
        offeredByOther = true;
        break;
      }
    }
    if (offeredByOther) {
      bumpCounter(presentTurns, gpId);
    } else {
      bumpCounter(absentTurns, gpId);
    }
  }
}

/// Records `fabric` market-offer presence/absence for the S7-D peasant-recruit
/// fabric localization (Refs #2847 § fabric offer-side split).
///
/// On each gp whose castIron-labour peasant-recruit fabric market path is
/// active this turn ([fabricMarketPathActiveThisTurn]), scans
/// [tradeOrdersByPlayerId] for any *other* faction emitting a `fabric` offer
/// and bumps [presentTurns] when one exists, else [absentTurns].
///
/// Complements [otherGreatPowerFabricHeld] (gross holdings) and
/// [otherGreatPowerOfferableFabricHeld] (planner-scope offerable proxy): a
/// positive holdings / offerable total with a flat-zero [presentTurns] across
/// the run localizes the closed market door to the **trade-order emission**
/// layer (holders retain `fabric` in stockpile but never emit a sell offer)
/// rather than to buyer-side bid/match. Read-only over the supplied maps except
/// the counter bumps; extracted to keep the diagnostic test file at or below
/// the repo non-comment line limit.
void recordSeed42S7dFabricMarketOfferCounters({
  required Set<String> fabricMarketPathActiveThisTurn,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  required Map<String, int> presentTurns,
  required Map<String, int> absentTurns,
}) => recordSeed42S7dOtherFactionOfferCounters(
  activeThisTurn: fabricMarketPathActiveThisTurn,
  tradeOrdersByPlayerId: tradeOrdersByPlayerId,
  commodityId: 'fabric',
  presentTurns: presentTurns,
  absentTurns: absentTurns,
);

