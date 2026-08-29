// Per-turn WM2924 diagnostic campaign callbacks (Refs #2924 / #4602 Slice E).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/seed42_observer_world_market_diagnostic_support.dart';

class Seed42WorldMarketPerTurnDiagnosticState {
  final Map<String, List<Seed42WorldMarketTurnRow>> perTurnRows = {
    for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
      gpId: <Seed42WorldMarketTurnRow>[],
  };
  final Map<String, Map<String, int>> offerQuantityByCommodityByGp = {
    for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
      gpId: <String, int>{},
  };
  final Map<String, Map<String, int>> sellerDealQuantityByCommodityByGp = {
    for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
      gpId: <String, int>{},
  };
  final Map<int, Seed42PendingWorldMarketTurn> pendingByTurn = {};

  void onBeforeResolve(
    int turn,
    FullAIResult fullAi,
    Game game,
    MapTopology topo,
  ) {
    final preTurnSnapshot =
        <
          String,
          ({
            int treasuryStart,
            int cargo,
            int bidTypeCap,
            int cfOffers,
            int cfBids,
            ObserverGoalPhase phase,
          })
        >{};
    for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) {
      final view = buildPlayerView(game, topo, gpId);
      final snap = AIWorldSnapshot.fromPlayerView(view, topology: topo);
      final outcome = runPhasePlanners(game: game, snapshot: snap);
      final player = game.playerById(gpId);
      final treasuryStart = player?.treasury ?? 0;
      final cargo = cargoHoldsForHomeFleet(game, gpId);
      final bidTypeCap = worldMarketBidTypeCap(game, gpId);
      final cfOffers =
          (game.worldMarketState.carryForwardOffersByFactionId[gpId] ??
          const <TradeOrder>[]);
      final cfBids =
          (game.worldMarketState.carryForwardBidsByFactionId[gpId] ??
          const <TradeOrder>[]);
      preTurnSnapshot[gpId] = (
        treasuryStart: treasuryStart,
        cargo: cargo < 0 ? 0 : cargo,
        bidTypeCap: bidTypeCap,
        cfOffers: cfOffers.length,
        cfBids: cfBids.length,
        phase: outcome.phase,
      );
    }

