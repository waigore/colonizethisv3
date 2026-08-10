// Feedstock / castIron / fabric core diagnostic counters for S7-D rollup
// (Refs #2847 / #4239 Slice C, #4310 Slice A). Mixed into [Seed42S7dCampaignRollup].
library;

import 'package:colonizethis_data/colonizethis_data.dart';

/// H8 feedstock-stage core counters (castIron emission + fabric feedstock chain).
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
}
