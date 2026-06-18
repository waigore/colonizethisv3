// Treasury planner: World Market trade orders for AI GPs. SPEC/ai/treasury-planner.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show
        ExtractionTotals,
        GamePlayerLookup,
        ProvinceOwnerCache,
        cargoHoldsForHomeFleet,
        carryForwardBidNotionalByPlayer,
        effectiveMarketPriceForCommodityId,
        kRegionNewWorld,
        oldWorldProvinceCountOwnedBy,
        peerLockRecoverySellerNeededProducibleImprovementInputs,
        pendingTreasuryCostsForTurn,
        regimentBuildInputFeedstockImprovementInputCost,
        tradeCargoCapacityForGreatPower,
        worldMarketBidTypeCap;
import 'package:colonizethis_logic/order_suggestion_api.dart'
    show TradeOrderSuggester, TradeSuggestionContext;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'cast_iron_labour_gate.dart'
    show
        isCastIronLabourPeasantRecruitFabricMarketPathActive,
        isCastIronLabourPeasantRecruitFabricShort,
        isDomesticFabricProductionLabourInfeasible;
import 'recipe_scoring.dart' show kShortageThreshold;

// Treasury planner concern fragments (Refs #3288 file-split). Each `part of`
// fragment shares this library's imports and private scope, so the move is
// behaviour-preserving — symbols, visibility, and helper sharing are unchanged.
part 'treasury_need_analysis.dart';
part 'treasury_market_pricing.dart';
part 'treasury_lock_recovery.dart';
part 'treasury_regiment_bootstrap.dart';
part 'treasury_bid_emission.dart';

/// Bid priority tiers (1 = highest). Refs #2994 F4.
const int kTreasuryBidPriorityEssentialInput = 1;
const int kTreasuryBidPriorityLuxury = 2;
const int kTreasuryBidPriorityRawMaterial = 3;
const int kTreasuryBidPriorityFood = 4;

/// Default offer priority when treasury is comfortable.
const int kTreasuryOfferPriorityModerate = 5;

/// Aggressive sell priority when treasury is below the regiment threshold.
const int kTreasuryOfferPriorityUrgent = 2;

/// Multiplier on `cheapestRegimentBuildTreasuryCost()` that defines the
/// "affluent" treasury band where speculative bidding activates. The default
/// `1` means a GP that can afford at least the cheapest regiment build is
/// also allowed to spend a small marginal amount on inventory inputs so the
/// world market clears (Refs #2924 F10). A GP whose treasury is below the
/// regiment threshold cannot afford regiments **or** speculation; the
/// affluence gate keeps speculation off for those broke GPs.
/// SPEC/ai/treasury-planner.md § Affluent-GP speculative bidding.
const int kTreasuryAffluenceThresholdMultiplier = 1;

/// Target stockpile quantity per non-riches commodity the affluent
/// speculative-bid pass tries to lift the GP toward when no F1–F5 deficit
/// already covers that commodity. Aligned with [kShortageThreshold] so a
/// successful buy completes one full consumption cycle. Refs #2924 F10.
const int kSpeculativeBidStockpileTarget = kShortageThreshold;

/// Treasury band at which speculative bidding activates. Refs #2924 F10.
int treasuryAffluenceThreshold() =>
    kTreasuryAffluenceThresholdMultiplier *
        cheapestRegimentBuildTreasuryCost();

