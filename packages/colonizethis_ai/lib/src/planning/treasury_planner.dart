// Treasury planner: World Market trade orders for AI GPs. SPEC/ai/treasury-planner.md.

import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/ai_api.dart'
    show
        ExtractionTotals,
        boycottedColonySellableCommodityIds,
        cargoHoldsForHomeFleet,
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
import 'treasury_regiment_bootstrap.dart';
import 'treasury_relation_boost_preference.dart';

export 'treasury_lock_recovery.dart'
    show
        anyLockRecoverySellerNeedsCastIronImprovementInput,
        isBelowQuotaZeroNwLockRecoverySeller,
        isFabricOfferRetainingLockRecoverySeller,
        isLockRecoveryLiquidityBuyer,
        kLockRecoveryPreferredBuyerIds,
        lockRecoveryDesignatedBuyerId,
        lockRecoveryFallbackBuyerId,
        otherGreatPowerOfferableFabricHeld;
export 'treasury_planner_constants.dart';
export 'treasury_regiment_bootstrap.dart' show kDomesticProductionImprovementInputIds;

/// Bundles inputs for [runTreasuryPlanner] (Refs #3972 AC5).
final class TreasuryPlannerInput {
  const TreasuryPlannerInput({
    required this.game,
    required this.playerId,
    required this.stockpile,
    required this.productionAssignments,
    required this.treasury,
    this.snapshot,
    this.tileMapByRegion,
    this.topology,
    this.currentOrders = const Orders(),
    this.resourceRules,
    this.extractionById,
  });

  final Game game;
  final String playerId;
  final Stockpile stockpile;
  final List<AssignedRecipe> productionAssignments;
  final int treasury;
  final AIWorldSnapshot? snapshot;
  final Map<String, TileMapResult>? tileMapByRegion;
  final MapTopology? topology;
  final Orders currentOrders;
  final ResourceRules? resourceRules;
  final Map<String, ExtractionTotals>? extractionById;
}

/// Returns trade orders for one AI-controlled GP after production planning.
///
/// Runs after [productionAssignments] are chosen in [runEconomyPlanner]. Uses
/// [TradeOrderSuggester] with treasury-aware surplus/need maps and per-commodity
/// bid priorities. Refs #2994 F1–F5, F8 (carry-forward de-duplication and
/// prior-fill-rate-aware offer urgency, see SPEC/ai/treasury-planner.md
/// § Partial-fill-aware forecasting).
List<TradeOrder> runTreasuryPlanner(TreasuryPlannerInput input) {
  final emitInput = buildEmitTradeOrdersInput(input);
  if (emitInput == null) {
    return const <TradeOrder>[];
  }
  return emitTradeOrders(emitInput);
}

/// Assembles surplus/need maps and emission inputs for [runTreasuryPlanner]
/// (Refs #3977 AC6). Returns `null` when both offer and bid maps are empty.
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

/// Resolves this GP's per-turn trade cargo capacity. Uses the tile-map-aware
/// [tradeCargoCapacityForGreatPower] when a tile map and topology are present;
/// otherwise falls back to the home-fleet cargo holds (floored at 0).
int resolveTradeCargoCapacity({
  required Game game,
  required String playerId,
  required Map<String, TileMapResult>? tileMapByRegion,
  required MapTopology? topology,
  Map<String, ExtractionTotals>? extractionById,
}) {
  if (tileMapByRegion != null &&
      tileMapByRegion.isNotEmpty &&
      topology != null) {
    return tradeCargoCapacityForGreatPower(
      game: game,
      playerId: playerId,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      extractionById: extractionById,
    );
  }
  final homeFleetHolds = cargoHoldsForHomeFleet(game, playerId);
  return homeFleetHolds < 0 ? 0 : homeFleetHolds;
}

/// Refs #2847 § H8: a below-quota zero-NW lock-recovery seller accumulates
/// treasury by selling food, but its bid `need` is cleared every turn (it is
/// a sell-only Path-F seller), so it can never buy the cheapest regiment's
/// build-input commodity. `peasant_levies` (the universal cheapest regiment,
/// cost `cheapestRegimentBuildTreasuryCost()`) requires its `buildInputs`
/// commodities in the stockpile; with zero of them on hand
/// `suggestBuildOrders` returns no regiment candidate even when treasury is
/// affordable and a peasant is free, so the seller that has *already* recovered
/// treasury to/above the regiment threshold stays trapped at zero regiments
/// (seed-42 gp5/gp6 hold treasury >= threshold yet 0 fabric for tens of turns).
/// Inject a single build-input bid so the recovered treasury converts into the
/// army the lock-recovery sell-down existed to fund. The carve-out fires only
/// while the GP holds zero regiments and is missing a build input, and clears
/// automatically once it owns a regiment or the input lands.
///
/// Refs #2847 § H8-supply: the bootstrap bid cannot fill when no world-market
/// seller offers the build input (seed-42 `fabric` has zero GP / minor / tribe
/// supply), so the recovered seller must *produce* the input domestically. The
/// economy planner already boosts feasible recipes that output a missing build
/// input (economy-planner.md § Regiment build-input production priority), but
/// those recipes only become feasible once their feedstock (e.g. `wool` /
/// `cotton` for `fabric`) reaches the per-run input requirement in the
/// stockpile. A lock-recovery seller otherwise sells that feedstock as surplus
/// every turn, so it never accumulates to a feasible run. Withhold the feedstock
/// from the offer set while the rebuild carve-out is active so it accumulates;
/// the reservation self-clears once the build input lands or the GP owns a
/// regiment. SPEC/ai/treasury-planner.md
/// § Lock-recovery seller regiment build-input bootstrap +
/// § Lock-recovery seller build-input feedstock reservation.
