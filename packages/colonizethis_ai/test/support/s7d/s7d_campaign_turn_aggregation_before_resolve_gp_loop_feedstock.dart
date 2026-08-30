// Feedstock / labour / turn-99 stage of the S7-D before-resolve GP loop (Refs #4602 Slice E).
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show isCastIronLabourPeasantRecruitFabricMarketPathActive;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show expandSellerFeedstockTileAcquisitionTarget;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 's7d_campaign_rollup.dart';
import 's7d_campaign_turn_aggregation_before_resolve_gp_loop_prospect.dart';
import 's7d_campaign_turn_aggregation_before_resolve_scratch.dart';
import '../seed42_s7d_feedstock_helpers.dart';

extension Seed42S7dCampaignTurnAggregationBeforeResolveFeedstock
    on Seed42S7dCampaignRollup {
  void recordBeforeResolveFeedstockAndLabourStage({
    required int t,
    required Game game,
    required MapTopology topology,
    required Map<String, TileMapResult> tileMap,
    required Seed42S7dBeforeResolveTurnScratch scratch,
    required String gpId,
    required AIWorldSnapshot snap,
    required PlayerView view,
    required Player? player,
  }) {
    final topo = topology;
    // the domestic wool/cotton -> fabric production chain into its
    // proximate links: Builder-routing gate fired, an unimproved
    // feedstock resource tile is owned, feedstock reached the stockpile,
    // and a fabric recipe is feasible for at least one run.
    final feedstockGateActive =
        regimentBuildInputFeedstockExtractionResourceIds(game, gpId).isNotEmpty;
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
      if (affordsBuildImprovementComponent(game, gpId, improvementCastIronId)) {
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
          feedstockTiles[feedstockId] = (feedstockTiles[feedstockId] ?? 0) + 1;
        }
      }
      recordBeforeResolveSupplierProspectCounters(
        game: game,
        topology: topo,
        tileMap: tileMap,
        gpId: gpId,
        view: view,
      );
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
        castIronLabourPopulationBoundTurns: castIronLabourPopulationBoundTurns,
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
