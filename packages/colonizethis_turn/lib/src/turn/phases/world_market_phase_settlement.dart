import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show boycottBlockedTradePairKeys, ftpPairKeysFromGame;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';
import 'world_market_phase_activity.dart';
import 'world_market_phase_credits.dart';
import 'world_market_phase_overseas_profit_events.dart';
import 'world_market_phase_deals.dart';
import 'world_market_phase_gather.dart';
import 'world_market_phase_orders.dart';
import 'world_market_phase_price_discovery.dart';
import 'world_market_phase_sell_priority.dart';

/// Applies match results, price discovery, and market-state persistence for
/// phase 13 Steps D–F. Refs #4113 slice C.
TurnPhaseStepOutcome settleWorldMarketMatch({
  required TurnPipelineState acc,
  required WorldMarketGatherResult gather,
  required WorldMarketState priorMarket,
  required TurnResolverConfig config,
  required int turn,
}) {
  final game = acc.game;

  final ftpPairKeys = ftpPairKeysFromGame(game);
  final purchasedTileIndex = PurchasedTileIndex.fromGame(game);
  final boycottBlockedPairKeys = boycottBlockedTradePairKeys(game);

  final sellPriorityRelationByMinorTribeSeller = computeSellPriorityRelations(
    game: game,
    offersByFactionId: gather.mergedOffersByFactionId,
  );

  final matchInputs = (
    offersByFactionId: gather.mergedOffersByFactionId,
    bidsByFactionId: gather.mergedBidsByFactionId,
    tradeCapacityByFactionId: gather.tradeCapacityByFactionId,
    treasuryBudgetByBuyerFactionId: gather.treasuryBudgetByBuyerFactionId,
    pricesByCommodityId: <CommodityId, double>{
      for (final entry in priorMarket.prices.entries)
        entry.key: entry.value.toDouble(),
    },
    ftpPairKeys: ftpPairKeys,
    purchasedTileIndex: purchasedTileIndex,
    lockRecoverySellerPriorityIds: gather.lockRecoverySellerPriorityIds,
    treasuryByFactionId: gather.treasuryByFactionId,
    sellPriorityRelationByMinorTribeSeller:
        sellPriorityRelationByMinorTribeSeller,
    boycottBlockedPairKeys: boycottBlockedPairKeys,
  );
  final matchResult = DealMatcher.matchDeals(matchInputs);

  final firstRightCredits = computeWorldMarketFirstRightCredits(
    game: game,
    filledDeals: matchResult.filledDeals,
    purchasedTileIndex: purchasedTileIndex,
  );

  final lockRecoveryLiquidityCommodityId =
      gather.lockRecoveryMinorBidsByFactionId.isEmpty
      ? null
      : gather.lockRecoveryMinorBidsByFactionId.values.first.first.commodityId;

  final subsidyPercentByPayerTargetKey = <String, int>{
    for (final s in game.subsidyStates)
      if (s.percent > 0) '${s.payerId}>${s.targetId}': s.percent,
  };

  final updatedPlayers = applyDealsToPlayers(
    players: game.players,
    filledDeals: matchResult.filledDeals,
    firstRightTreasuryCreditByGpId: firstRightCredits.treasuryCreditByGpId,
    embassyKickbackTreasuryCreditByGpId:
        firstRightCredits.embassyKickbackByGpId,
    lockRecoverySellerPriorityIds: gather.lockRecoverySellerPriorityIds,
    lockRecoveryLiquidityCommodityId: lockRecoveryLiquidityCommodityId,
    subsidyPercentByPayerTargetKey: subsidyPercentByPayerTargetKey,
  );

  final filledNewBidsByCommodity = aggregateFilledNewBidsByCommodity(
    newBidsByFactionId: gather.newBidsByFactionId,
    filledDeals: matchResult.filledDeals,
  );
  final priceDiscoveryByCommodity = buildPriceDiscoveryPairs(
    newQuantitiesByCommodity: gather.newQuantitiesByCommodity,
    filledNewBidsByCommodity: filledNewBidsByCommodity,
  );

  final newPrices = computeNextPrices(
    priorPrices: priorMarket.prices,
    newQuantitiesByCommodity: priceDiscoveryByCommodity,
  );

  final activity = buildActivity(
    matchResult: matchResult,
    newQuantitiesByCommodity: priceDiscoveryByCommodity,
    priorPrices: priorMarket.prices,
    newPrices: newPrices,
  );
  attachMatcherNotes(activity: activity, matchResult: matchResult);
  attachDropNotes(
    activity: activity,
    notesByCommodity: gather.carryForwardValidation.dropNotesByCommodity,
  );

  final gpFactionIds = <String>{for (final p in game.players) p.id};
  final completedTradePairKeys = completedTradePairKeysFromDeals(
    filledDeals: matchResult.filledDeals,
    gpFactionIds: gpFactionIds,
  );
  final overseasProfitRecords = buildWorldMarketOverseasProfitCreditRecords(
    game: game,
    filledDeals: matchResult.filledDeals,
    credits: firstRightCredits,
    purchasedTileIndex: purchasedTileIndex,
  );
  emitOverseasProfitCreditedEvents(
    recordsByGpId: overseasProfitRecords,
    turn: turn,
    sink: config.eventSink,
  );
  final updatedMarket = priorMarket.copyWith(
    prices: Map<CommodityId, int>.unmodifiable(newPrices),
    lastTurnActivity: Map<CommodityId, MarketActivity>.unmodifiable(activity),
    carryForwardOffersByFactionId: restrictToFactions(
      matchResult.unfilledOffersByFactionId,
      gpFactionIds,
    ),
    carryForwardBidsByFactionId: matchResult.unfilledBidsByFactionId,
    completedTradePairKeys: completedTradePairKeys,
    lastTurnOverseasProfitCreditsByGpId: overseasProfitRecords,
  );

  final nextGame = game
      .withPlayers(updatedPlayers)
      .copyWith(worldMarketState: updatedMarket);
  return TurnPhaseStepContinue(acc.copyWith(game: nextGame));
}
