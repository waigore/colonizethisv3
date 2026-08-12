// Post-merge order reconciliation for S7-D before-resolve (Refs #4310 Slice A).
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'lock_recovery_trade_probes.dart';
import 's7d_campaign_rollup.dart';
import 's7d_campaign_turn_aggregation_before_resolve_gp_loop.dart';

extension Seed42S7dCampaignTurnAggregationBeforeResolveMerged
    on Seed42S7dCampaignRollup {
  void reconcileMergedOrdersBeforeResolve(
    FullAIResult fullAi,
    Game game,
    Seed42S7dBeforeResolveTurnScratch scratch,
  ) {
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
      if ((scratch.turnRebuildReady[gpId] ?? false) && !emittedMilitaryThisTurn) {
        rebuildReadyNoBuildTurns[gpId] =
            (rebuildReadyNoBuildTurns[gpId] ?? 0) + 1;
        if (scratch.turnInputsPresent[gpId] ?? false) {
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
      fabricStarvedThisTurn: scratch.fabricStarvedThisTurn,
      tradeOrdersByPlayerId: merged.tradeOrdersByPlayerId,
      emittedTurns: castIronLabourPeasantRecruitFabricBidEmittedTurns,
      absentTurns: castIronLabourPeasantRecruitFabricBidAbsentTurns,
    );

    // Refs #2847 § fabric offer-side split: on peasant-recruit fabric
    // market-path-active turns, record whether any other faction offered
    // `fabric` in trade orders this turn.
    recordSeed42S7dFabricMarketOfferCounters(
      fabricMarketPathActiveThisTurn: scratch.fabricMarketPathActiveThisTurn,
      tradeOrdersByPlayerId: merged.tradeOrdersByPlayerId,
      presentTurns: fabricMarketOfferPresentTurns,
      absentTurns: fabricMarketOfferAbsentTurns,
    );

    // Refs #2847 § castIron market-supply wall: on the feedstock-extraction
    // gate-active turns, record whether any other faction offered castIron
    // (the manufactured level-0 build_improvement input) this turn.
    recordSeed42S7dCastIronMarketOfferCounters(
      feedstockGateActiveThisTurn: scratch.feedstockGateActiveThisTurn,
      tradeOrdersByPlayerId: merged.tradeOrdersByPlayerId,
      castIronCommodityId:
          castIronProductionRecipe?.outputCommodityId ?? 'castIron',
      presentTurns: castIronMarketOfferPresentTurns,
      absentTurns: castIronMarketOfferAbsentTurns,
    );
  }
}
