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


/// Per-turn post-resolution aggregation for the S7-D campaign.
extension Seed42S7dCampaignTurnAggregationAfterResolve on Seed42S7dCampaignRollup {
  void onAfterResolve(int turn, Game game) {
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
          treasuryCredited[seller] = (treasuryCredited[seller] ?? 0) + notional;
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
      if (regimentThresholdFirstReachTurn[gpId] == null && after >= cheapest) {
        regimentThresholdFirstReachTurn[gpId] = t;
      }
      treasuryPrevTurn[gpId] = after;
      if (t == 99) {
        treasuryAtTurn99[gpId] = after;
        final player = game.playerById(gpId);
        if (player != null) {
          improvementInputHeldAtTurn99[gpId] = improvementInputCommodityIds
              .fold<int>(0, (sum, id) => sum + player.stockpile.quantityOf(id));
          lumberHeldAtTurn99[gpId] = player.stockpile.quantityOf('lumber');
          castIronHeldAtTurn99[gpId] = player.stockpile.quantityOf('castIron');
          final feedstockHeld = castIronFeedstockHeldAtTurn99[gpId]!;
          for (final feedstockId in castIronFeedstockIds) {
            feedstockHeld[feedstockId] = player.stockpile.quantityOf(
              feedstockId,
            );
          }
        }
      }
    }
  }
}
