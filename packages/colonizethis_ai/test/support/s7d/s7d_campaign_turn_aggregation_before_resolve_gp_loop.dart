// Per-turn GP scan before resolution for seed-42 S7-D (Refs #4310 Slice A).
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

/// Scratch sets/maps shared between the GP loop and merged-order reconciliation.
class Seed42S7dBeforeResolveTurnScratch {
  final Set<String> fabricStarvedThisTurn = <String>{};
  final Set<String> fabricMarketPathActiveThisTurn = <String>{};
  final Set<String> feedstockGateActiveThisTurn = <String>{};
  final Map<String, bool> turnRebuildReady = <String, bool>{};
  final Map<String, bool> turnInputsPresent = <String, bool>{};
}

extension Seed42S7dCampaignTurnAggregationBeforeResolveGpLoop
    on Seed42S7dCampaignRollup {
  void runGpBeforeResolveLoop(
    int t,
    Game game,
    MapTopology topo,
    Map<String, TileMapResult> tileMap,
    Seed42S7dBeforeResolveTurnScratch scratch,
  ) {
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
      scratch.turnInputsPresent[gpId] = inputsPresent;
      if (inputsPresent) {
        fabricInStockpileTurns[gpId] = (fabricInStockpileTurns[gpId] ?? 0) + 1;
      }
      final rebuildReady =
          outcome.expandEconomyPlan.forceCheapestRegimentBuild &&
          player != null &&
          player.treasury >= cheapestRegimentBuildTreasuryCost() &&
          regiments == 0;
      scratch.turnRebuildReady[gpId] = rebuildReady;
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
        scratch.feedstockGateActiveThisTurn.add(gpId);
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
          scratch.fabricMarketPathActiveThisTurn.add(gpId);
        }
        recordSeed42S7dCastIronLabourCounters(
          game: game,
          gpId: gpId,
          ci: ci,
          fabricStarvedThisTurn: scratch.fabricStarvedThisTurn,
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
  }
}
