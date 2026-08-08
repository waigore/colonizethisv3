// Per-turn aggregation for the seed-42 S7-D diagnostic campaign (Refs #3997).
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
import 'package:colonizethis_logic/ai_api.dart'
    show
        regimentBuildInputFeedstockExtractionResourceIds,
        supplierImprovementInputFeedstockExtractionResourceIds;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../seed42_s7d_feedstock_helpers.dart';

import 's7d_campaign_rollup.dart';


/// Per-turn pre-resolution aggregation for the S7-D campaign.
extension Seed42S7dCampaignTurnAggregationBeforeResolve on Seed42S7dCampaignRollup {
  void onBeforeResolve(
    int turn,
    FullAIResult fullAi,
    Game game,
    MapTopology topo,
    Map<String, TileMapResult> tileMap,
  ) {
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
      declareWarPicks[gpId]![dwKey] = (declareWarPicks[gpId]![dwKey] ?? 0) + 1;
      final peaceKey = outcome.expandPeaceTargetFactionIdsSorted.isEmpty
          ? '(none)'
          : outcome.expandPeaceTargetFactionIdsSorted.join(',');
      peaceTargetPicks[gpId]![peaceKey] =
          (peaceTargetPicks[gpId]![peaceKey] ?? 0) + 1;
      if (outcome.expandEconomyPlan.forceCheapestRegimentBuild) {
        economyArmCounts[gpId]!['forceCheapestRegimentBuild'] =
            (economyArmCounts[gpId]!['forceCheapestRegimentBuild'] ?? 0) + 1;
      }
      if (outcome.expandEconomyPlan.boostTreasuryRecoveryCargo) {
        economyArmCounts[gpId]!['boostTreasuryRecoveryCargo'] =
            (economyArmCounts[gpId]!['boostTreasuryRecoveryCargo'] ?? 0) + 1;
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
        fabricInStockpileTurns[gpId] = (fabricInStockpileTurns[gpId] ?? 0) + 1;
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
        if (ownsImprovedFeedstockResourceTile(game, gpId, fabricFeedstockIds)) {
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
              (feedstockGateValidBuildImprovementCandidateTurns[gpId] ?? 0) + 1;
        }
        if (affordsBuildImprovementLevelZero(game, gpId)) {
          feedstockGateImprovementCostAffordableTurns[gpId] =
              (feedstockGateImprovementCostAffordableTurns[gpId] ?? 0) + 1;
        }
        // Per-component split of the combined affordability gate above:
        // pins which material (lumber / castIron) binds on gate-active
        // turns. Refs #2847 H8-extraction.
        if (affordsBuildImprovementComponent(game, gpId, improvementLumberId)) {
          feedstockGateImprovementLumberAffordableTurns[gpId] =
              (feedstockGateImprovementLumberAffordableTurns[gpId] ?? 0) + 1;
        }
        if (affordsBuildImprovementComponent(
          game,
          gpId,
          improvementCastIronId,
        )) {
          feedstockGateImprovementCastIronAffordableTurns[gpId] =
              (feedstockGateImprovementCastIronAffordableTurns[gpId] ?? 0) + 1;
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
      if (ownsUnimprovedFeedstockResourceTile(game, gpId, fabricFeedstockIds)) {
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
          if (ownsUnimprovedFeedstockResourceTile(game, gpId, {feedstockId})) {
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
              (supplierIdleExplorerColocatedFeedstockTileTurns[gpId] ?? 0) + 1;
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
          castIronRecipeLabourFeasibleTurns: castIronRecipeLabourFeasibleTurns,
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
  }
}
