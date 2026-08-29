// Path F world-market lock-recovery diagnostic state + callbacks (Refs #2924 / #4602 Slice E).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

class Seed42WorldMarketLockRecoveryDiagnosticState {
  Seed42WorldMarketLockRecoveryDiagnosticState(this.gpIds)
    : treasuryBeforeTurn = {for (final gpId in gpIds) gpId: <int>[]},
      treasuryAfterTurn = {for (final gpId in gpIds) gpId: <int>[]},
      offersEmittedPerTurn = {for (final gpId in gpIds) gpId: <int>[]},
      bidsEmittedPerTurn = {for (final gpId in gpIds) gpId: <int>[]},
      offerQuantityEmittedPerTurn = {for (final gpId in gpIds) gpId: <int>[]},
      cargoHoldsPerTurn = {for (final gpId in gpIds) gpId: <int>[]},
      carryForwardOffersOnEntry = {for (final gpId in gpIds) gpId: <int>[]},
      carryForwardBidsOnEntry = {for (final gpId in gpIds) gpId: <int>[]},
      dealsAsSellerPerTurn = {for (final gpId in gpIds) gpId: <int>[]},
      dealsAsBuyerPerTurn = {for (final gpId in gpIds) gpId: <int>[]},
      treasuryGainAsSellerPerTurn = {for (final gpId in gpIds) gpId: <int>[]},
      treasurySpentAsBuyerPerTurn = {for (final gpId in gpIds) gpId: <int>[]},
      lifetimeSellerCredit = {for (final gpId in gpIds) gpId: 0},
      lifetimeBuyerSpend = {for (final gpId in gpIds) gpId: 0},
      maxTreasuryReached = {for (final gpId in gpIds) gpId: -1 << 30},
      crossedThresholdAtTurn = {for (final gpId in gpIds) gpId: null},
      commodityBidByGp = {for (final gpId in gpIds) gpId: <CommodityId, int>{}},
      minTreasuryReached = {for (final gpId in gpIds) gpId: 1 << 30},
      droppedBelowThresholdAtTurn = {for (final gpId in gpIds) gpId: null};

  final List<String> gpIds;
  final Map<String, List<int>> treasuryBeforeTurn;
  final Map<String, List<int>> treasuryAfterTurn;
  final Map<String, List<int>> offersEmittedPerTurn;
  final Map<String, List<int>> bidsEmittedPerTurn;
  final Map<String, List<int>> offerQuantityEmittedPerTurn;
  final Map<String, List<int>> cargoHoldsPerTurn;
  final Map<String, List<int>> carryForwardOffersOnEntry;
  final Map<String, List<int>> carryForwardBidsOnEntry;
  final Map<String, List<int>> dealsAsSellerPerTurn;
  final Map<String, List<int>> dealsAsBuyerPerTurn;
  final Map<String, List<int>> treasuryGainAsSellerPerTurn;
  final Map<String, List<int>> treasurySpentAsBuyerPerTurn;
  final Map<String, int> lifetimeSellerCredit;
  final Map<String, int> lifetimeBuyerSpend;
  final Map<String, int> maxTreasuryReached;
  final Map<String, int?> crossedThresholdAtTurn;
  final Map<CommodityId, int> commodityNewBidQuantity = {};
  final Map<CommodityId, int> commodityNewOfferQuantity = {};
  final Map<CommodityId, int> commodityFilledQuantity = {};
  final Map<String, Map<CommodityId, int>> commodityBidByGp;
  final Map<String, int> minTreasuryReached;
  final Map<String, int> finalTreasury = {};
  final Map<String, int?> droppedBelowThresholdAtTurn;
  final Map<String, Map<CommodityId, int>> turn99Stockpile = {};
  final Map<String, int> turn99CarryOffers = {};
  final Map<String, int> turn99CarryBids = {};
  final Map<String, List<String>> turn99HomeFleetShipTypes = {};

