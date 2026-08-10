// Per-turn aggregation for the seed-42 S7-D diagnostic campaign (Refs #3997 / #4310).
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 's7d_campaign_rollup.dart';
import 's7d_campaign_turn_aggregation_before_resolve_gp_loop.dart';
import 's7d_campaign_turn_aggregation_before_resolve_merged.dart';

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
    final scratch = Seed42S7dBeforeResolveTurnScratch();
    runGpBeforeResolveLoop(turn, game, topo, tileMap, scratch);
    reconcileMergedOrdersBeforeResolve(fullAi, game, scratch);
    pendingTurnScratch['fabricStarvedThisTurn'] = scratch.fabricStarvedThisTurn;
  }
}
