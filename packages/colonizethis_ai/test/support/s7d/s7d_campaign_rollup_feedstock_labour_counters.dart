// CastIron / fabric labour and market-offer diagnostic counters (Refs #4310 Slice A).
library;

import 'package:colonizethis_data/colonizethis_data.dart';

import 's7d_campaign_rollup_feedstock_counters.dart';

/// Labour feasibility, peasant-recruit, and market-offer localization counters.
mixin Seed42S7dCampaignRollupFeedstockLabourCounters
    on Seed42S7dCampaignRollupFeedstockCounters {
  // Refs #2847 H8 castIron production-assignment localization (read-only).
  // The castIron recipe `castIron_from_iron` consumes only
  // `timber` + `iron` (no coal in `inputQuantities`), so it is materially
  // feasible whenever both feedstocks are on hand. This counter (built on
  // `stockpileAffordsAnyProductionRecipe`) splits a flat
  // `gpCastIronProductionAssignedTurns == 0` into "never materially
  // feasible" (a feedstock-supply gap) vs "feasible yet never assigned" (a
  // production-allocation / planner gate downstream of supply).
  late final castIronRecipeFeasibleTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 H8 castIron production-allocation localization (read-only;
  // S7-D castIron production-assignment, PR #3289 follow-up). The staging
  // path landed in #3289 still leaves `gpCastIronProductionAssignedTurns`
  // flat zero for every GP, including gp5 which is materially feasible for
  // ~53 turns (`gpCastIronRecipeFeasibleTurns`). Two read-only counters
  // split that flat residual on the material-feasible turns:
  //   * `castIronRecipeLabourFeasibleTurns` — the castIron recipe also
  //     clears the planner's own labour gate (`feasibleRuns(...) > 0`
  //     against the full `effectiveLabourForWorkers`, the same compute
  //     `economy_planner_labour.dart` § `allocateLabour` runs). A near-zero count
  //     here while `gpCastIronRecipeFeasibleTurns` is high localizes the
  //     break to **labour starvation** (effective labour, after mandatory
  //     food upkeep, cannot fund even one `labourPerOutput` run), moving the
  //     lever to effective-labour / food-reservation; a count close to the
  //     material-feasible count instead clears raw labour as the cause and
  //     re-points downstream to allocation competition / the staging gate.
  //   * `castIronFeasibleOwnsFeedstockTileTurns` — the seller still owns a
  //     `timber` / `iron` feedstock resource tile at any improvement level
  //     (the staging gate's `_ownsFeedstockResourceTile` precondition). A
  //     flat zero here while the seller *holds* `timber` / `iron`
  //     commodities localizes the unfired staging gate to **tile
  //     ownership** (feedstock accumulated but no resource tile owned),
  //     re-pointing the next behaviour slice to broaden the gate to fire on
  //     held feedstock; a non-zero count clears tile ownership as the cause.
  // Read-only; the (freely tunable) counts can move as later slices land.
  late final castIronRecipeLabourFeasibleTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final castIronFeasibleOwnsFeedstockTileTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 H8 castIron labour-starvation sub-cause split (read-only).
  // `gpCastIronRecipeLabourFeasibleTurns == 0` while
  // `gpCastIronRecipeFeasibleTurns` / `gpCastIronFeasibleOwnsFeedstockTile
  // Turns` are high decisively localized the binding constraint to
  // effective labour (the seller can never fund one `castIron`
  // `labourPerOutput` run after mandatory food upkeep). These two counters
  // fork *why* effective labour falls short on those material-feasible
  // turns so the next behaviour slice can pick the correct lever:
  //   * `castIronLabourFoodStarvedTurns` — the raw (food-ungated) labour
  //     ceiling (`playerRawLabourSupply`) **would** fund one run if every
  //     worker were fed, but `playerEffectiveLabour` does not: workers exist
  //     yet too few are food-fed. Lever: food supply / food-reservation.
  //   * `castIronLabourPopulationBoundTurns` — even the fully-fed ceiling is
  //     below one run's `labourPerOutput`: the seller simply lacks workers.
  //     Lever: worker growth / recruitment, not food.
  // Counted only on castIron material-feasible but labour-infeasible turns,
  // so the two are a partition of (recipeFeasible AND NOT labourFeasible).
  // Read-only; the (freely tunable) counts can move as later slices land.
  late final castIronLabourFoodStarvedTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final castIronLabourPopulationBoundTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 — peasant-recruit effectiveness localization for the
  // #3303 castIron-labour boost. #3303 wired an EXPAND orchestrator pass
  // that emits one peasant `RecruitWorkerOrder` whenever
  // `isCastIronLabourPopulationBoundForLockRecoverySeller` holds (the
  // lock-recovery seller is material-feasible for one castIron run yet its
  // raw population ceiling supplies < `labourPerOutput` labour). The S7-D
  // refresh after #3303 shows `gpCastIronRecipeLabourFeasibleTurns` is
  // STILL 0 for every GP, i.e. the boost never makes a castIron run
  // labour-feasible. These counters localize *why* by measuring, per GP:
  //   * `castIronLabourPeasantRecruitGateTurns` — turns the #3303 gate
  //     predicate itself holds (the boost's distinguishing condition);
  //   * `castIronLabourPeasantRecruitAffordableTurns` — of those, turns the
  //     seller can actually pay the peasant recruit cost row
  //     (`WorkerActionEconomyCatalog.peasant`, which costs 2 `fabric`);
  //   * `castIronLabourPeasantRecruitFabricStarvedTurns` — of those, turns
  //     it CANNOT (the suspected circular dependency: recruiting the
  //     peasant that would grow castIron labour itself needs `fabric`, the
  //     very downstream commodity the castIron chain exists to unblock).
  // If FabricStarved == GateTurns the #3303 boost is a structural no-op:
  // every gate-active turn it probes a peasant recruit the validator must
  // reject for want of fabric. Read-only; counts move freely as later
  // slices land.
  late final castIronLabourPeasantRecruitGateTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final castIronLabourPeasantRecruitAffordableTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final castIronLabourPeasantRecruitFabricStarvedTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 § S7-D market-fabric localization (post-#3317 re-point). Of
  // the fabric-starved peasant-recruit turns above, the subset where NO
  // other great power holds any `fabric` either — so the seller can
  // neither *produce* the 2-`fabric` recruit cost (the #3317
  // circular-labour deadlock: `fabric_from_*` needs 2 labour, the seller
  // has 1) NOR *buy* it from the world market. The peasant recruit is the
  // only raw-population-growth row in `WorkerActionEconomyCatalog`
  // (apprentice/journeyman/master consume an existing peasant), and it is
  // `fabric`-gated, so there is no non-`fabric` worker-action lever. When
  // this counter equals `castIronLabourPeasantRecruitFabricStarvedTurns`,
  // the market door is closed on every fabric-starved turn too, which
  // re-points the next slice off "find a non-`fabric` recruit row" (none
  // exists) and onto a rules-level bootstrap. Read-only; counts move
  // freely as later slices land.
  late final castIronLabourPeasantRecruitMarketFabricStarvedTurns =
      <String, int>{for (final gpId in gpIds) gpId: 0};
  // Refs #2847 § S7-D market-fabric offer/acquisition localization: the
  // complementary subset of the fabric-starved turns where other great
  // powers DO hold `fabric` (so this is not market-starved) yet none of it
  // is offerable — every holder is itself a below-quota zero-NW zero-
  // regiment lock-recovery seller withholding its `fabric` by the regiment-
  // rebuild offer-retention carve-out (`otherGreatPowerOfferableFabricHeld
  // <= 0` while `otherGreatPowerFabricHeld > 0`). A high count here forks
  // the residual onto the offer/retention layer (no counterparty offers
  // `fabric`); a low count with holdings present instead re-points it to the
  // starved seller's own buy/bid path. Read-only; counts move freely as
  // later slices land.
  late final castIronLabourPeasantRecruitMarketFabricUnofferedTurns =
      <String, int>{for (final gpId in gpIds) gpId: 0};
  // Refs #2847 § S7-D buyer-side fabric acquisition localization: on
  // fabric-starved peasant-recruit turns where offerable `fabric` exists
  // (`otherGreatPowerOfferableFabricHeld > 0`), whether the starved seller
  // emits a `fabric` bid and whether a deal fills as buyer. Read-only;
  // counts move freely as later slices land.
  late final castIronLabourPeasantRecruitFabricBidEmittedTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final castIronLabourPeasantRecruitFabricBidAbsentTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final castIronLabourPeasantRecruitFabricDealAsBuyerTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 § castIron market-supply wall: on feedstock-extraction
  // gate-active turns, whether any *other* faction offered `castIron` (the
  // manufactured level-0 `build_improvement` input) on the world market —
  // i.e. whether the seller's direct-acquisition branch had any supply to
  // bid against. A flat-zero present count across the run proves the
  // direct castIron purchase path is permanently closed (every GP consumes
  // its castIron for Old World military builds), leaving only the
  // labour-walled domestic run. Read-only; counts move freely as later
  // supply slices land.
  late final castIronMarketOfferPresentTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final castIronMarketOfferAbsentTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 § fabric offer-side split: on peasant-recruit fabric market
  // path-active turns, whether any *other* faction emitted a `fabric` sell
  // offer in trade orders (the trade-order emission layer between
  // offerable-holdings proxy and buyer-side bid/deal counters).
  late final fabricMarketOfferPresentTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final fabricMarketOfferAbsentTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Minimum `labourPerOutput` across the castIron recipes — the cheapest
  // single run's effective-labour requirement, used as the food-starved /
  // population-bound fork threshold above.
  late final castIronMinLabourPerOutput = castIronRecipes.isEmpty
      ? 0
      : castIronRecipes
            .map((recipe) => recipe.labourPerOutput)
            .reduce((a, b) => a < b ? a : b);
  // Food commodities (grain + meat) consumed by worker upkeep
  // (`economy_consumption.dart`), summed for the turn-99 food-on-hand
  // snapshot that corroborates the food-starved lever.
  late final castIronLabourFoodCommodityIds = <String>{
    CommodityCatalog.grain.id,
    CommodityCatalog.meat.id,
  };
}