  void onBeforeResolve(
    int turn,
    FullAIResult fullAi,
    Game game,
    int threshold,
  ) {
    for (final gpId in gpIds) {
      final player = game.playerById(gpId);
      final treasury = player?.treasury ?? 0;
      treasuryBeforeTurn[gpId]!.add(treasury);
      if (treasury > maxTreasuryReached[gpId]!) {
        maxTreasuryReached[gpId] = treasury;
      }
      if (treasury > threshold && crossedThresholdAtTurn[gpId] == null) {
        crossedThresholdAtTurn[gpId] = turn;
      }
      final carryOffers = game.worldMarketState.carryForwardOffersByFactionId[gpId]
          ?.fold<int>(0, (s, o) => s + o.quantity);
      carryForwardOffersOnEntry[gpId]!.add(carryOffers ?? 0);
      final carryBids = game.worldMarketState.carryForwardBidsByFactionId[gpId]
          ?.fold<int>(0, (s, o) => s + o.quantity);
      carryForwardBidsOnEntry[gpId]!.add(carryBids ?? 0);

      final orders =
          fullAi.orders.tradeOrdersByPlayerId[gpId] ?? const <TradeOrder>[];
      final offers = orders.where((o) => o.type == TradeOrderType.offer);
      final bids = orders.where((o) => o.type == TradeOrderType.bid);
      offersEmittedPerTurn[gpId]!.add(offers.length);
      bidsEmittedPerTurn[gpId]!.add(bids.length);
      offerQuantityEmittedPerTurn[gpId]!.add(
        offers.fold<int>(0, (s, o) => s + o.quantity),
      );
      for (final o in offers) {
        commodityNewOfferQuantity[o.commodityId] =
            (commodityNewOfferQuantity[o.commodityId] ?? 0) + o.quantity;
      }
      for (final b in bids) {
        commodityNewBidQuantity[b.commodityId] =
            (commodityNewBidQuantity[b.commodityId] ?? 0) + b.quantity;
        commodityBidByGp[gpId]![b.commodityId] =
            (commodityBidByGp[gpId]![b.commodityId] ?? 0) + b.quantity;
      }
      final fleetsById = fleetsByIdForWorld(game.worldState);
      cargoHoldsPerTurn[gpId]!.add(
        cargoHoldsForHomeFleet(game, gpId, fleetsById: fleetsById),
      );
    }
  }

  void onAfterResolve(int turn, Game game, int threshold) {
    final perGpSellerDeals = <String, int>{for (final id in gpIds) id: 0};
    final perGpBuyerDeals = <String, int>{for (final id in gpIds) id: 0};
    final perGpSellerCredit = <String, int>{for (final id in gpIds) id: 0};
    final perGpBuyerSpend = <String, int>{for (final id in gpIds) id: 0};
    for (final entry in game.worldMarketState.lastTurnActivity.entries) {
      final commodityId = entry.key;
      final activity = entry.value;
      commodityFilledQuantity[commodityId] =
          (commodityFilledQuantity[commodityId] ?? 0) + activity.filledQuantity;
      for (final deal in activity.deals) {
        final notional = (deal.quantity * deal.pricePerUnit).round();
        if (perGpSellerDeals.containsKey(deal.sellerFactionId)) {
          perGpSellerDeals[deal.sellerFactionId] =
              perGpSellerDeals[deal.sellerFactionId]! + 1;
          perGpSellerCredit[deal.sellerFactionId] =
              perGpSellerCredit[deal.sellerFactionId]! + notional;
        }
        if (perGpBuyerDeals.containsKey(deal.buyerFactionId)) {
          perGpBuyerDeals[deal.buyerFactionId] =
              perGpBuyerDeals[deal.buyerFactionId]! + 1;
          perGpBuyerSpend[deal.buyerFactionId] =
              perGpBuyerSpend[deal.buyerFactionId]! + notional;
        }
      }
    }
    for (final gpId in gpIds) {
      dealsAsSellerPerTurn[gpId]!.add(perGpSellerDeals[gpId]!);
      dealsAsBuyerPerTurn[gpId]!.add(perGpBuyerDeals[gpId]!);
      treasuryGainAsSellerPerTurn[gpId]!.add(perGpSellerCredit[gpId]!);
      treasurySpentAsBuyerPerTurn[gpId]!.add(perGpBuyerSpend[gpId]!);
      lifetimeSellerCredit[gpId] =
          lifetimeSellerCredit[gpId]! + perGpSellerCredit[gpId]!;
      lifetimeBuyerSpend[gpId] =
          lifetimeBuyerSpend[gpId]! + perGpBuyerSpend[gpId]!;
      final after = game.playerById(gpId)?.treasury ?? 0;
      treasuryAfterTurn[gpId]!.add(after);
      if (after > maxTreasuryReached[gpId]!) {
        maxTreasuryReached[gpId] = after;
      }
      if (after < minTreasuryReached[gpId]!) {
        minTreasuryReached[gpId] = after;
      }
      if (after < threshold && droppedBelowThresholdAtTurn[gpId] == null) {
        droppedBelowThresholdAtTurn[gpId] = turn;
      }
      if (after > threshold && crossedThresholdAtTurn[gpId] == null) {
        crossedThresholdAtTurn[gpId] = turn;
      }
      finalTreasury[gpId] = after;
    }
    if (turn == 99) {
      final fleetsById = fleetsByIdForWorld(game.worldState);
      for (final gpId in gpIds) {
        final player = game.playerById(gpId);
        turn99Stockpile[gpId] = <CommodityId, int>{
          for (final entry
              in (player?.stockpile.quantities.entries ??
                  const <MapEntry<CommodityId, int>>[]))
            if (entry.value > 0) entry.key: entry.value,
        };
        turn99CarryOffers[gpId] =
            game.worldMarketState.carryForwardOffersByFactionId[gpId]
                ?.fold<int>(0, (s, o) => s + o.quantity) ??
            0;
        turn99CarryBids[gpId] =
            game.worldMarketState.carryForwardBidsByFactionId[gpId]
                ?.fold<int>(0, (s, o) => s + o.quantity) ??
            0;
        final homeFleetId = 'fleet_$gpId';
        final fleet = fleetsById[homeFleetId];
        turn99HomeFleetShipTypes[gpId] =
            fleet?.shipTypeIds.toList() ?? const <String>[];
      }
    }
  }

