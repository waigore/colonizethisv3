// Feedstock / castIron / fabric / labour diagnostic counters for S7-D rollup
// (Refs #2847 / #4239 Slice C). Mixed into [Seed42S7dCampaignRollup].
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'supply_probes.dart';

/// H8 feedstock-stage and castIron-labour localization counters.
mixin Seed42S7dCampaignRollupFeedstockCounters {
  List<String> get gpIds;

  Map<String, int> get cheapestRegimentInputs;

  Map<String, int> zeroPerGpCounter(List<String> ids) => {for (final gpId in ids) gpId: 0};

  // Refs #2847 H8-extraction castIron residual localization (post-#3241).
  // The level-0 `build_improvement` material is `lumber + castIron`. #3241
  // makes a lock-recovery seller buy `lumber` directly and produce
  // `castIron` domestically from its production feedstock (timber + iron).
  // The affordability gate
  // (`gpFeedstockGateImprovementCostAffordableTurns`) requires BOTH inputs
  // on hand simultaneously, yet it stays flat zero. These read-only
  // counters split the castIron sub-chain so the next slice can target the
  // exact stage, in order:
  //   (a) the seller bids castIron's production feedstock at all
  //       (`gpCastIronFeedstockBidsEmitted`);
  //   (b) that feedstock is even *offered* on the world market
  //       (`gpCastIronFeedstockOffersEmitted` flat zero => no releasable
  //       supply — `timber` / `iron` are absent from the supplier release
  //       set, so the affluent GPs never offer them);
  //   (c) the bids *fill* (`gpCastIronFeedstockDealsAsBuyer`);
  //   (d) the economy planner ever runs the castIron recipe
  //       (`gpCastIronProductionAssignedTurns`); and
  //   (e) the resulting per-commodity holdings at turn 99
  //       (`gpLumberHeldAtTurn99` / `gpCastIronHeldAtTurn99`) — a non-zero
  //       lumber with zero castIron confirms the production-feedstock break.
  // Pure observation — no production logic changes — so the (freely
  // tunable) counts can move as later supply slices land.
  late final castIronRecipes = <ProductionRecipe>[
    for (final recipe in ProductionRecipesCatalog.all)
      if (recipe.outputCommodityId == 'castIron') recipe,
  ]..sort((a, b) => a.id.compareTo(b.id));
  late final castIronProductionRecipe = castIronRecipes.isEmpty
      ? null
      : castIronRecipes.first;
  late final castIronFeedstockIds = <String>{
    ...?castIronProductionRecipe?.inputQuantities.keys,
  };
  late final castIronRecipeIds = <String>{
    for (final recipe in castIronRecipes) recipe.id,
  };
  late final fabricRecipeIds = <String>{
    ProductionRecipesCatalog.fabricFromWool.id,
    ProductionRecipesCatalog.fabricFromCotton.id,
  };
  late final fabricProductionAssignedTurns = zeroPerGpCounter(gpIds);
  late final castIronFeedstockBidsEmitted = zeroPerGpCounter(gpIds);
  late final castIronFeedstockOffersEmitted = zeroPerGpCounter(gpIds);
  late final castIronFeedstockDealsAsBuyer = zeroPerGpCounter(gpIds);
  late final castIronProductionAssignedTurns = zeroPerGpCounter(gpIds);
  late final lumberHeldAtTurn99 = zeroPerGpCounter(gpIds);
  late final castIronHeldAtTurn99 = zeroPerGpCounter(gpIds);
  // Refs #2847 H8-extraction supplier feedstock: per-GP count of turns the
  // supplier-side castIron feedstock extraction gate is active
  // (`supplierImprovementInputFeedstockExtractionResourceIds` non-empty) —
  // i.e. the GP is a non-seller above the quota, a peer locked seller needs
  // the producible `castIron` improvement input, and the GP owns an
  // unimproved `timber` / `iron` tile to extract. A non-zero count for the
  // supplier GPs (gp1 / gp2) paired with a rising
  // `gpCastIronProductionAssignedTurns` confirms the supplier-extraction
  // slice closes the over-production feedstock gap; a flat-zero count for
  // gp1 / gp2 re-points the next slice (the suppliers own no unimproved
  // `timber` / `iron` tile to extract). Read-only; freely tunable.
  late final supplierFeedstockExtractionGateActiveTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 H8-extraction castIron co-availability localization
  // (post-#3247). #3247 reserves the multi-input `castIron` feedstock
  // (`timber` + `iron`) from competing single-input recipes so the
  // feedstock can co-accumulate for one run, yet
  // `gpCastIronProductionAssignedTurns` stays 0 for every GP and the
  // affluent supplier gp2 still converts its extracted `timber` to
  // `lumber`. The reservation cannot help if the supplier never has the
  // *other* feedstock (`iron`) to reserve in the first place. These two
  // counters decide the next slice's direction per feedstock commodity:
  //
  //   * `supplierActiveUnimprovedCastIronFeedstockTileTurns` — while the
  //     supplier feedstock-extraction gate is active, per-commodity count
  //     of turns the GP owns an *unimproved* tile of that castIron
  //     feedstock (a Builder target it could extract). A flat zero for
  //     `iron` on the supplier GPs (gp1 / gp2) means domestic `castIron`
  //     production is structurally impossible (no `iron` tile to extract),
  //     re-pointing the next slice to a market / requirement-relaxation
  //     path; a non-zero `iron` count means the Builder routing simply is
  //     not selecting the `iron` tile, re-pointing to a routing fix.
  //   * `castIronFeedstockHeldAtTurn99` — per-commodity feedstock stock at
  //     turn 99. Confirms which feedstock the supplier actually accumulates
  //     (`timber`) versus never holds (`iron`).
  //
  // Read-only scans; freely tunable diagnostic surface.
  late final supplierActiveUnimprovedCastIronFeedstockTileTurns =
      <String, Map<String, int>>{
        for (final gpId in gpIds)
          gpId: <String, int>{for (final id in castIronFeedstockIds) id: 0},
      };
  late final castIronFeedstockHeldAtTurn99 = <String, Map<String, int>>{
    for (final gpId in gpIds)
      gpId: <String, int>{for (final id in castIronFeedstockIds) id: 0},
  };
  // Refs #2847 H8-supply: domestic-production feedstock-stage isolation.
  // The post-#3235 surface shows the world market never supplies fabric
  // (`gpRegimentInputDealsAsBuyer == 0`) and the affluent-supplier release
  // path cannot help (the conquest GPs that might hold textile surplus sit
  // far below the regiment-affluence treasury band), so the only viable
  // fabric source for a locked seller is *domestic production* of the
  // wool / cotton feedstock the `fabricFrom*` recipes consume. These
  // read-only accumulators split that chain into its proximate links so a
  // tuning implementer can tell apart, in order:
  //   1. no Builder routing window — the feedstock-extraction gate
  //      ([regimentBuildInputFeedstockExtractionResourceIds]) never fires;
  //   2. no feedstock tile to improve — the GP owns no unimproved
  //      wool / cotton resource tile a Builder could extract;
  //   3. feedstock never reaches the stockpile — no wool / cotton on hand
  //      despite the gate / tile;
  //   4. feedstock present but not enough for a recipe run — no fabric
  //      recipe is feasible for >=1 run;
  // measured against the existing `gpCheapestRegimentInputsInStockpileTurns`
  // (fabric on hand) so the break point is unambiguous. Pure observation —
  // no production logic changes — so the (freely tunable) counts can move
  // as later supply slices land.
  late final fabricRecipes = <ProductionRecipe>[
    for (final recipe in ProductionRecipesCatalog.all)
      if (RegimentEconomyCatalog.peasantLevies.buildInputs
          .containsKey(recipe.outputCommodityId)) recipe,
  ];
  late final fabricFeedstockIds = <String>{
    for (final recipe in fabricRecipes) ...recipe.inputQuantities.keys,
  };
  late final feedstockExtractionGateActiveTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 § S7-D castIron-feedstock order-matching off-critical path
  // (read-only). Affluent suppliers now *offer* `timber` / `iron`
  // (`gpCastIronFeedstockOffersEmitted` non-zero — supplier feedstock
  // extraction landed), yet a below-quota zero-NW lock-recovery seller's
  // castIron-feedstock bids still fill 0 deals
  // (`gpCastIronFeedstockDealsAsBuyer == 0`, a `timber` / `iron` offer-tier
  // mismatch). This counter records the feedstock-extraction-gate-active
  // turns on which the seller's fully-fed raw labour ceiling is below the
  // castIron `labourPerOutput`, so even a *fully filled* feedstock bid could
  // not yield a labour-feasible domestic castIron run. A count equal to
  // `gpFeedstockExtractionGateActiveTurns` proves the order-matching gap is
  // **off the critical path** — closing it (offer-tier alignment / supplier
  // release) cannot move the gate while the seller stays population-bound —
  // and re-points the next behaviour lever to worker-population growth.
  // Generalises `gpCastIronLabourPopulationBoundTurns` (measured only on
  // castIron material-feasible turns, which gp3 never reaches) to the gate
  // turns where the seller is still bidding the feedstock. Read-only; the
  // (freely tunable) counts can move as later slices land.
  late final castIronFeedstockExtractionLabourFutileTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final unimprovedFeedstockTileOwnedTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final feedstockInStockpileTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final fabricRecipeFeasibleTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 § S7-D fabric circular-labour localization (read-only). The
  // #3303/#3315 castIron-labour peasant-recruit boost stages domestic
  // `fabric` so a lock-recovery seller can pay the 2-`fabric` peasant
  // recruit that would grow its castIron labour. The post-#3315 refresh
  // shows the recruit gate fires for gp5 (8 turns) yet is fabric-starved on
  // every one (`gpCastIronLabourPeasantRecruitAffordableTurns == 0`), while
  // `gpFabricRecipeFeasibleTurns` (material-only) is high (gp5 47) but
  // `gpFabricProductionAssignedTurns` is ~2. This counter splits the
  // material-feasible fabric turns by the planner's own labour gate
  // (`feasibleRuns(...) > 0` against full `effectiveLabourForWorkers`,
  // mirroring `gpCastIronRecipeLabourFeasibleTurns`). A near-zero count
  // while the material count is high localizes the unbuilt recruit-fabric
  // to **labour starvation of the fabric recipe itself** (`fabric_from_*`
  // carries `labourPerOutput == 2`, above the seller's effective labour of
  // 1), i.e. the recruit boost is a circular deadlock — the next lever must
  // grow raw population by a non-`fabric` path, not stage more domestic
  // fabric. Read-only; the (freely tunable) counts can move as later slices
  // land.
  late final fabricRecipeLabourFeasibleTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
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
  // Refs #2847 H8-extraction execution-gap disambiguation (read-only).
  // Both are gated on a feedstock-extraction-gate-active turn so they split
  // the 29-52 gate-active turns into the proximate failure stage:
  //   * `feedstockGateIdleBuilderPresentTurns` — a free Builder exists to
  //     route (rules out "no Builder available");
  //   * `feedstockGateImprovedTileOwnedTurns` — the routed Builder has
  //     actually finished improving a feedstock tile. Near-zero here with
  //     an idle Builder present and `gpUnimprovedFeedstockTileOwnedTurns`
  //     high => the improvement never completes (routing / preemption);
  //     high here with `gpFeedstockInStockpileTurns` near-zero => the
  //     improved tile is not extraction-connected (transport-cap stage).
  late final feedstockGateIdleBuilderPresentTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final feedstockGateImprovedTileOwnedTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 H8-extraction missing-candidate disambiguation (read-only).
  // Both are gated on a feedstock-extraction-gate-active turn and split the
  // "idle Builder present + unimproved feedstock tile owned, yet improvement
  // never completes" gap into its proximate cause:
  //   * `feedstockGateValidBuildImprovementCandidateTurns` — the work-order
  //     engine (`getValidWorkOrderTileKeys`, the same validator chain
  //     `suggestWorkOrders` runs) actually accepts a `build_improvement`
  //     candidate for an idle Builder on an owned unimproved feedstock tile.
  //     Near-zero here confirms the candidate is suppressed by the validator
  //     before any selection boost (#3234) applies; high here re-points the
  //     break downstream to selection / orchestrator / phase filtering.
  //   * `feedstockGateImprovementCostAffordableTurns` — the GP's stockpile
  //     can afford the level-0 `build_improvement` cost (1 lumber + 1 cast
  //     iron). Near-zero alongside a near-zero candidate count localizes the
  //     suppression to the validator material-cost gate (the lumber /
  //     cast-iron deadlock); high alongside a near-zero candidate count
  //     points instead at tile control / visibility / occupancy gates.
  late final feedstockGateValidBuildImprovementCandidateTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final feedstockGateImprovementCostAffordableTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 H8-extraction affordability localization: the level-0
  // `build_improvement` cost is purely material (1 lumber + 1 cast iron,
  // `work_order_costs.dart`) — no treasury or recipe gate. When the
  // combined `gpFeedstockGateImprovementCostAffordableTurns` stays flat at
  // zero, these per-component counters split it into its proximate
  // shortfall: how many gate-active turns the GP holds the `lumber` share
  // vs the `castIron` share. Pins the binding missing material during the
  // gate window (not just at the turn-99 snapshot) so the next slice can
  // target lumber supply, castIron supply, or both. Read-only.
  late final improvementLumberId = CommodityCatalog.lumber.id;
  late final improvementCastIronId = CommodityCatalog.castIron.id;
  late final feedstockGateImprovementLumberAffordableTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final feedstockGateImprovementCastIronAffordableTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 H8-extraction acquisition-thread localization (read-only).
  // Post-#3274 the seller feedstock-tile acquisition thread (declare-war
  // target bias #3273 + conquest army-move target bias #3274) drives a
  // flagged below-quota zero-NW lock-recovery seller toward the Old World
  // feedstock province it must conquer when it owns no extractable feedstock
  // tile of its own. These split *why* a flagged seller that still owns 0
  // improved feedstock tiles (e.g. gp3) never completes the acquisition into
  // its proximate stage:
  //   * `feedstockAcquisitionTargetActiveTurns` —
  //     `expandSellerFeedstockTileAcquisitionTarget(game, snap)` returns a
  //     non-null conquest-reachable Old World feedstock province this turn,
  //     so the acquisition thread engages. Zero here localizes the residual
  //     upstream of the declare-war / army-move bias to "no conquest-
  //     reachable feedstock target" (the needed feedstock province is never
  //     invadable) — the bias has nothing to redirect.
  //   * `feedstockAcquisitionTargetWithFieldArmyTurns` — subset of the above
  //     where the GP also owns at least one non-home field army able to
  //     execute the march. Near-zero here with a positive active count
  //     localizes the residual to "target reachable but no field army to
  //     march it" (peer-war regiment attrition); a high count alongside a
  //     flat `gpFeedstockGateImprovedTileOwnedTurns` re-points the break to
  //     march/capture completion downstream of the army-move bias. Both stay
  //     0 by construction for the +6 baseline GPs gp1/gp2 (never flagged, so
  //     the acquisition target is always null).
  late final feedstockAcquisitionTargetActiveTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final feedstockAcquisitionTargetWithFieldArmyTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
}