    final emittedThisTurn =
        <String, ({int offers, int bids, int offerQty, int bidQty})>{};
    for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) {
      final orders =
          fullAi.orders.tradeOrdersByPlayerId[gpId] ?? const <TradeOrder>[];
      var offers = 0;
      var bids = 0;
      var offerQty = 0;
      var bidQty = 0;
      for (final o in orders) {
        switch (o.type) {
          case TradeOrderType.offer:
            offers += 1;
            offerQty += o.quantity;
            offerQuantityByCommodityByGp[gpId]![o.commodityId] =
                (offerQuantityByCommodityByGp[gpId]![o.commodityId] ?? 0) +
                o.quantity;
          case TradeOrderType.bid:
            bids += 1;
            bidQty += o.quantity;
        }
      }
      emittedThisTurn[gpId] = (
        offers: offers,
        bids: bids,
        offerQty: offerQty,
        bidQty: bidQty,
      );
    }

    pendingByTurn[turn] = Seed42PendingWorldMarketTurn(
      preTurnSnapshot: preTurnSnapshot,
      emittedThisTurn: emittedThisTurn,
    );
  }

  void onAfterResolve(int turn, Game resolved) {
    final pending = pendingByTurn.remove(turn);
    if (pending == null) {
      fail(
        'Refs #2924 per-turn diagnostic: missing pre-resolve snapshot '
        'for turn $turn.',
      );
    }

    final dealCountsAsSeller = <String, int>{
      for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) gpId: 0,
    };
    final treasuryCreditedAsSeller = <String, int>{
      for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) gpId: 0,
    };
    final dealCountsAsBuyer = <String, int>{
      for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) gpId: 0,
    };
    final treasurySpentAsBuyer = <String, int>{
      for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) gpId: 0,
    };
    for (final activity in resolved.worldMarketState.lastTurnActivity.values) {
      for (final deal in activity.deals) {
        final dealValue = (deal.quantity * deal.pricePerUnit).round();
        if (dealCountsAsSeller.containsKey(deal.sellerFactionId)) {
          dealCountsAsSeller[deal.sellerFactionId] =
              (dealCountsAsSeller[deal.sellerFactionId] ?? 0) + 1;
          treasuryCreditedAsSeller[deal.sellerFactionId] =
              (treasuryCreditedAsSeller[deal.sellerFactionId] ?? 0) + dealValue;
          sellerDealQuantityByCommodityByGp[deal.sellerFactionId]![deal
                  .commodityId] =
              (sellerDealQuantityByCommodityByGp[deal.sellerFactionId]![deal
                      .commodityId] ??
                  0) +
              deal.quantity;
        }
        if (dealCountsAsBuyer.containsKey(deal.buyerFactionId)) {
          dealCountsAsBuyer[deal.buyerFactionId] =
              (dealCountsAsBuyer[deal.buyerFactionId] ?? 0) + 1;
          treasurySpentAsBuyer[deal.buyerFactionId] =
              (treasurySpentAsBuyer[deal.buyerFactionId] ?? 0) + dealValue;
        }
      }
    }

    for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) {
      final pre = pending.preTurnSnapshot[gpId]!;
      final emit = pending.emittedThisTurn[gpId]!;
      final treasuryEnd = resolved.playerById(gpId)?.treasury ?? 0;
      perTurnRows[gpId]!.add(
        Seed42WorldMarketTurnRow(
          turn: turn,
          phase: pre.phase,
          treasuryStart: pre.treasuryStart,
          treasuryEnd: treasuryEnd,
          tradeCargoCapacity: pre.cargo,
          bidTypeCap: pre.bidTypeCap,
          offersEmitted: emit.offers,
          bidsEmitted: emit.bids,
          offerQuantityTotal: emit.offerQty,
          bidQuantityTotal: emit.bidQty,
          carryForwardOffersCount: pre.cfOffers,
          carryForwardBidsCount: pre.cfBids,
          dealsAsSeller: dealCountsAsSeller[gpId] ?? 0,
          treasuryCreditedAsSeller: treasuryCreditedAsSeller[gpId] ?? 0,
          dealsAsBuyer: dealCountsAsBuyer[gpId] ?? 0,
          treasurySpentAsBuyer: treasurySpentAsBuyer[gpId] ?? 0,
        ),
      );
    }
  }

  Map<String, Object?> buildDiagnosticJson(int cheapest) {
    final gpRollup = <String, Object?>{
      for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
        gpId: buildSeed42WorldMarketGpRollup(
          rows: perTurnRows[gpId]!,
          offerQuantityByCommodity:
              kSeed42WorldMarketDiagnosticFailingGreatPowerIds.contains(gpId)
              ? offerQuantityByCommodityByGp[gpId]!
              : const <String, int>{},
          sellerDealQuantityByCommodity:
              kSeed42WorldMarketDiagnosticFailingGreatPowerIds.contains(gpId)
              ? sellerDealQuantityByCommodityByGp[gpId]!
              : const <String, int>{},
          cheapestRegimentBuildTreasuryCost: cheapest,
        ),
    };

    return <String, Object?>{
      'issue': 2924,
      'subtask': 'world-market-per-turn-diagnostic',
      'seed': 42,
      'turns': 100,
      'cheapestRegimentBuildTreasuryCost': cheapest,
      'failingGreatPowerIds':
          kSeed42WorldMarketDiagnosticFailingGreatPowerIds.toList()..sort(),
      'perCommodityTopN': kSeed42WorldMarketDiagnosticPerCommodityTopN,
      'gpRollup': gpRollup,
      'gpPerTurnRows': {
        for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
          gpId: [for (final r in perTurnRows[gpId]!) r.toJson()],
      },
    };
  }
}
