import 'dart:convert';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show isCastIronLabourPeasantRecruitFabricMarketPathActive;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show
        cheapestRegimentBuildTreasuryCost,
        expandSellerFeedstockTileAcquisitionTarget;
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart'
    show
        hasIdleExplorerUnit,
        ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile,
        ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile,
        ownsProspectedOldWorldMineralFeedstockTile,
        colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates,
        suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show
        regimentBuildInputFeedstockExtractionResourceIds,
        supplierImprovementInputFeedstockExtractionResourceIds;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/seed42_observer_campaign.dart';
import 'support/seed42_s7d_feedstock_helpers.dart';
import 'support/s7d/diagnostic_json.dart';

/// Seed-42 turn-100 EXPAND-arm S7-D diagnostic (Refs #2847 / #3967).
///
/// Historical findings live in `support/s7d/s7d_diagnostic_findings.dart`.
/// Probe helpers live under `support/s7d/`. This file owns the campaign
/// runner, rollup JSON emission, and structural invariant assertion.
///
/// Skip: long-running (~4 min). Re-run with `dart test --run-skipped`.

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 100 S7-D diagnostic: per-GP EXPAND arm decision trace',
    () {
      final gpIds = [for (var i = 1; i <= 6; i++) 'gp$i'];
      Map<String, int> zeroPerGp() => {for (final gpId in gpIds) gpId: 0};

      // Per-GP rollups; populated as the simulation advances.
      final phaseCounts = <String, Map<ObserverGoalPhase, int>>{
        for (final gpId in gpIds)
          gpId: <ObserverGoalPhase, int>{
            for (final ph in ObserverGoalPhase.values) ph: 0,
          },
      };
      final declareWarPicks = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final peaceTargetPicks = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final economyArmCounts = <String, Map<String, int>>{
        for (final gpId in gpIds)
          gpId: <String, int>{
            'forceCheapestRegimentBuild': 0,
            'boostTreasuryRecoveryCargo': 0,
          },
      };
      final invadableEmptyTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final atWarTurnsByPeer = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final treasuryUnderCheapestTurns = zeroPerGp();
      final lastSnapshotFields = <String, Map<String, Object?>>{};

      // Refs #2847 regiment-accumulation surface (post-#2924 / World
      // Market merge). Treasury starvation is no longer the dominant
      // EXPAND-lock blocker for the failing GPs; the new question is
      // whether the standing regiment count actually grows once the GP
      // can afford a build. These per-GP rollups capture the regiment
      // trajectory (peak / turns at zero / turns at-or-above the cheapest
      // build cost) and the number of military `BuildUnitOrder`s the AI
      // actually emits each turn, so a future tuning implementer can tell
      // apart "the build order is never emitted/accepted" from "regiments
      // are built but immediately lost in the peer-war zero-sum churn".
      final regimentPeak = <String, int>{for (final gpId in gpIds) gpId: 0};
      final regimentTurnsAtZero = zeroPerGp();
      final treasuryAtOrAboveCheapestTurns = zeroPerGp();
      final militaryBuildOrdersEmitted = zeroPerGp();

      // Refs #2847 H8 conversion-gap isolation. The headline H8 finding is
      // that `forceCheapestRegimentBuild` fires 85-100 turns while
      // `gpMilitaryBuildOrdersEmitted` stays at 2-4 and `gpRegimentTurnsAtZero`
      // is 39-59 for gp3 / gp5 / gp6. These accumulators split the gap into
      // its proximate sub-causes so a tuning implementer can tell apart
      // "the cheapest-regiment input (fabric) is never in the stockpile when
      // the GP is ready to build" (production / market-acquisition gap) from
      // "fabric is present and the GP is ready, yet no military build is
      // emitted" (a downstream suggestion / build-pick gate). A turn counts
      // as *rebuild-ready* when the EXPAND directive is active, treasury can
      // afford the cheapest regiment, and the GP holds zero regiments — the
      // exact condition under which the lost starting army should be
      // replaced. The cheapest regiment (`peasant_levies`) requires a single
      // unit of fabric, so fabric availability is the proximate input gate.
      final cheapestRegimentInputs =
          RegimentEconomyCatalog.peasantLevies.buildInputs;
      final fabricInStockpileTurns = zeroPerGp();
      final rebuildReadyTurns = zeroPerGp();
      final rebuildReadyNoBuildTurns = zeroPerGp();
      final rebuildReadyNoBuildMissingInputTurns = zeroPerGp();
      final rebuildReadyNoBuildInputsPresentTurns = zeroPerGp();
      // Cheapest-regiment input commodity ids (e.g. fabric) and the bid /
      // fill counters that prove whether the #3226 lock-recovery build-input
      // bid carve-out actually secures the input from the world market. A
      // high bid count with a near-zero fill count localizes the gap to
      // world-market *supply* (no seller / no production feedstock) rather
      // than the planner failing to bid.
      final regimentInputCommodityIds = cheapestRegimentInputs.keys.toSet();
      final regimentInputBidsEmitted = zeroPerGp();
      final regimentInputDealsAsBuyer = zeroPerGp();

      // Refs #2847 H8-extraction supply-side localization. The level-0
      // `build_improvement` material (lumber + cast iron) is the prerequisite a
      // locked seller's routed Builder needs but cannot afford
      // (`gpFeedstockGateImprovementCostAffordableTurns == 0`). The
      // improvement-input bid carve-out and the treasury-independent supplier
      // release set both target these commodities, yet the seller never ends up
      // holding them. These counters split that supply gap into its proximate
      // links so a tuning implementer can tell apart, in order: (a) no GP / tribe
      // *offers* the inputs at all (`gpImprovementInputOffersEmitted` flat zero =>
      // nobody holds a releasable surplus); (b) offers exist but the seller's bid
      // never *fills* (`gpImprovementInputDealsAsBuyer` flat zero alongside
      // non-zero offers => price / priority / bid-cap matching gap); or (c) deals
      // fill but the input is consumed before the gate observes it
      // (`gpImprovementInputHeldAtTurn99` zero alongside non-zero buyer deals).
      // Read-only; the (freely tunable) counts can move as later supply slices
      // land.
      final improvementInputCommodityIds = workOrderCostBuildImprovement(
        0,
      ).keys.toSet();
      final improvementInputOffersEmitted = zeroPerGpCounter(gpIds);
      final improvementInputBidsEmitted = zeroPerGpCounter(gpIds);
      final improvementInputDealsAsBuyer = zeroPerGpCounter(gpIds);
      final improvementInputHeldAtTurn99 = zeroPerGpCounter(gpIds);

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
      final castIronRecipes = <ProductionRecipe>[
        for (final recipe in ProductionRecipesCatalog.all)
          if (recipe.outputCommodityId == 'castIron') recipe,
      ]..sort((a, b) => a.id.compareTo(b.id));
      final castIronProductionRecipe = castIronRecipes.isEmpty
          ? null
          : castIronRecipes.first;
      final castIronFeedstockIds = <String>{
        ...?castIronProductionRecipe?.inputQuantities.keys,
      };
      final castIronRecipeIds = <String>{
        for (final recipe in castIronRecipes) recipe.id,
      };
      final fabricRecipeIds = <String>{
        ProductionRecipesCatalog.fabricFromWool.id,
        ProductionRecipesCatalog.fabricFromCotton.id,
      };
      final fabricProductionAssignedTurns = zeroPerGpCounter(gpIds);
      final castIronFeedstockBidsEmitted = zeroPerGpCounter(gpIds);
      final castIronFeedstockOffersEmitted = zeroPerGpCounter(gpIds);
      final castIronFeedstockDealsAsBuyer = zeroPerGpCounter(gpIds);
      final castIronProductionAssignedTurns = zeroPerGpCounter(gpIds);
      final lumberHeldAtTurn99 = zeroPerGpCounter(gpIds);
      final castIronHeldAtTurn99 = zeroPerGpCounter(gpIds);
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
      final supplierFeedstockExtractionGateActiveTurns = <String, int>{
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
      final supplierActiveUnimprovedCastIronFeedstockTileTurns =
          <String, Map<String, int>>{
            for (final gpId in gpIds)
              gpId: <String, int>{for (final id in castIronFeedstockIds) id: 0},
          };
      final castIronFeedstockHeldAtTurn99 = <String, Map<String, int>>{
        for (final gpId in gpIds)
          gpId: <String, int>{for (final id in castIronFeedstockIds) id: 0},
      };

      // Refs #2847 H8-extraction Old World mineral feedstock prospect
      // localization (post-#3257 reservation). The reservation holds back an
      // idle Builder/Explorer for Old World feedstock work, yet
      // `gpCastIronFeedstockHeldAtTurn99` still shows `iron == 0` for every
      // supplier (`iron` is never extracted) while surface `timber` is. A
      // mineral `build_improvement` is rejected until the tile is prospected
      // (`work_order_target_prechecks.dart`), and only an **idle** Explorer is
      // reservable, so these two counters split the residual `iron` break,
      // captured while the supplier castIron gate is active:
      //
      //   * `supplierIdleExplorerPresentTurns` — the supplier owns an idle
      //     Explorer this turn (a unit the reservation could route onto the
      //     `iron` prospect). A near-zero count localizes the break to
      //     **Explorer availability** (all Explorers busy / dispatched to
      //     multi-turn New World exploration, so the reservation never has an
      //     idle Explorer to hold).
      //   * `supplierProspectedMineralFeedstockTileTurns` — the supplier owns a
      //     **prospected** Old World `iron` mineral feedstock tile. A non-zero
      //     count alongside `iron` held == 0 instead localizes the break
      //     **downstream** of prospecting (the Builder never improves the
      //     prospected tile / cannot afford the improvement); a flat zero
      //     confirms the prospect itself never happens.
      //   * `supplierIdleExplorerColocatedFeedstockTileTurns` — the supplier
      //     owns an idle Explorer standing **in the same province** as an
      //     unprospected Old World `iron` mineral feedstock tile. `prospect`
      //     candidate generation only reaches an Explorer positioned on (or
      //     single-hop from) the feedstock province, and the reservation holds
      //     the lexicographically-smallest idle Explorer **without
      //     repositioning it**. A flat zero alongside
      //     `supplierIdleExplorerPresentTurns > 0` localizes the residual to
      //     reservation **positioning** (no idle Explorer ever reaches the
      //     feedstock province, so no `prospect` candidate generates); a
      //     non-zero count instead points at candidate-generation eligibility
      //     (mineral-tile gate / validator) or selection ranking for an
      //     already-positioned Explorer.
      //   * `supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns` —
      //     the supplier owns an idle Explorer co-located with an unprospected
      //     Old World `iron` mineral feedstock tile that **also** passes the
      //     live mineral-eligibility terrain check (`isMineralEligibleTile`
      //     under the seed-42 `tileMapByRegion`). This is the next gate the
      //     `prospect` candidate must clear in
      //     `_allAcceptedProspectTilesInProvince`. Comparing it against
      //     `supplierIdleExplorerColocatedFeedstockTileTurns` splits the
      //     residual finer: a flat zero here while the resource-only co-located
      //     count is non-zero localizes the break to **terrain
      //     mineral-eligibility** at candidate generation (the owned `iron`
      //     tile sits on non-prospectable terrain); equal non-zero counts
      //     instead point **downstream** of eligibility (validator material
      //     cost / visibility precheck or selection ranking).
      //   * `supplierIdleExplorerColocatedSuggestedProspectTileTurns` — the
      //     **real** `suggestWorkOrders` pass actually emits a `prospect`
      //     candidate for the co-located mineral-eligible feedstock tile. This
      //     is the next gate past terrain eligibility: it runs the live
      //     generation pass (province visibility, move-leg validation, and the
      //     incremental-validator material-cost / visibility precheck all live
      //     inside it) rather than re-deriving one gate. Comparing it against
      //     `supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns`
      //     resolves the final fork: a non-zero count proves the prospect is
      //     generated + validator-accepted, so the residual is **selection
      //     ranking** (the accepted `prospect` loses to a competing `explore`
      //     in `selectFullAiCivilianWorkOrders`); a flat zero while the
      //     mineral-eligible count is non-zero localizes the residual **inside
      //     generation** (the visibility / move-leg / validator gates), not
      //     ranking.
      //
      // Read-only; the (freely tunable) counts can move as later slices land.
      final supplierIdleExplorerPresentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final supplierProspectedMineralFeedstockTileTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final supplierIdleExplorerColocatedFeedstockTileTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};
      final supplierIdleExplorerColocatedSuggestedProspectTileTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};
      final supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};
      final supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};
      final supplierIdleExplorerColocatedFeedstockProspectValidatorTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};

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
      final fabricRecipes = <ProductionRecipe>[
        for (final recipe in ProductionRecipesCatalog.all)
          if (cheapestRegimentInputs.containsKey(recipe.outputCommodityId))
            recipe,
      ];
      final fabricFeedstockIds = <String>{
        for (final recipe in fabricRecipes) ...recipe.inputQuantities.keys,
      };
      final feedstockExtractionGateActiveTurns = <String, int>{
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
      final castIronFeedstockExtractionLabourFutileTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final unimprovedFeedstockTileOwnedTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final feedstockInStockpileTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final fabricRecipeFeasibleTurns = <String, int>{
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
      final fabricRecipeLabourFeasibleTurns = <String, int>{
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
      final castIronRecipeFeasibleTurns = <String, int>{
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
      //     `economy_planner.dart` § `_allocateLabour` runs). A near-zero count
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
      final castIronRecipeLabourFeasibleTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronFeasibleOwnsFeedstockTileTurns = <String, int>{
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
      final castIronLabourFoodStarvedTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronLabourPopulationBoundTurns = <String, int>{
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
      final castIronLabourPeasantRecruitGateTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronLabourPeasantRecruitAffordableTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronLabourPeasantRecruitFabricStarvedTurns = <String, int>{
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
      final castIronLabourPeasantRecruitMarketFabricStarvedTurns =
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
      final castIronLabourPeasantRecruitMarketFabricUnofferedTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};
      // Refs #2847 § S7-D buyer-side fabric acquisition localization: on
      // fabric-starved peasant-recruit turns where offerable `fabric` exists
      // (`otherGreatPowerOfferableFabricHeld > 0`), whether the starved seller
      // emits a `fabric` bid and whether a deal fills as buyer. Read-only;
      // counts move freely as later slices land.
      final castIronLabourPeasantRecruitFabricBidEmittedTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronLabourPeasantRecruitFabricBidAbsentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronLabourPeasantRecruitFabricDealAsBuyerTurns = <String, int>{
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
      final castIronMarketOfferPresentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronMarketOfferAbsentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 § fabric offer-side split: on peasant-recruit fabric market
      // path-active turns, whether any *other* faction emitted a `fabric` sell
      // offer in trade orders (the trade-order emission layer between
      // offerable-holdings proxy and buyer-side bid/deal counters).
      final fabricMarketOfferPresentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final fabricMarketOfferAbsentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Minimum `labourPerOutput` across the castIron recipes — the cheapest
      // single run's effective-labour requirement, used as the food-starved /
      // population-bound fork threshold above.
      final castIronMinLabourPerOutput = castIronRecipes.isEmpty
          ? 0
          : castIronRecipes
                .map((recipe) => recipe.labourPerOutput)
                .reduce((a, b) => a < b ? a : b);
      // Food commodities (grain + meat) consumed by worker upkeep
      // (`economy_consumption.dart`), summed for the turn-99 food-on-hand
      // snapshot that corroborates the food-starved lever.
      final castIronLabourFoodCommodityIds = <String>{
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
      final feedstockGateIdleBuilderPresentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final feedstockGateImprovedTileOwnedTurns = <String, int>{
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
      final feedstockGateValidBuildImprovementCandidateTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final feedstockGateImprovementCostAffordableTurns = <String, int>{
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
      final improvementLumberId = CommodityCatalog.lumber.id;
      final improvementCastIronId = CommodityCatalog.castIron.id;
      final feedstockGateImprovementLumberAffordableTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final feedstockGateImprovementCastIronAffordableTurns = <String, int>{
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
      final feedstockAcquisitionTargetActiveTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final feedstockAcquisitionTargetWithFieldArmyTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };

      // Refs #2924 Step 0 — world-market lock-recovery diagnostics:
      // per-GP rollups capturing (a) trade orders the AI submits each
      // turn (offer/bid counts plus urgent-priority offer counts at
      // [kTreasuryOfferPriorityUrgent]), (b) deals matched in the
      // world-market phase counted by seller/buyer GP plus treasury
      // credited/debited per side, and (c) whether/when the post-turn
      // treasury crosses [cheapestRegimentBuildTreasuryCost]. These
      // surfaces are issue-2924 specific and live alongside the
      // existing #2847 S7-D fields so a single run produces both
      // diagnostic blocks.
      final tradeOfferCount = <String, int>{for (final gpId in gpIds) gpId: 0};
      final tradeUrgentOfferCount = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final tradeBidCount = <String, int>{for (final gpId in gpIds) gpId: 0};
      final dealsAsSeller = <String, int>{for (final gpId in gpIds) gpId: 0};
      final dealsAsBuyer = <String, int>{for (final gpId in gpIds) gpId: 0};
      final treasuryCredited = <String, int>{for (final gpId in gpIds) gpId: 0};
      final treasuryDebited = <String, int>{for (final gpId in gpIds) gpId: 0};
      final regimentThresholdCrossingsUp = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final regimentThresholdFirstReachTurn = <String, int?>{
        for (final gpId in gpIds) gpId: null,
      };
      final treasuryAtTurn99 = <String, int>{for (final gpId in gpIds) gpId: 0};
      // Treasury immediately after the previous turn resolved (seeded
      // from turn-0 pre-resolution treasury so the first crossing
      // detection compares against game start rather than zero).
      final treasuryPrevTurn = <String, int>{};

      /// Per-turn scratch state shared between harness callbacks.
      final pendingTurnScratch = <String, Object>{};

      final campaign = runSeed42ObserverCampaign(
        turns: 100,
        onBeforeResolve: (turn, fullAi, game, topo, tileMap) {
          if (turn == 0) {
            for (final gpId in gpIds) {
              treasuryPrevTurn[gpId] = game.playerById(gpId)?.treasury ?? 0;
            }
          }
          final t = turn;
        final fabricStarvedThisTurn = <String>{};
        // Refs #2847 § fabric offer-side split: GPs whose castIron-labour
        // peasant-recruit fabric market path is active this turn.
        final fabricMarketPathActiveThisTurn = <String>{};
        // Refs #2847 § castIron market-supply wall: GPs whose feedstock-
        // extraction gate is active this turn, scanned post-merge for castIron
        // market-offer presence/absence.
        final feedstockGateActiveThisTurn = <String>{};
        // Refs #2847 H8: per-turn rebuild-readiness + cheapest-regiment input
        // availability, populated in the pre-resolution GP loop and reconciled
        // against the emitted military builds after the merge below.
        final turnRebuildReady = <String, bool>{};
        final turnInputsPresent = <String, bool>{};

        // Capture phase / arm decisions *before* the turn resolves so the
        // diagnostic reflects what the planner saw entering turn t+1.
        for (final gpId in gpIds) {
          final view = buildPlayerView(game, topo, gpId);
          final snap = AIWorldSnapshot.fromPlayerView(view, topology: topo);
          final outcome = runPhasePlanners(game: game, snapshot: snap);
          phaseCounts[gpId]![outcome.phase] =
              (phaseCounts[gpId]![outcome.phase] ?? 0) + 1;
          final dwKey = outcome.expandDeclareWarTargetFactionId ?? '(null)';
          declareWarPicks[gpId]![dwKey] =
              (declareWarPicks[gpId]![dwKey] ?? 0) + 1;
          final peaceKey = outcome.expandPeaceTargetFactionIdsSorted.isEmpty
              ? '(none)'
              : outcome.expandPeaceTargetFactionIdsSorted.join(',');
          peaceTargetPicks[gpId]![peaceKey] =
              (peaceTargetPicks[gpId]![peaceKey] ?? 0) + 1;
          if (outcome.expandEconomyPlan.forceCheapestRegimentBuild) {
            economyArmCounts[gpId]!['forceCheapestRegimentBuild'] =
                (economyArmCounts[gpId]!['forceCheapestRegimentBuild'] ?? 0) +
                1;
          }
          if (outcome.expandEconomyPlan.boostTreasuryRecoveryCargo) {
            economyArmCounts[gpId]!['boostTreasuryRecoveryCargo'] =
                (economyArmCounts[gpId]!['boostTreasuryRecoveryCargo'] ?? 0) +
                1;
          }
          if (snap.conquest.invadableProvinceIdsSorted.isEmpty) {
            invadableEmptyTurns[gpId] = (invadableEmptyTurns[gpId] ?? 0) + 1;
          }
          for (final peer in snap.threats.atWarWith) {
            atWarTurnsByPeer[gpId]![peer] =
                (atWarTurnsByPeer[gpId]![peer] ?? 0) + 1;
          }
          final player = game.playerById(gpId);
          if (player != null) {
            final cheapest = cheapestRegimentBuildTreasuryCost();
            if (player.treasury < cheapest) {
              treasuryUnderCheapestTurns[gpId] =
                  (treasuryUnderCheapestTurns[gpId] ?? 0) + 1;
            } else {
              treasuryAtOrAboveCheapestTurns[gpId] =
                  (treasuryAtOrAboveCheapestTurns[gpId] ?? 0) + 1;
            }
          }
          final regiments = regimentCountForPlayer(game, gpId);
          if (regiments > (regimentPeak[gpId] ?? 0)) {
            regimentPeak[gpId] = regiments;
          }
          if (regiments == 0) {
            regimentTurnsAtZero[gpId] = (regimentTurnsAtZero[gpId] ?? 0) + 1;
          }
          // Refs #2847 H8 conversion-gap: classify this GP's pre-resolution
          // rebuild readiness and whether the cheapest-regiment build inputs
          // are already in the stockpile. Reconciled against the emitted
          // military builds after the merge below.
          final inputsPresent =
              player != null &&
              cheapestRegimentInputs.entries.every(
                (e) => player.stockpile.quantityOf(e.key) >= e.value,
              );
          turnInputsPresent[gpId] = inputsPresent;
          if (inputsPresent) {
            fabricInStockpileTurns[gpId] =
                (fabricInStockpileTurns[gpId] ?? 0) + 1;
          }
          final rebuildReady =
              outcome.expandEconomyPlan.forceCheapestRegimentBuild &&
              player != null &&
              player.treasury >= cheapestRegimentBuildTreasuryCost() &&
              regiments == 0;
          turnRebuildReady[gpId] = rebuildReady;
          if (rebuildReady) {
            rebuildReadyTurns[gpId] = (rebuildReadyTurns[gpId] ?? 0) + 1;
          }
          // Refs #2847 H8-supply feedstock-stage isolation (read-only). Splits
          // the domestic wool/cotton -> fabric production chain into its
          // proximate links: Builder-routing gate fired, an unimproved
          // feedstock resource tile is owned, feedstock reached the stockpile,
          // and a fabric recipe is feasible for at least one run.
          final feedstockGateActive =
              regimentBuildInputFeedstockExtractionResourceIds(
                game,
                gpId,
              ).isNotEmpty;
          if (feedstockGateActive) {
            feedstockGateActiveThisTurn.add(gpId);
            feedstockExtractionGateActiveTurns[gpId] =
                (feedstockExtractionGateActiveTurns[gpId] ?? 0) + 1;
            // Refs #2847 H8-extraction execution-gap disambiguation: split the
            // gate-active turns by Builder availability and improvement
            // completion so the next slice can target the exact stage.
            if (hasIdleBuilderUnit(game, gpId)) {
              feedstockGateIdleBuilderPresentTurns[gpId] =
                  (feedstockGateIdleBuilderPresentTurns[gpId] ?? 0) + 1;
            }
            if (ownsImprovedFeedstockResourceTile(
              game,
              gpId,
              fabricFeedstockIds,
            )) {
              feedstockGateImprovedTileOwnedTurns[gpId] =
                  (feedstockGateImprovedTileOwnedTurns[gpId] ?? 0) + 1;
            }
            // Refs #2847 H8-extraction missing-candidate disambiguation: does
            // the work-order engine accept a feedstock `build_improvement`
            // candidate at all, and can the GP afford the level-0 improvement
            // cost? Splits the suppression between the validator material-cost
            // gate and the tile-control / visibility gates.
            if (hasValidBuildImprovementOnUnimprovedFeedstockTile(
              game,
              topo,
              gpId,
              fabricFeedstockIds,
              tileMapByRegion: tileMap,
            )) {
              feedstockGateValidBuildImprovementCandidateTurns[gpId] =
                  (feedstockGateValidBuildImprovementCandidateTurns[gpId] ??
                      0) +
                  1;
            }
            if (affordsBuildImprovementLevelZero(game, gpId)) {
              feedstockGateImprovementCostAffordableTurns[gpId] =
                  (feedstockGateImprovementCostAffordableTurns[gpId] ?? 0) + 1;
            }
            // Per-component split of the combined affordability gate above:
            // pins which material (lumber / castIron) binds on gate-active
            // turns. Refs #2847 H8-extraction.
            if (affordsBuildImprovementComponent(
              game,
              gpId,
              improvementLumberId,
            )) {
              feedstockGateImprovementLumberAffordableTurns[gpId] =
                  (feedstockGateImprovementLumberAffordableTurns[gpId] ?? 0) +
                  1;
            }
            if (affordsBuildImprovementComponent(
              game,
              gpId,
              improvementCastIronId,
            )) {
              feedstockGateImprovementCastIronAffordableTurns[gpId] =
                  (feedstockGateImprovementCastIronAffordableTurns[gpId] ?? 0) +
                  1;
            }
            // Refs #2847 § S7-D castIron-feedstock order-matching off-critical
            // path: on a gate-active turn whose fully-fed raw labour ceiling is
            // below the castIron `labourPerOutput`, even a fully-filled
            // `timber` / `iron` feedstock bid could not yield a labour-feasible
            // domestic castIron run, so the order-matching gap is not on the
            // critical path — the binding constraint stays worker population.
            if (castIronFeedstockExtractionLabourFutile(
              game,
              gpId,
              castIronMinLabourPerOutput,
            )) {
              castIronFeedstockExtractionLabourFutileTurns[gpId] =
                  (castIronFeedstockExtractionLabourFutileTurns[gpId] ?? 0) + 1;
            }
          }
          if (ownsUnimprovedFeedstockResourceTile(
            game,
            gpId,
            fabricFeedstockIds,
          )) {
            unimprovedFeedstockTileOwnedTurns[gpId] =
                (unimprovedFeedstockTileOwnedTurns[gpId] ?? 0) + 1;
          }
          // Refs #2847 H8-extraction acquisition-thread localization
          // (read-only). Records whether the post-#3274 seller feedstock-tile
          // acquisition thread engages for this GP this turn (a non-null
          // conquest-reachable feedstock target) and, when it does, whether a
          // non-home field army is available to execute the conquest march.
          // `expandSellerFeedstockTileAcquisitionTarget` returns null for every
          // player whose acquisition residual is inactive, so gp1/gp2 stay 0.
          final acquisitionTarget = expandSellerFeedstockTileAcquisitionTarget(
            game: game,
            snapshot: snap,
          );
          if (acquisitionTarget != null) {
            feedstockAcquisitionTargetActiveTurns[gpId] =
                (feedstockAcquisitionTargetActiveTurns[gpId] ?? 0) + 1;
            if (hasFieldArmy(game, gpId)) {
              feedstockAcquisitionTargetWithFieldArmyTurns[gpId] =
                  (feedstockAcquisitionTargetWithFieldArmyTurns[gpId] ?? 0) + 1;
            }
          }
          if (supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            gpId,
          ).isNotEmpty) {
            supplierFeedstockExtractionGateActiveTurns[gpId] =
                (supplierFeedstockExtractionGateActiveTurns[gpId] ?? 0) + 1;
            // While the supplier gate is active, record per-castIron-feedstock
            // whether the GP owns an unimproved tile of that commodity (a
            // Builder extraction target). Pins whether the supplier ever has an
            // `iron` source to feed domestic `castIron` (Refs #2847).
            final feedstockTiles =
                supplierActiveUnimprovedCastIronFeedstockTileTurns[gpId]!;
            for (final feedstockId in castIronFeedstockIds) {
              if (ownsUnimprovedFeedstockResourceTile(game, gpId, {
                feedstockId,
              })) {
                feedstockTiles[feedstockId] =
                    (feedstockTiles[feedstockId] ?? 0) + 1;
              }
            }
            // Refs #2847 H8-extraction prospect localization: split the
            // never-extracted `iron` residual into Explorer availability vs a
            // downstream (prospect-done / improvement) break.
            if (hasIdleExplorerUnit(game, gpId)) {
              supplierIdleExplorerPresentTurns[gpId] =
                  (supplierIdleExplorerPresentTurns[gpId] ?? 0) + 1;
            }
            if (ownsProspectedOldWorldMineralFeedstockTile(
              game,
              gpId,
              castIronFeedstockIds,
            )) {
              supplierProspectedMineralFeedstockTileTurns[gpId] =
                  (supplierProspectedMineralFeedstockTileTurns[gpId] ?? 0) + 1;
            }
            if (ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
              game,
              gpId,
              castIronFeedstockIds,
            )) {
              supplierIdleExplorerColocatedFeedstockTileTurns[gpId] =
                  (supplierIdleExplorerColocatedFeedstockTileTurns[gpId] ?? 0) +
                  1;
            }
            if (ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
              game,
              gpId,
              castIronFeedstockIds,
              tileMap,
            )) {
              supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns[gpId] =
                  (supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns[gpId] ??
                      0) +
                  1;
            }
            if (suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile(
              game,
              topo,
              view,
              gpId,
              castIronFeedstockIds,
              tileMap,
            )) {
              supplierIdleExplorerColocatedSuggestedProspectTileTurns[gpId] =
                  (supplierIdleExplorerColocatedSuggestedProspectTileTurns[gpId] ??
                      0) +
                  1;
            }
            final intraPassGates =
                colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates(
                  game: game,
                  topology: topo,
                  view: view,
                  playerId: gpId,
                  feedstockIds: castIronFeedstockIds,
                  tileMapByRegion: tileMap,
                );
            if (intraPassGates.provinceFoggedVisibility) {
              supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns[gpId] =
                  (supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns[gpId] ??
                      0) +
                  1;
            }
            if (intraPassGates.bundledMoveLeg) {
              supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns[gpId] =
                  (supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns[gpId] ??
                      0) +
                  1;
            }
            if (intraPassGates.validatorAccepted) {
              supplierIdleExplorerColocatedFeedstockProspectValidatorTurns[gpId] =
                  (supplierIdleExplorerColocatedFeedstockProspectValidatorTurns[gpId] ??
                      0) +
                  1;
            }
          }
          if (player != null) {
            // Refs #2847 — per-turn castIron-labour stage localization. The
            // measure bundles the read-only flags (the #3303 peasant-recruit
            // gate + affordability, fabric feedstock/recipe feasibility, and
            // the castIron material/labour/food/tile fork); the caller only
            // applies counter bumps. The fabric-starved peasant-recruit subset
            // isolates the suspected circular dependency that renders the
            // #3303 boost a no-op.
            final ci = seed42S7dCastIronLabourTurnMeasure(
              game: game,
              playerId: gpId,
              fabricFeedstockIds: fabricFeedstockIds,
              fabricRecipes: fabricRecipes,
              castIronRecipes: castIronRecipes,
              castIronFeedstockIds: castIronFeedstockIds,
              castIronMinLabourPerOutput: castIronMinLabourPerOutput,
            );
            if (isCastIronLabourPeasantRecruitFabricMarketPathActive(
              game: game,
              playerId: gpId,
              projected: player.stockpile,
            )) {
              fabricMarketPathActiveThisTurn.add(gpId);
            }
            recordSeed42S7dCastIronLabourCounters(
              game: game,
              gpId: gpId,
              ci: ci,
              fabricStarvedThisTurn: fabricStarvedThisTurn,
              castIronLabourPeasantRecruitGateTurns:
                  castIronLabourPeasantRecruitGateTurns,
              castIronLabourPeasantRecruitAffordableTurns:
                  castIronLabourPeasantRecruitAffordableTurns,
              castIronLabourPeasantRecruitFabricStarvedTurns:
                  castIronLabourPeasantRecruitFabricStarvedTurns,
              castIronLabourPeasantRecruitMarketFabricStarvedTurns:
                  castIronLabourPeasantRecruitMarketFabricStarvedTurns,
              castIronLabourPeasantRecruitMarketFabricUnofferedTurns:
                  castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
              feedstockInStockpileTurns: feedstockInStockpileTurns,
              fabricRecipeFeasibleTurns: fabricRecipeFeasibleTurns,
              fabricRecipeLabourFeasibleTurns: fabricRecipeLabourFeasibleTurns,
              castIronRecipeFeasibleTurns: castIronRecipeFeasibleTurns,
              castIronRecipeLabourFeasibleTurns:
                  castIronRecipeLabourFeasibleTurns,
              castIronLabourFoodStarvedTurns: castIronLabourFoodStarvedTurns,
              castIronLabourPopulationBoundTurns:
                  castIronLabourPopulationBoundTurns,
              castIronFeasibleOwnsFeedstockTileTurns:
                  castIronFeasibleOwnsFeedstockTileTurns,
            );
          }
          // Cache the turn-99 snapshot fields for the final rollup.
          if (t == 99) {
            lastSnapshotFields[gpId] = seed42S7dTurn99SnapshotFields(
              game: game,
              playerId: gpId,
              snap: snap,
              foodCommodityIds: castIronLabourFoodCommodityIds,
            );
          }
        }

        final merged = mergeOrderLists(
          humanOrders: const Orders(),
          aiOrders: fullAi.orders,
        );

        // Refs #2847 — count military `BuildUnitOrder`s the AI emits per
        // GP this turn (regiment / warship builds carry `isMilitary ==
        // true`). Compared against the regiment trajectory above, a high
        // emission count with a flat/zero peak indicates builds rejected
        // downstream or units lost as fast as they are produced; a low
        // emission count indicates the planner never queues the build.
        for (final gpId in gpIds) {
          final builds = merged.buildUnitOrdersByPlayerId[gpId];
          var emittedMilitaryThisTurn = false;
          if (builds != null) {
            for (final build in builds) {
              if (build.isMilitary) {
                militaryBuildOrdersEmitted[gpId] =
                    (militaryBuildOrdersEmitted[gpId] ?? 0) + 1;
                emittedMilitaryThisTurn = true;
              }
            }
          }
          // Refs #2847 H8 conversion-gap reconciliation. On a rebuild-ready
          // turn (directive active + treasury affordable + zero regiments)
          // that emitted no military build, attribute the miss to either a
          // missing cheapest-regiment input in the stockpile (production /
          // market-acquisition gap) or inputs-present-yet-no-build (downstream
          // suggestion / build-pick gate).
          if ((turnRebuildReady[gpId] ?? false) && !emittedMilitaryThisTurn) {
            rebuildReadyNoBuildTurns[gpId] =
                (rebuildReadyNoBuildTurns[gpId] ?? 0) + 1;
            if (turnInputsPresent[gpId] ?? false) {
              rebuildReadyNoBuildInputsPresentTurns[gpId] =
                  (rebuildReadyNoBuildInputsPresentTurns[gpId] ?? 0) + 1;
            } else {
              rebuildReadyNoBuildMissingInputTurns[gpId] =
                  (rebuildReadyNoBuildMissingInputTurns[gpId] ?? 0) + 1;
            }
          }
          // Refs #2847 H8-extraction castIron residual: did the economy planner
          // assign a domestic castIron recipe this turn (only possible when the
          // recipe's timber + iron feedstock is on hand for >= 1 full run)?
          final plan = fullAi.economyPlansByPlayerId[gpId];
          if (plan != null &&
              plan.productionAssignments.any(
                (a) => castIronRecipeIds.contains(a.recipeId),
              )) {
            castIronProductionAssignedTurns[gpId] =
                (castIronProductionAssignedTurns[gpId] ?? 0) + 1;
          }
          if (plan != null &&
              plan.productionAssignments.any(
                (a) => fabricRecipeIds.contains(a.recipeId),
              )) {
            fabricProductionAssignedTurns[gpId] =
                (fabricProductionAssignedTurns[gpId] ?? 0) + 1;
          }
        }

        // Refs #2924 Step 0 — count submitted trade orders per GP
        // from the merged order list that the resolver will apply.
        // Carry-forward bids/offers re-injected by the world-market
        // phase are not counted here; this metric reflects what the
        // AI actively emits each turn.
        recordSeed42S7dTradeOrderCounters(
          gpIds: gpIds,
          tradeOrdersByPlayerId: merged.tradeOrdersByPlayerId,
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

        // Refs #2847 § S7-D buyer-side fabric acquisition: on fabric-starved
        // peasant-recruit turns with offerable counterparty supply, record
        // whether the seller emitted a `fabric` bid this turn.
        recordSeed42S7dFabricBidCounters(
          game: game,
          fabricStarvedThisTurn: fabricStarvedThisTurn,
          tradeOrdersByPlayerId: merged.tradeOrdersByPlayerId,
          emittedTurns: castIronLabourPeasantRecruitFabricBidEmittedTurns,
          absentTurns: castIronLabourPeasantRecruitFabricBidAbsentTurns,
        );

        // Refs #2847 § fabric offer-side split: on peasant-recruit fabric
        // market-path-active turns, record whether any other faction offered
        // `fabric` in trade orders this turn.
        recordSeed42S7dFabricMarketOfferCounters(
          fabricMarketPathActiveThisTurn: fabricMarketPathActiveThisTurn,
          tradeOrdersByPlayerId: merged.tradeOrdersByPlayerId,
          presentTurns: fabricMarketOfferPresentTurns,
          absentTurns: fabricMarketOfferAbsentTurns,
        );

        // Refs #2847 § castIron market-supply wall: on the feedstock-extraction
        // gate-active turns, record whether any other faction offered castIron
        // (the manufactured level-0 build_improvement input) this turn.
        recordSeed42S7dCastIronMarketOfferCounters(
          feedstockGateActiveThisTurn: feedstockGateActiveThisTurn,
          tradeOrdersByPlayerId: merged.tradeOrdersByPlayerId,
          castIronCommodityId:
              castIronProductionRecipe?.outputCommodityId ?? 'castIron',
          presentTurns: castIronMarketOfferPresentTurns,
          absentTurns: castIronMarketOfferAbsentTurns,
        );

        pendingTurnScratch['fabricStarvedThisTurn'] = fabricStarvedThisTurn;
        },
        onAfterResolve: (turn, game) {
          final t = turn;
          final fabricStarvedThisTurn =
              pendingTurnScratch['fabricStarvedThisTurn']! as Set<String>;

        // Refs #2924 Step 0 — tally deals matched per GP from the
        // post-resolution world-market activity. `lastTurnActivity`
        // holds the deals that filled during phase 13 of the just-
        // resolved turn; we accumulate seller/buyer counts and the
        // resulting treasury credit/debit per GP. Treasury delta is
        // rounded the same way the world-market phase computes the
        // notional transfer per `SPEC/program/world-market-resolution.md`.
        final activity = game.worldMarketState.lastTurnActivity;
        for (final entry in activity.entries) {
          for (final deal in entry.value.deals) {
            final notional = (deal.quantity * deal.pricePerUnit).round();
            final seller = deal.sellerFactionId;
            if (treasuryCredited.containsKey(seller)) {
              dealsAsSeller[seller] = (dealsAsSeller[seller] ?? 0) + 1;
              treasuryCredited[seller] =
                  (treasuryCredited[seller] ?? 0) + notional;
            }
            final buyer = deal.buyerFactionId;
            if (treasuryDebited.containsKey(buyer)) {
              dealsAsBuyer[buyer] = (dealsAsBuyer[buyer] ?? 0) + 1;
              treasuryDebited[buyer] = (treasuryDebited[buyer] ?? 0) + notional;
              if (regimentInputCommodityIds.contains(deal.commodityId)) {
                regimentInputDealsAsBuyer[buyer] =
                    (regimentInputDealsAsBuyer[buyer] ?? 0) + 1;
              }
              if (improvementInputCommodityIds.contains(deal.commodityId)) {
                improvementInputDealsAsBuyer[buyer] =
                    (improvementInputDealsAsBuyer[buyer] ?? 0) + 1;
              }
              if (castIronFeedstockIds.contains(deal.commodityId)) {
                castIronFeedstockDealsAsBuyer[buyer] =
                    (castIronFeedstockDealsAsBuyer[buyer] ?? 0) + 1;
              }
              if (fabricStarvedThisTurn.contains(buyer) &&
                  deal.commodityId == 'fabric') {
                bumpCounter(
                  castIronLabourPeasantRecruitFabricDealAsBuyerTurns,
                  buyer,
                );
              }
            }
          }
        }

        // Refs #2924 Step 0 — treasury threshold crossings:
        // count turn boundaries where a GP transitions from
        // `treasury < cheapestRegimentBuildTreasuryCost` to
        // `treasury >= cheapestRegimentBuildTreasuryCost` based on
        // post-resolution treasury. First-reach turn captures the
        // earliest turn at which each GP's post-turn treasury can
        // afford the cheapest regiment.
        final cheapest = cheapestRegimentBuildTreasuryCost();
        for (final gpId in gpIds) {
          final after = game.playerById(gpId)?.treasury ?? 0;
          final before = treasuryPrevTurn[gpId] ?? 0;
          if (before < cheapest && after >= cheapest) {
            regimentThresholdCrossingsUp[gpId] =
                (regimentThresholdCrossingsUp[gpId] ?? 0) + 1;
          }
          if (regimentThresholdFirstReachTurn[gpId] == null &&
              after >= cheapest) {
            regimentThresholdFirstReachTurn[gpId] = t;
          }
          treasuryPrevTurn[gpId] = after;
          if (t == 99) {
            treasuryAtTurn99[gpId] = after;
            final player = game.playerById(gpId);
            if (player != null) {
              improvementInputHeldAtTurn99[gpId] = improvementInputCommodityIds
                  .fold<int>(
                    0,
                    (sum, id) => sum + player.stockpile.quantityOf(id),
                  );
              lumberHeldAtTurn99[gpId] = player.stockpile.quantityOf('lumber');
              castIronHeldAtTurn99[gpId] = player.stockpile.quantityOf(
                'castIron',
              );
              final feedstockHeld = castIronFeedstockHeldAtTurn99[gpId]!;
              for (final feedstockId in castIronFeedstockIds) {
                feedstockHeld[feedstockId] = player.stockpile.quantityOf(
                  feedstockId,
                );
              }
            }
          }
        }
        },
      );

      final game = campaign.finalGame;
      final owStart = <String, int>{
        for (final gpId in gpIds)
          gpId: campaign.initialGame.worldState.oldWorld.provinces
              .where((p) => p.ownerId == gpId)
              .length,
      };
      final gains = <String, int>{
        for (final gpId in gpIds)
          gpId:
              game.worldState.oldWorld.provinces
                  .where((p) => p.ownerId == gpId)
                  .length -
              owStart[gpId]!,
      };

      // Structured JSON dump for inclusion in the S7-D diagnostic note.
      final diagnostic = <String, Object?>{
        'issue': 2847,
        'subtask': 'S7-D',
        'seed': 42,
        'turns': 100,
        'gpOwGain': gains,
        'gpOwStart': owStart,
        'gpPhaseTurnCount': {
          for (final gpId in gpIds)
            gpId: {
              for (final entry in phaseCounts[gpId]!.entries)
                entry.key.name: entry.value,
            },
        },
        'gpDeclareWarPickDistribution': declareWarPicks,
        'gpExpandPeacePickDistribution': peaceTargetPicks,
        'gpExpandEconomyArmCounts': economyArmCounts,
        'gpInvadableEmptyTurns': invadableEmptyTurns,
        'gpAtWarTurnsByPeer': atWarTurnsByPeer,
        'gpTreasuryUnderCheapestRegimentTurns': treasuryUnderCheapestTurns,
        'gpTreasuryAtOrAboveCheapestRegimentTurns':
            treasuryAtOrAboveCheapestTurns,
        'gpRegimentPeak': regimentPeak,
        'gpRegimentTurnsAtZero': regimentTurnsAtZero,
        'gpMilitaryBuildOrdersEmitted': militaryBuildOrdersEmitted,
        'gpCheapestRegimentInputsInStockpileTurns': fabricInStockpileTurns,
        'gpRebuildReadyTurns': rebuildReadyTurns,
        'gpRebuildReadyNoBuildTurns': rebuildReadyNoBuildTurns,
        'gpRebuildReadyNoBuildMissingInputTurns':
            rebuildReadyNoBuildMissingInputTurns,
        'gpRebuildReadyNoBuildInputsPresentTurns':
            rebuildReadyNoBuildInputsPresentTurns,
        'regimentInputCommodityIds': regimentInputCommodityIds.toList()..sort(),
        'gpRegimentInputBidsEmitted': regimentInputBidsEmitted,
        'gpRegimentInputDealsAsBuyer': regimentInputDealsAsBuyer,
        'improvementInputCommodityIds': improvementInputCommodityIds.toList()
          ..sort(),
        'gpImprovementInputOffersEmitted': improvementInputOffersEmitted,
        'gpImprovementInputBidsEmitted': improvementInputBidsEmitted,
        'gpImprovementInputDealsAsBuyer': improvementInputDealsAsBuyer,
        'gpImprovementInputHeldAtTurn99': improvementInputHeldAtTurn99,
        'castIronFeedstockCommodityIds': castIronFeedstockIds.toList()..sort(),
        'gpCastIronFeedstockOffersEmitted': castIronFeedstockOffersEmitted,
        'gpCastIronFeedstockBidsEmitted': castIronFeedstockBidsEmitted,
        'gpCastIronFeedstockDealsAsBuyer': castIronFeedstockDealsAsBuyer,
        'gpCastIronProductionAssignedTurns': castIronProductionAssignedTurns,
        'gpFabricProductionAssignedTurns': fabricProductionAssignedTurns,
        'gpSupplierFeedstockExtractionGateActiveTurns':
            supplierFeedstockExtractionGateActiveTurns,
        'gpSupplierActiveUnimprovedCastIronFeedstockTileTurns':
            supplierActiveUnimprovedCastIronFeedstockTileTurns,
        'gpSupplierIdleExplorerPresentTurns': supplierIdleExplorerPresentTurns,
        'gpSupplierProspectedMineralFeedstockTileTurns':
            supplierProspectedMineralFeedstockTileTurns,
        'gpSupplierIdleExplorerColocatedFeedstockTileTurns':
            supplierIdleExplorerColocatedFeedstockTileTurns,
        'gpSupplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns':
            supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns,
        'gpSupplierIdleExplorerColocatedSuggestedProspectTileTurns':
            supplierIdleExplorerColocatedSuggestedProspectTileTurns,
        'gpSupplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns':
            supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns,
        'gpSupplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns':
            supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns,
        'gpSupplierIdleExplorerColocatedFeedstockProspectValidatorTurns':
            supplierIdleExplorerColocatedFeedstockProspectValidatorTurns,
        'gpCastIronFeedstockHeldAtTurn99': castIronFeedstockHeldAtTurn99,
        'gpLumberHeldAtTurn99': lumberHeldAtTurn99,
        'gpCastIronHeldAtTurn99': castIronHeldAtTurn99,
        'fabricFeedstockCommodityIds': fabricFeedstockIds.toList()..sort(),
        'gpFeedstockExtractionGateActiveTurns':
            feedstockExtractionGateActiveTurns,
        'gpUnimprovedFeedstockTileOwnedTurns':
            unimprovedFeedstockTileOwnedTurns,
        'gpFeedstockGateIdleBuilderPresentTurns':
            feedstockGateIdleBuilderPresentTurns,
        'gpFeedstockGateImprovedTileOwnedTurns':
            feedstockGateImprovedTileOwnedTurns,
        'gpFeedstockGateValidBuildImprovementCandidateTurns':
            feedstockGateValidBuildImprovementCandidateTurns,
        'gpFeedstockGateImprovementCostAffordableTurns':
            feedstockGateImprovementCostAffordableTurns,
        'gpFeedstockGateImprovementLumberAffordableTurns':
            feedstockGateImprovementLumberAffordableTurns,
        'gpFeedstockGateImprovementCastIronAffordableTurns':
            feedstockGateImprovementCastIronAffordableTurns,
        'gpFeedstockAcquisitionTargetActiveTurns':
            feedstockAcquisitionTargetActiveTurns,
        'gpFeedstockAcquisitionTargetWithFieldArmyTurns':
            feedstockAcquisitionTargetWithFieldArmyTurns,
        'gpFeedstockInStockpileTurns': feedstockInStockpileTurns,
        'gpFabricRecipeFeasibleTurns': fabricRecipeFeasibleTurns,
        'gpFabricRecipeLabourFeasibleTurns': fabricRecipeLabourFeasibleTurns,
        'gpCastIronRecipeFeasibleTurns': castIronRecipeFeasibleTurns,
        'gpCastIronRecipeLabourFeasibleTurns':
            castIronRecipeLabourFeasibleTurns,
        'gpCastIronFeasibleOwnsFeedstockTileTurns':
            castIronFeasibleOwnsFeedstockTileTurns,
        'gpCastIronLabourFoodStarvedTurns': castIronLabourFoodStarvedTurns,
        'gpCastIronLabourPopulationBoundTurns':
            castIronLabourPopulationBoundTurns,
        'gpCastIronLabourPeasantRecruitGateTurns':
            castIronLabourPeasantRecruitGateTurns,
        'gpCastIronLabourPeasantRecruitAffordableTurns':
            castIronLabourPeasantRecruitAffordableTurns,
        'gpCastIronLabourPeasantRecruitFabricStarvedTurns':
            castIronLabourPeasantRecruitFabricStarvedTurns,
        'gpCastIronLabourPeasantRecruitMarketFabricStarvedTurns':
            castIronLabourPeasantRecruitMarketFabricStarvedTurns,
        'gpCastIronLabourPeasantRecruitMarketFabricUnofferedTurns':
            castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
        'gpCastIronLabourPeasantRecruitFabricBidEmittedTurns':
            castIronLabourPeasantRecruitFabricBidEmittedTurns,
        'gpCastIronLabourPeasantRecruitFabricBidAbsentTurns':
            castIronLabourPeasantRecruitFabricBidAbsentTurns,
        'gpCastIronLabourPeasantRecruitFabricDealAsBuyerTurns':
            castIronLabourPeasantRecruitFabricDealAsBuyerTurns,
        'gpCastIronMarketOfferPresentTurns': castIronMarketOfferPresentTurns,
        'gpCastIronMarketOfferAbsentTurns': castIronMarketOfferAbsentTurns,
        'gpFabricMarketOfferPresentTurns': fabricMarketOfferPresentTurns,
        'gpFabricMarketOfferAbsentTurns': fabricMarketOfferAbsentTurns,
        'gpCastIronFeedstockExtractionLabourFutileTurns':
            castIronFeedstockExtractionLabourFutileTurns,
        'castIronMinLabourPerOutput': castIronMinLabourPerOutput,
        'gpTurn99Snapshot': lastSnapshotFields,
      };

      // Refs #2924 Step 0 — lock-recovery JSON (builder in support/s7d).
      final lockRecoveryDiagnostic = buildSeed42S7dLockRecoveryDiagnosticJson(
        gpIds: gpIds,
        tradeOfferCount: tradeOfferCount,
        tradeUrgentOfferCount: tradeUrgentOfferCount,
        tradeBidCount: tradeBidCount,
        dealsAsSeller: dealsAsSeller,
        dealsAsBuyer: dealsAsBuyer,
        treasuryCredited: treasuryCredited,
        treasuryDebited: treasuryDebited,
        regimentThresholdCrossingsUp: regimentThresholdCrossingsUp,
        regimentThresholdFirstReachTurn: regimentThresholdFirstReachTurn,
        treasuryUnderCheapestTurns: treasuryUnderCheapestTurns,
        treasuryAtTurn99: treasuryAtTurn99,
      );

      // Re-enable info-level logging so the structured diagnostic JSON
      // surfaces in stdout via the package logger (the simulation above
      // intentionally ran with logging off to suppress planner noise).
      // Routing through `aiLogger` keeps this test compliant with the
      // disallowed-AST `avoid_print_suppression` rule while preserving
      // greppable BEGIN/END markers for issue-comment transcription.
      CtLogger.level = Level.info;
      final log = aiLogger('s7d-diagnostic');
      log.i('S7D_DIAGNOSTIC_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(diagnostic));
      log.i('S7D_DIAGNOSTIC_JSON_END');
      log.i('ISSUE2924_STEP0_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(lockRecoveryDiagnostic));
      log.i('ISSUE2924_STEP0_JSON_END');

      // Lightweight assertion: data was actually collected. The diagnostic
      // does not pin arm-fire counts so the planner can be tuned freely
      // in S7-T without churn here. The structural invariants over the
      // per-GP counter maps are asserted by the extracted support helper
      // (kept out of this file for the non-comment line-size budget).
      assertSeed42S7dStructuralInvariants(
        gpIds: gpIds,
        phaseCounts: phaseCounts,
        rebuildReadyNoBuildTurns: rebuildReadyNoBuildTurns,
        rebuildReadyNoBuildMissingInputTurns:
            rebuildReadyNoBuildMissingInputTurns,
        rebuildReadyNoBuildInputsPresentTurns:
            rebuildReadyNoBuildInputsPresentTurns,
        feedstockExtractionGateActiveTurns: feedstockExtractionGateActiveTurns,
        feedstockGateIdleBuilderPresentTurns:
            feedstockGateIdleBuilderPresentTurns,
        feedstockGateImprovedTileOwnedTurns:
            feedstockGateImprovedTileOwnedTurns,
        feedstockGateValidBuildImprovementCandidateTurns:
            feedstockGateValidBuildImprovementCandidateTurns,
        feedstockGateImprovementCostAffordableTurns:
            feedstockGateImprovementCostAffordableTurns,
        feedstockGateImprovementLumberAffordableTurns:
            feedstockGateImprovementLumberAffordableTurns,
        feedstockGateImprovementCastIronAffordableTurns:
            feedstockGateImprovementCastIronAffordableTurns,
        feedstockAcquisitionTargetActiveTurns:
            feedstockAcquisitionTargetActiveTurns,
        feedstockAcquisitionTargetWithFieldArmyTurns:
            feedstockAcquisitionTargetWithFieldArmyTurns,
        castIronLabourPeasantRecruitGateTurns:
            castIronLabourPeasantRecruitGateTurns,
        castIronLabourPeasantRecruitAffordableTurns:
            castIronLabourPeasantRecruitAffordableTurns,
        castIronLabourPeasantRecruitFabricStarvedTurns:
            castIronLabourPeasantRecruitFabricStarvedTurns,
        castIronLabourPeasantRecruitMarketFabricStarvedTurns:
            castIronLabourPeasantRecruitMarketFabricStarvedTurns,
        castIronLabourPeasantRecruitMarketFabricUnofferedTurns:
            castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
        castIronLabourPeasantRecruitFabricBidEmittedTurns:
            castIronLabourPeasantRecruitFabricBidEmittedTurns,
        castIronLabourPeasantRecruitFabricBidAbsentTurns:
            castIronLabourPeasantRecruitFabricBidAbsentTurns,
        castIronLabourPeasantRecruitFabricDealAsBuyerTurns:
            castIronLabourPeasantRecruitFabricDealAsBuyerTurns,
        fabricRecipeFeasibleTurns: fabricRecipeFeasibleTurns,
        fabricRecipeLabourFeasibleTurns: fabricRecipeLabourFeasibleTurns,
        castIronMarketOfferPresentTurns: castIronMarketOfferPresentTurns,
        castIronMarketOfferAbsentTurns: castIronMarketOfferAbsentTurns,
        castIronFeedstockExtractionLabourFutileTurns:
            castIronFeedstockExtractionLabourFutileTurns,
      );
    },
    skip:
        'Refs #2847 S7-D: long-running (~4 min) per-GP EXPAND-arm '
        'diagnostic. Captured findings live in '
        'support/s7d/s7d_diagnostic_findings.dart and the issue S7-D '
        'note. Re-run with `dart test --run-skipped` when the '
        'diagnostic surface shifts after a tuning slice lands.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
