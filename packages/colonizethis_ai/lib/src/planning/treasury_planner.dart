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
import 'treasury_regiment_bootstrap_bids.dart';
import 'treasury_relation_boost_preference.dart';
import 'treasury_planner_emit_input.dart';
import 'treasury_planner_input.dart';

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
export 'treasury_planner_input.dart';
export 'treasury_regiment_bootstrap.dart' show kDomesticProductionImprovementInputIds;

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
