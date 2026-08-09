// Treasury planner emit-input assembly (Refs #4239 Slice A).
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/ai_api.dart'
    show
        ExtractionTotals,
        boycottedColonySellableCommodityIds,
        carryForwardBidNotionalByPlayer,
        peerLockRecoverySellerNeededProducibleImprovementInputs,
        pendingTreasuryCostsForTurn,
        tradeCargoCapacityForGreatPower,
        worldMarketBidTypeCap;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner_economy.dart' show cheapestRegimentBuildTreasuryCost;
import 'treasury_bid_emission.dart';
import 'treasury_lock_recovery.dart';
import 'treasury_market_pricing.dart';
import 'treasury_need_analysis.dart';
import 'treasury_planner_constants.dart';
import 'treasury_planner_input.dart';
import 'treasury_regiment_bootstrap_bids.dart';
import 'treasury_relation_boost_preference.dart';

EmitTradeOrdersInput? buildEmitTradeOrdersInput(TreasuryPlannerInput input) {
  final game = input.game;
  final playerId = input.playerId;
  final stockpile = input.stockpile;
  final productionAssignments = input.productionAssignments;
  final treasury = input.treasury;
  final snapshot = input.snapshot;
  final tileMapByRegion = input.tileMapByRegion;
  final topology = input.topology;
  final currentOrders = input.currentOrders;
  final extractionById = input.extractionById;
  final ResourceRules rules = input.resourceRules ?? ResourceRules.defaultRules;
  final bidTypeCap = worldMarketBidTypeCap(game, playerId);
  final tradeCargoCapacity = resolveTradeCargoCapacity(
    game: game,
    playerId: playerId,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
    extractionById: extractionById,
  );

  final projected = projectStockpileAfterProduction(
    stockpile: stockpile,
    productionAssignments: productionAssignments,
  );
  final inputNeeds = inputNeedsFromAssignments(productionAssignments);
  final trackedIds = trackedCommodityIds(
    stockpile: stockpile,
    projected: projected,
    inputNeeds: inputNeeds,
    productionAssignments: productionAssignments,
  );
  final available = <CommodityId, int>{};
  final need = <CommodityId, int>{};
  final marketPrices = game.worldMarketState.prices;
  // Refs #2994 F8: carry-forward residuals already represented in Issue A's
  // queues are subtracted from the planner's new-emission gap so the engine
  // never sees duplicate quantities.
  final carryForwardOffers = carryForwardQuantitiesByCommodity(
    state: game.worldMarketState,
    playerId: playerId,
    side: TradeOrderType.offer,
  );
  final carryForwardBids = carryForwardQuantitiesByCommodity(
    state: game.worldMarketState,
    playerId: playerId,
    side: TradeOrderType.bid,
  );

  final rawTreasury = treasury < 0 ? 0 : treasury;
  final threshold = cheapestRegimentBuildTreasuryCost();
  final brokeForLockRecovery = rawTreasury < threshold;
  final lockRecoveryScan = LockRecoveryGameScan.fromGame(
    game,
    snapshot: snapshot,
  );

  // Refs #2924 F17: a below-quota zero-NW lock-recovery seller releases its
  // food surplus aggressively so its trade cargo is spent selling the
  // liquidity-food commodity into the net-positive minor/tribe auto-bid pool
  // (F15) instead of being left idle behind a 2x food safety buffer. On seed
  // 42 gp6 keeps only ~42 grain and rarely clears the 2x reserve (24), so it
  // emits offers on ~14 of 100 turns and never accumulates enough seller
  // credit to cross the regiment threshold, while gp5 — which hoards grain —
  // recovers. Dropping the safety buffer (keeping one consumption-cycle
  // reserve) lets the seller offer down to that floor each turn.
  // SPEC/ai/treasury-planner.md § Lock-recovery seller food-surplus release.
  final isLockRecoverySeller = lockRecoveryScan.isLockRecoverySeller(playerId);
  // Refs #2847 H8-supply (S7-D lumber re-localization): the supplier release
  // also activates when a peer lock-recovery seller is stuck one stage earlier —
  // at the level-0 `build_improvement` gate whose producible inputs the world
  // market cannot supply it. On seed 42 that binding input is `lumber` (market
  // supply is structurally thin), with `castIron` covered for the post-waiver
  // stage; [peerLockRecoverySellerNeededProducibleImprovementInputs] reports the
  // exact inputs a *peer* seller is short of, so activating the release here lets
  // an affluent supplier's over-produced `lumber` / `castIron` surplus reach the
  // locked seller before the seller ever reaches the regiment build-input
  // (fabric) stage. SPEC/ai/treasury-planner.md § Lock-recovery castIron
  // improvement-input supplier source.
  final regimentBuildInputMarketSupplyActive =
      lockRecoveryScan.anySellerNeedsRegimentBuildInput ||
      lockRecoveryScan.anySellerNeedsCastIronLabourPeasantRecruitFabric ||
      peerLockRecoverySellerNeededProducibleImprovementInputs(
        game,
        excludePlayerId: playerId,
      ).isNotEmpty;
  // Refs #2847 H8-extraction supply-side fix: releasing a *surplus* (stock held
  // above the GP's own consumption + production-input reserve) is selling, not
  // speculating, so the supplier role must not be gated on the supplier's own
  // treasury. On seed 42 the only GPs holding fabric / lumber / cast-iron
  // surplus (gp1 / gp2) spend their treasury on conquest and sit far below the
  // regiment-affordable band, so the prior `rawTreasury >= threshold` gate left
  // every lock-recovery seller bid (fabric, then the level-0 build_improvement
  // inputs) permanently unfilled — `gpRegimentInputDealsAsBuyer == 0` and
  // `gpFeedstockGateImprovementCostAffordableTurns == 0` across the whole run.
  // Releasing surplus regardless of the supplier's treasury still reserves the
  // supplier's own consumption + production inputs (only the extra safety buffer
  // drops to 0), so it cannot starve the supplier, while letting the needy
  // seller's bid match. SPEC/ai/treasury-planner.md
  // § Lock-recovery seller feedstock-improvement input bootstrap.
  final isRegimentBuildInputMarketSupplier =
      regimentBuildInputMarketSupplyActive && !isLockRecoverySeller;

  populateTreasurySurplusAndNeedMaps(
    TreasurySurplusNeedMapsInput(
      trackedCommodityIds: trackedIds,
      inputNeeds: inputNeeds,
      projected: projected,
      carryForwardOffers: carryForwardOffers,
      carryForwardBids: carryForwardBids,
      marketPrices: marketPrices,
      isLockRecoverySeller: isLockRecoverySeller,
      isRegimentBuildInputMarketSupplier: isRegimentBuildInputMarketSupplier,
      available: available,
      need: need,
    ),
  );

  // Refs #3122: treasury budget that bounds total bid notional this turn.
  // Mirrors the matcher-side per-buyer clamp introduced by #3115 so the
  // planner never emits a bid the matcher would have to truncate to zero.
  final pendingCosts = pendingTreasuryCostsForTurn(
    game,
    playerId,
    currentOrders,
  );
  final carryForwardBidNotional = carryForwardBidNotionalByPlayer(
    game: game,
    playerId: playerId,
    resourceRules: rules,
  );
  final treasuryBudgetForBidsRaw =
      rawTreasury - pendingCosts - carryForwardBidNotional;
  final treasuryBudgetForBids = treasuryBudgetForBidsRaw < 0
      ? 0
      : treasuryBudgetForBidsRaw;

  final treasuryForecast =
      treasury +
      expectedOfferInflow(
        available: available,
        marketPrices: marketPrices,
        state: game.worldMarketState,
      );
  // Refs #2924 F13/F16: lock-recovery tier alignment keys off actual treasury,
  // not the F8 offer-inflow forecast. An optimistic forecast must not downgrade
  // offers to the moderate tier while the GP still holds less than a regiment
  // build (seed-42 gp5 stalls at treasury 1999 when forecast >= 2000).
  final lockRecoveryUrgent = brokeForLockRecovery;
  final offerPriority = lockRecoveryUrgent || treasuryForecast < threshold
      ? kTreasuryOfferPriorityUrgent
      : kTreasuryOfferPriorityModerate;

  final isLiquidityBuyer = isLockRecoveryLiquidityBuyer(
    game: game,
    playerId: playerId,
    treasuryBudgetForBids: treasuryBudgetForBids,
    treasuryForecast: treasuryForecast,
    scan: lockRecoveryScan,
  );
  final isAffluentDesignatedBuyer = isAffluentDesignatedLockRecoveryBuyerInternal(
    game: game,
    playerId: playerId,
    scan: lockRecoveryScan,
  );

  // Refs #2924 F10: affluent GPs spend treasury on inventory ahead of strict
  // deficits so the world market clears. Gated by treasury affluence so broke
  // GPs never speculate; the F3 price gate is bypassed because the GP is
  // choosing to convert treasury into stockpile regardless of unit cost.
  // Suppressed for lock-recovery liquidity buyers (their single bid slot
  // is committed to the urgent grain liquidity bid below — F12).
  if (treasury >= treasuryAffluenceThreshold() &&
      !isLiquidityBuyer &&
      !isAffluentDesignatedBuyer &&
      !isLockRecoverySeller) {
    addSpeculativeBidNeeds(
      need: need,
      available: available,
      projected: projected,
      carryForwardBids: carryForwardBids,
      state: game.worldMarketState,
    );
  }

  // Refs #2924 F11/F12/F15: when broke GPs emit urgent offers (typically grain)
  // but bids land on other commodities or priority tiers, the matcher clears
  // zero deals. One rotating affluent GP per turn (F12) — or every GP that can
  // fund at least one liquidity-food unit when no GP is affluent (F15) — bids
  // the liquid food commodity at the same priority as urgent offers, capped by
  // treasury budget, and withholds that commodity from its offer set (mutual
  // exclusion). Other broke GPs sell only (F13).
  if (isLiquidityBuyer || isAffluentDesignatedBuyer) {
    applyLockRecoveryLiquidityBid(
      LockRecoveryLiquidityBidInput(
        game: game,
        need: need,
        available: available,
        treasuryBudgetForBids: treasuryBudgetForBids,
        addSyntheticBid: isLiquidityBuyer,
      ),
    );
    if (isLiquidityBuyer) {
      final liquidity = lockRecoveryLiquidityCommodity(game.worldMarketState);
      // Keep only the liquidity food bid so the single bidTypeCap slot is not
      // consumed by fabric/bronze deficits that cannot match urgent grain offers.
      need.removeWhere((id, _) => id != liquidity);
    }
  } else if (lockRecoveryUrgent || isLockRecoverySeller) {
    need.clear();
  }

  // Refs #2847 § H8: lock-recovery seller regiment build-input bootstrap bid +
  // feedstock reservation. SPEC/ai/treasury-planner.md
  // § Lock-recovery seller regiment build-input bootstrap.
  applyLockRecoverySellerRegimentRebuildBids(
    LockRecoverySellerRegimentRebuildBidsInput(
      isLockRecoverySeller: isLockRecoverySeller,
      rawTreasury: rawTreasury,
      threshold: threshold,
      game: game,
      playerId: playerId,
      projected: projected,
      carryForwardBids: carryForwardBids,
      need: need,
      available: available,
    ),
  );

  // Refs #3758 S7/R12: drop bids for commodities only sourceable from a colony
  // Tribe this GP is boycotted from. The deal matcher already refuses those
  // trades; suppressing the bid here keeps the capped bid slots
  // (`bidTypeCap`) for fillable commodities. Gated behind the existence of a
  // boycott targeting this GP and present tile maps (zero common-path cost),
  // deterministic for fixed inputs. SPEC/ai/treasury-planner.md
  // § Boycott-aware bid suppression.
  if (tileMapByRegion != null && need.isNotEmpty) {
    final blockedCommodityIds = boycottedColonySellableCommodityIds(
      game: game,
      buyerPlayerId: playerId,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
    );
    if (blockedCommodityIds.isNotEmpty) {
      need.removeWhere((id, _) => blockedCommodityIds.contains(id));
    }
  }

  if (available.isEmpty && need.isEmpty) {
    return null;
  }

  // Refs #3758 S9/R10: trade-deal relation-boost-aware bid preference. Resolve
  // the single bid commodity whose completed deal would earn the largest
  // trade-deal relation boost from a peace-time below-neutral partner, and pass
  // it as the `preferCommodityId` ordering hint so it is admitted first under
  // the caps. Skipped in every lock-recovery special state (those own the hint)
  // and a no-op when no qualifying partner holds a standing matching offer, so
  // common-path emission (and seed-42 tuning) is byte-identical. Deterministic.
  // SPEC/ai/treasury-planner.md § Trade-deal relation-boost-aware bid preference.
  final tradeDealPreferredBidCommodityId =
      (snapshot != null &&
          !isLiquidityBuyer &&
          !isAffluentDesignatedBuyer &&
          !isLockRecoverySeller &&
          !lockRecoveryUrgent)
      ? tradeDealRelationBoostPreferredBidCommodityId(
          game: game,
          playerId: playerId,
          snapshot: snapshot,
          need: need,
        )
      : null;

  // Refs #3758 file-split / #3967: offer/bid suggestion, supplier offer-tier
  // alignment, and treasury/cargo-clamped bid prioritization are assembled in
  // [emitTradeOrders] via [EmitTradeOrdersInput] so this planner body stays
  // within the function-size budget. Behaviour-preserving (same library scope,
  // identical emission path).
  return EmitTradeOrdersInput(
    game: game,
    playerId: playerId,
    bidTypeCap: bidTypeCap,
    tradeCargoCapacity: tradeCargoCapacity,
    available: available,
    need: need,
    treasuryBudgetForBids: treasuryBudgetForBids,
    offerPriority: offerPriority,
    isRegimentBuildInputMarketSupplier: isRegimentBuildInputMarketSupplier,
    isLiquidityBuyer: isLiquidityBuyer,
    lockRecoveryUrgent: lockRecoveryUrgent,
    rules: rules,
    tradeDealPreferredBidCommodityId: tradeDealPreferredBidCommodityId,
  );
}