/// Returns trade orders for one AI-controlled GP after production planning.
///
/// Runs after [productionAssignments] are chosen in [runEconomyPlanner]. Uses
/// [TradeOrderSuggester] with treasury-aware surplus/need maps and per-commodity
/// bid priorities. Refs #2994 F1–F5, F8 (carry-forward de-duplication and
/// prior-fill-rate-aware offer urgency, see SPEC/ai/treasury-planner.md
/// § Partial-fill-aware forecasting).
List<TradeOrder> runTreasuryPlanner({
  required Game game,
  required String playerId,
  required Stockpile stockpile,
  required List<AssignedRecipe> productionAssignments,
  required int treasury,
  AIWorldSnapshot? snapshot,
  Map<String, TileMapResult>? tileMapByRegion,
  MapTopology? topology,
  Orders currentOrders = const Orders(),
  ResourceRules? resourceRules,
  Map<String, ExtractionTotals>? extractionById,
}) {
  final ResourceRules rules = resourceRules ?? ResourceRules.defaultRules;
  final bidTypeCap = worldMarketBidTypeCap(game, playerId);
  final tradeCargoCapacity = _resolveTradeCargoCapacity(
    game: game,
    playerId: playerId,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
    extractionById: extractionById,
  );

  final projected = _projectStockpileAfterProduction(
    stockpile: stockpile,
    productionAssignments: productionAssignments,
  );
  final inputNeeds = _inputNeedsFromAssignments(productionAssignments);
  final trackedCommodityIds = _trackedCommodityIds(
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
  final carryForwardOffers = _carryForwardQuantitiesByCommodity(
    state: game.worldMarketState,
    playerId: playerId,
    side: TradeOrderType.offer,
  );
  final carryForwardBids = _carryForwardQuantitiesByCommodity(
    state: game.worldMarketState,
    playerId: playerId,
    side: TradeOrderType.bid,
  );

  final rawTreasury = treasury < 0 ? 0 : treasury;
  final threshold = cheapestRegimentBuildTreasuryCost();
  final brokeForLockRecovery = rawTreasury < threshold;
  final lockRecoveryScan = _LockRecoveryGameScan.fromGame(
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

  _populateTreasurySurplusAndNeedMaps(
    trackedCommodityIds: trackedCommodityIds,
    inputNeeds: inputNeeds,
    projected: projected,
    carryForwardOffers: carryForwardOffers,
    carryForwardBids: carryForwardBids,
    marketPrices: marketPrices,
    isLockRecoverySeller: isLockRecoverySeller,
    isRegimentBuildInputMarketSupplier: isRegimentBuildInputMarketSupplier,
    available: available,
    need: need,
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
  final treasuryBudgetForBids =
      treasuryBudgetForBidsRaw < 0 ? 0 : treasuryBudgetForBidsRaw;

  final treasuryForecast = treasury +
      _expectedOfferInflow(
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
  final isAffluentDesignatedBuyer = _isAffluentDesignatedLockRecoveryBuyer(
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
    _addSpeculativeBidNeeds(
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
    _applyLockRecoveryLiquidityBid(
      playerId: playerId,
      game: game,
      need: need,
      available: available,
      carryForwardBids: carryForwardBids,
      treasuryBudgetForBids: treasuryBudgetForBids,
      treasuryForecast: treasuryForecast,
      addSyntheticBid: isLiquidityBuyer,
    );
    if (isLiquidityBuyer) {
      final liquidity = _lockRecoveryLiquidityCommodity(game.worldMarketState);
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
  _applyLockRecoverySellerRegimentRebuildBids(
    isLockRecoverySeller: isLockRecoverySeller,
    rawTreasury: rawTreasury,
    threshold: threshold,
    game: game,
    playerId: playerId,
    projected: projected,
    carryForwardBids: carryForwardBids,
    need: need,
    available: available,
  );

  if (available.isEmpty && need.isEmpty) {
    return const <TradeOrder>[];
  }

  // Refs #3122 + #3127: pass the treasury-budget-aware bid cap (computed above
  // — `rawTreasury - pendingCosts - carryForwardBidNotional`, floored at 0)
  // into the suggester so it never emits bids the validator rule 5 would
  // reject. Subsumes #3127's bare `max(0, treasury)` formulation.
  final suggestion = TradeOrderSuggester.suggest(
    TradeSuggestionContext(
      playerId: playerId,
      bidTypeCap: bidTypeCap,
      tradeCargoCapacity: tradeCargoCapacity,
      availableStockpileByCommodityId: available,
      commodityNeedByCommodityId: need,
      treasuryBudgetForBids: treasuryBudgetForBids,
      worldMarketState: game.worldMarketState,
      offerPriority: offerPriority,
      bidPriority: kTreasuryBidPriorityRawMaterial,
    ),
  );

  // Refs #2847 H8-supply market order matching: a lock-recovery supplier
  // releases its surplus at the GP's general `offerPriority` (the urgent tier
  // when broke, the moderate tier otherwise), but the locked buyer bids the
  // build inputs at `_bidPriorityForCommodity` (essential = 1 for the
  // manufactured `lumber` / `castIron` / `fabric` inputs) once it has recovered
  // above the regiment threshold. The DealMatcher crosses offers and bids only
  // **within** the same integer priority tier
  // (SPEC/program/world-market-resolution.md § Step C), so a standing
  // build-input offer and the buyer's standing build-input bid never pair --
  // confirmed on seed 42: a priority-2 `lumber` offer and a priority-1 `lumber`
  // bid coexist every turn yet `filledQuantity == 0`. Re-tag the supplier's
  // build-input supply offers to the same per-commodity tier the buyer bids at
  // so the two cross. Mirrors the bid-side `alignBidPriorityWithUrgentOffers`
  // tier-alignment machinery (Refs #2924 F12/F16).
  // SPEC/ai/treasury-planner.md § Supplier offer-tier alignment.
  final offers = isRegimentBuildInputMarketSupplier
      ? _alignBuildInputSupplyOfferTiers(suggestion.offers)
      : suggestion.offers;
  // Refs #2924 F11/F12: when the designated buyer is affluent its own forecast
  // is above the regiment threshold (offerPriority == moderate); the lock-
  // recovery bid still needs to clear at the urgent integer priority tier so
  // it matches broke GPs' urgent grain offers. forceBidPriority overrides the
  // tier-alignment computation so the synthetic grain bid always goes out at
  // kTreasuryOfferPriorityUrgent regardless of the buyer's own offerPriority.
  final bids = _prioritizedBids(
    rawBids: suggestion.bids,
    need: need,
    bidTypeCap: bidTypeCap,
    tradeCargoCapacity: tradeCargoCapacity,
    offerPriority: offerPriority,
    alignBidPriorityWithUrgentOffers: isLiquidityBuyer || lockRecoveryUrgent,
    forceBidPriority:
        isLiquidityBuyer ? kTreasuryOfferPriorityUrgent : null,
    preferCommodityId: isLiquidityBuyer
        ? _lockRecoveryLiquidityCommodity(game.worldMarketState)
        : null,
    treasuryBudgetForBids: treasuryBudgetForBids,
    worldMarketState: game.worldMarketState,
    resourceRules: rules,
  );

  return [...offers, ...bids];
}

/// Resolves this GP's per-turn trade cargo capacity. Uses the tile-map-aware
/// [tradeCargoCapacityForGreatPower] when a tile map and topology are present;
/// otherwise falls back to the home-fleet cargo holds (floored at 0).
int _resolveTradeCargoCapacity({
  required Game game,
  required String playerId,
  required Map<String, TileMapResult>? tileMapByRegion,
  required MapTopology? topology,
  Map<String, ExtractionTotals>? extractionById,
}) {
  if (tileMapByRegion != null && tileMapByRegion.isNotEmpty && topology != null) {
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
void _applyLockRecoverySellerRegimentRebuildBids({
  required bool isLockRecoverySeller,
  required int rawTreasury,
  required int threshold,
  required Game game,
  required String playerId,
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required Map<CommodityId, int> need,
  required Map<CommodityId, int> available,
}) {
  if (!isLockRecoverySeller) {
    return;
  }
  final zeroRegimentRebuildPath = regimentCountForPlayer(game, playerId) == 0;
  // Refs #2847 § castIron-labour peasant-recruit fabric staging: the recruit
  // row costs 2 `fabric` while the regiment build input needs only 1, so a
  // seller holding one unit clears the regiment missing-input check yet still
  // cannot pay the recruit — wool / cotton feedstock must stay reserved until
  // `fabric >= 2` when the population-bound castIron labour path is active.
  final peasantRecruitFabricStaging =
      isCastIronLabourPeasantRecruitFabricMarketPathActive(
        game: game,
        playerId: playerId,
        projected: projected,
      );
  final castIronLabourPeasantRecruitMarketPath = peasantRecruitFabricStaging;
  if (!zeroRegimentRebuildPath && !castIronLabourPeasantRecruitMarketPath) {
    return;
  }
  // Refs #2847 § H8 production allocation: offer-side input staging is
  // **treasury-independent**. The economy planner now produces the cheapest
  // regiment's build input (`fabric`) and its recipe feedstock ahead of
  // treasury recovery (economy-planner.md § Regiment build-input production
  // priority), so the offer side must retain that staged input even while the
  // seller is still broke — otherwise the strong-cargo Path-F seller sells the
  // freshly produced `fabric` (and its `wool` / `cotton` feedstock) back into
  // the world market every turn and it never accumulates to the
  // `peasant_levies` build cost, leaving the seller trapped at zero regiments.
  // Both reservations only suppress surplus offers (no order is added, no
  // treasury is spent), are scoped to the below-quota zero-NW zero-regiment
  // band, and self-clear the turn a regiment lands (enclosing guard) or the
  // build input is on hand (feedstock self-clear), so the +6 OW baseline GPs
  // (gp1 / gp2) are never affected. SPEC/ai/treasury-planner.md
  // § Produced build-input retention + § Build-input feedstock reservation.
  if (zeroRegimentRebuildPath || castIronLabourPeasantRecruitMarketPath) {
    for (final buildInputId
        in RegimentEconomyCatalog.peasantLevies.buildInputs.keys) {
      available.remove(buildInputId);
    }
    for (final feedstockId in _regimentBuildInputFeedstockIds(
      projected,
      peasantRecruitFabricStaging: peasantRecruitFabricStaging,
    )) {
      available.remove(feedstockId);
    }
  }
  // Refs #2847 § H8 bootstrap bids: market bids spend treasury (the buyer's
  // notional is debited on a match), so the build-input / feedstock / direct
  // bid arms below require a **recovered** treasury. A still-broke seller stays
  // offers-only (minus the staged input reservations above) until it crosses
  // the regiment cost. SPEC/ai/treasury-planner.md § Lock-recovery seller
  // regiment build-input bootstrap.
  if (rawTreasury < threshold) {
    return;
  }
  if (castIronLabourPeasantRecruitMarketPath &&
      isDomesticFabricProductionLabourInfeasible(
        game: game,
        playerId: playerId,
      )) {
    // Domestic `fabric_from_*` is material-feasible yet labour-walled
    // (`labourPerOutput == 2` > effective labour). Feedstock bids cannot unblock
    // the peasant recruit — buy finished `fabric` from affluent suppliers instead
    // (Refs #2847 § labour-infeasible fabric market path).
    _addRegimentBuildInputDirectNeed(
      projected: projected,
      carryForwardBids: carryForwardBids,
      need: need,
      peasantRecruitFabricStaging: true,
    );
    return;
  }
  if (!zeroRegimentRebuildPath) {
    // Peasant-recruit fabric path with labour-feasible domestic conversion:
    // feedstock / direct bids only (no zero-regiment improvement-input chain).
    final feedstockStillMissing = _addRegimentBuildInputFeedstockBootstrapNeed(
      feedstockCandidates: _sortedRegimentBuildInputFeedstockIds(
        projected,
        peasantRecruitFabricStaging: peasantRecruitFabricStaging,
      ),
      projected: projected,
      carryForwardBids: carryForwardBids,
      need: need,
      peasantRecruitFabricStaging: peasantRecruitFabricStaging,
    );
    if (!feedstockStillMissing) {
      _addRegimentBuildInputDirectNeed(
        projected: projected,
        carryForwardBids: carryForwardBids,
        need: need,
        peasantRecruitFabricStaging: peasantRecruitFabricStaging,
      );
    }
    return;
  }
  // Refs #2847 H8-extraction: improvement-input prerequisite. The seller's
  // routed Builder cannot extract its owned feedstock tile until it holds the
  // level-0 `build_improvement` material (lumber + cast iron) it has zero of —
  // a lumber / cast-iron deadlock with no domestic escape. Bid for those
  // improvement inputs first and suppress the downstream feedstock / fabric
  // bootstrap bids while any improvement-input deficit remains, so the single
  // bid slot targets the prerequisite supply. Self-clears once the inputs land
  // (or the tile is improved / a regiment is owned).
  if (_addRegimentFeedstockImprovementInputNeed(
    game: game,
    playerId: playerId,
    projected: projected,
    carryForwardBids: carryForwardBids,
    need: need,
  )) {
    return;
  }
  final feedstockStillMissing = _addRegimentBuildInputFeedstockBootstrapNeed(
    feedstockCandidates: _sortedRegimentBuildInputFeedstockIds(
      projected,
      peasantRecruitFabricStaging: peasantRecruitFabricStaging,
    ),
    projected: projected,
    carryForwardBids: carryForwardBids,
    need: need,
    peasantRecruitFabricStaging: peasantRecruitFabricStaging,
  );
  if (!feedstockStillMissing) {
    _addRegimentBuildInputDirectNeed(
      projected: projected,
      carryForwardBids: carryForwardBids,
      need: need,
      peasantRecruitFabricStaging: peasantRecruitFabricStaging,
    );
  }
}