  Map<String, Object?> buildDiagnosticJson(int threshold) {
    int sum(List<int> xs) => xs.fold<int>(0, (a, b) => a + b);
    int avg(List<int> xs) => xs.isEmpty
        ? 0
        : (xs.fold<int>(0, (a, b) => a + b) / xs.length).round();

    return <String, Object?>{
      'issue': 2924,
      'subtask': 'Step 0 — Path F detail',
      'seed': 42,
      'turns': 100,
      'cheapestRegimentBuildTreasuryCost': threshold,
      'crossedThresholdAtTurn': crossedThresholdAtTurn,
      'droppedBelowThresholdAtTurn': droppedBelowThresholdAtTurn,
      'maxTreasuryReached': maxTreasuryReached,
      'minTreasuryReached': minTreasuryReached,
      'finalTreasury': finalTreasury,
      'lifetimeSellerCredit': lifetimeSellerCredit,
      'lifetimeBuyerSpend': lifetimeBuyerSpend,
      'commodityNewBidQuantity': commodityNewBidQuantity,
      'commodityNewOfferQuantity': commodityNewOfferQuantity,
      'commodityFilledQuantity': commodityFilledQuantity,
      'commodityBidByGp': commodityBidByGp,
      'perGpAggregates': {
        for (final gpId in gpIds)
          gpId: {
            'totalOffersEmitted': sum(offersEmittedPerTurn[gpId]!),
            'totalBidsEmitted': sum(bidsEmittedPerTurn[gpId]!),
            'totalOfferQuantityEmitted': sum(offerQuantityEmittedPerTurn[gpId]!),
            'avgCargoHolds': avg(cargoHoldsPerTurn[gpId]!),
            'maxCargoHolds': cargoHoldsPerTurn[gpId]!.fold<int>(
              0,
              (a, b) => a > b ? a : b,
            ),
            'totalDealsAsSeller': sum(dealsAsSellerPerTurn[gpId]!),
            'totalDealsAsBuyer': sum(dealsAsBuyerPerTurn[gpId]!),
            'maxCarryForwardOffersOnEntry': carryForwardOffersOnEntry[gpId]!
                .fold<int>(0, (a, b) => a > b ? a : b),
            'maxCarryForwardBidsOnEntry': carryForwardBidsOnEntry[gpId]!
                .fold<int>(0, (a, b) => a > b ? a : b),
          },
      },
      'turn99HomeFleetShipTypes': turn99HomeFleetShipTypes,
      'turn99CarryOffers': turn99CarryOffers,
      'turn99CarryBids': turn99CarryBids,
      'turn99Stockpile': turn99Stockpile,
    };
  }
}
