// Per-turn GP scan before resolution for seed-42 S7-D (Refs #4310 Slice A).
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 's7d_campaign_rollup.dart';
import 's7d_campaign_turn_aggregation_before_resolve_gp_loop_feedstock.dart';
import 's7d_campaign_turn_aggregation_before_resolve_scratch.dart';

export 's7d_campaign_turn_aggregation_before_resolve_scratch.dart';

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
      recordBeforeResolveFeedstockAndLabourStage(
        t: t,
        game: game,
        topology: topo,
        tileMap: tileMap,
        scratch: scratch,
        gpId: gpId,
        snap: snap,
        view: view,
        player: player,
      );
    }
  }
}
