import 'dart:convert';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

/// Seed-42 Path F (World Market) lock-recovery diagnostic (Refs #2924).
///
/// Captures per-turn world-market metrics for each Great Power across the
/// 100-turn seed-42 horizon to identify why gp3-gp6 fail to cross
/// `cheapestRegimentBuildTreasuryCost()` purely from world-market sales.
///
/// Recorded per GP / per turn:
///   * trade orders emitted (offers, bids) and total quantity
///   * cargo holds available (home fleet)
///   * carry-forward queue size on entry
///   * deals filled as buyer / seller (count, quantity, treasury change)
///   * treasury before / after the world-market phase
///   * cumulative world-market credits (lifetime)
///   * turn-99 stockpile snapshot
///
/// Skipped by default (long-running, ~3 min). Re-run via
/// `dart test --run-skipped` when the lock-recovery surface changes.
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 100 Path F world-market diagnostic: per-GP per-turn '
    'trade emission / deal matching / treasury credit trace',
    () {
      final init = runInitGame(
        config: GameSetupConfig(seed: 42),
        options: const InitGameOptions(
          cellSize: 24,
          renderPng: false,
          skipFillLakes: false,
        ),
      );
      var game = init.game.copyWith(
        aiControlByGpId: {for (final p in init.game.players) p.id: true},
      );
      final topo = init.combinedTopology;
      final tileMap = init.tileMapByRegion;

      final gpIds = [for (var i = 1; i <= 6; i++) 'gp$i'];

      final treasuryBeforeTurn = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final treasuryAfterTurn = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final offersEmittedPerTurn = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final bidsEmittedPerTurn = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final offerQuantityEmittedPerTurn = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final cargoHoldsPerTurn = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final carryForwardOffersOnEntry = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final carryForwardBidsOnEntry = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final dealsAsSellerPerTurn = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final dealsAsBuyerPerTurn = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final treasuryGainAsSellerPerTurn = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final treasurySpentAsBuyerPerTurn = <String, List<int>>{
        for (final gpId in gpIds) gpId: <int>[],
      };
      final lifetimeSellerCredit = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final lifetimeBuyerSpend = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final maxTreasuryReached = <String, int>{
        for (final gpId in gpIds) gpId: -1 << 30,
      };
      final crossedThresholdAtTurn = <String, int?>{
        for (final gpId in gpIds) gpId: null,
      };

      final turn99Stockpile = <String, Map<CommodityId, int>>{};
      final turn99CarryOffers = <String, int>{};
      final turn99CarryBids = <String, int>{};
      final turn99HomeFleetShipTypes = <String, List<String>>{};

      // Per-commodity bid/offer/deal volume across the run (system-wide).
      final commodityNewBidQuantity = <CommodityId, int>{};
      final commodityNewOfferQuantity = <CommodityId, int>{};
      final commodityFilledQuantity = <CommodityId, int>{};

      // Per-commodity bid quantity per GP across the run (so we can see which
      // commodities each GP targeted with its capped bid slot).
      final commodityBidByGp = <String, Map<CommodityId, int>>{
        for (final gpId in gpIds) gpId: <CommodityId, int>{},
      };

      // Minimum treasury reached after the start-of-game baseline (the real
      // test of lock recovery: do failing GPs ever drop below the regiment
      // threshold and recover via market deals?).
      final minTreasuryReached = <String, int>{
        for (final gpId in gpIds) gpId: 1 << 30,
      };
      final finalTreasury = <String, int>{};
      final droppedBelowThresholdAtTurn = <String, int?>{
        for (final gpId in gpIds) gpId: null,
      };

      final threshold = cheapestRegimentBuildTreasuryCost();

      for (var t = 0; t < 100; t++) {
        // Capture per-GP entry state for this turn.
        for (final gpId in gpIds) {
          final player = game.playerById(gpId);
          final treasury = player?.treasury ?? 0;
          treasuryBeforeTurn[gpId]!.add(treasury);
          if (treasury > maxTreasuryReached[gpId]!) {
            maxTreasuryReached[gpId] = treasury;
          }
          if (treasury > threshold && crossedThresholdAtTurn[gpId] == null) {
            crossedThresholdAtTurn[gpId] = t;
          }
          final carryOffers = game.worldMarketState
              .carryForwardOffersByFactionId[gpId]
              ?.fold<int>(0, (s, o) => s + o.quantity);
          carryForwardOffersOnEntry[gpId]!.add(carryOffers ?? 0);
          final carryBids = game.worldMarketState
              .carryForwardBidsByFactionId[gpId]
              ?.fold<int>(0, (s, o) => s + o.quantity);
          carryForwardBidsOnEntry[gpId]!.add(carryBids ?? 0);
        }

        final fullAi = generateOrdersForGameFullAI(
          game,
          topo,
          tileMapByRegion: tileMap,
        );
        for (final gpId in gpIds) {
          final orders = fullAi.orders.tradeOrdersByPlayerId[gpId] ??
              const <TradeOrder>[];
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

        final merged = mergeOrderLists(
          humanOrders: const Orders(),
          aiOrders: fullAi.orders,
        );
        final assignments = fullAi.economyPlansByPlayerId.map(
          (pid, plan) => MapEntry(pid, plan.productionAssignments),
        );
        final treasuriesBefore = <String, int>{
          for (final gpId in gpIds) gpId: game.playerById(gpId)?.treasury ?? 0,
        };
        final result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: fullAi.game,
          topology: topo,
          orders: merged,
          tileMapByRegion: tileMap,
          defaultAssignmentsByPlayerId: assignments,
        );
        expect(result, isA<TurnResolutionComplete>());
        game = (result as TurnResolutionComplete).game;

        // Per-turn deal aggregates from the resolved world-market activity.
        final perGpSellerDeals = <String, int>{for (final id in gpIds) id: 0};
        final perGpBuyerDeals = <String, int>{for (final id in gpIds) id: 0};
        final perGpSellerCredit = <String, int>{for (final id in gpIds) id: 0};
        final perGpBuyerSpend = <String, int>{for (final id in gpIds) id: 0};
        for (final entry in game.worldMarketState.lastTurnActivity.entries) {
          final commodityId = entry.key;
          final activity = entry.value;
          commodityFilledQuantity[commodityId] =
              (commodityFilledQuantity[commodityId] ?? 0) +
                  activity.filledQuantity;
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
          if (after < threshold &&
              droppedBelowThresholdAtTurn[gpId] == null) {
            droppedBelowThresholdAtTurn[gpId] = t;
          }
          if (after > threshold && crossedThresholdAtTurn[gpId] == null) {
            crossedThresholdAtTurn[gpId] = t;
          }
          finalTreasury[gpId] = after;
          // Suppress unused variable warning.
          treasuriesBefore[gpId];
        }
        if (t == 99) {
          final fleetsById = fleetsByIdForWorld(game.worldState);
          for (final gpId in gpIds) {
            final player = game.playerById(gpId);
            turn99Stockpile[gpId] = <CommodityId, int>{
              for (final entry in (player?.stockpile.quantities.entries ??
                  const <MapEntry<CommodityId, int>>[]))
                if (entry.value > 0) entry.key: entry.value,
            };
            turn99CarryOffers[gpId] = game.worldMarketState
                    .carryForwardOffersByFactionId[gpId]
                    ?.fold<int>(0, (s, o) => s + o.quantity) ??
                0;
            turn99CarryBids[gpId] = game.worldMarketState
                    .carryForwardBidsByFactionId[gpId]
                    ?.fold<int>(0, (s, o) => s + o.quantity) ??
                0;
            final homeFleetId = 'fleet_$gpId';
            final fleet = fleetsById[homeFleetId];
            turn99HomeFleetShipTypes[gpId] = fleet?.shipTypeIds.toList() ??
                const <String>[];
          }
        }
      }

      int sum(List<int> xs) => xs.fold<int>(0, (a, b) => a + b);
      int avg(List<int> xs) =>
          xs.isEmpty ? 0 : (xs.fold<int>(0, (a, b) => a + b) / xs.length).round();

      final diagnostic = <String, Object?>{
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
              'totalOfferQuantityEmitted':
                  sum(offerQuantityEmittedPerTurn[gpId]!),
              'avgCargoHolds': avg(cargoHoldsPerTurn[gpId]!),
              'maxCargoHolds': cargoHoldsPerTurn[gpId]!.fold<int>(
                  0, (a, b) => a > b ? a : b),
              'totalDealsAsSeller': sum(dealsAsSellerPerTurn[gpId]!),
              'totalDealsAsBuyer': sum(dealsAsBuyerPerTurn[gpId]!),
              'maxCarryForwardOffersOnEntry':
                  carryForwardOffersOnEntry[gpId]!
                      .fold<int>(0, (a, b) => a > b ? a : b),
              'maxCarryForwardBidsOnEntry':
                  carryForwardBidsOnEntry[gpId]!
                      .fold<int>(0, (a, b) => a > b ? a : b),
            }
        },
        'turn99HomeFleetShipTypes': turn99HomeFleetShipTypes,
        'turn99CarryOffers': turn99CarryOffers,
        'turn99CarryBids': turn99CarryBids,
        'turn99Stockpile': turn99Stockpile,
      };

      CtLogger.level = Level.info;
      final log = aiLogger('s7d-world-market');
      log.i('S7D_WORLD_MARKET_DIAGNOSTIC_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(diagnostic));
      log.i('S7D_WORLD_MARKET_DIAGNOSTIC_JSON_END');

      // Lightweight assertion: turn loop ran for every GP.
      for (final gpId in gpIds) {
        expect(treasuryAfterTurn[gpId]!.length, 100);
      }
    },
    skip:
        'Refs #2924: long-running (~3 min) per-GP per-turn world-market '
        'diagnostic. Re-run with `dart test --run-skipped` when the Path F '
        'lock-recovery surface changes.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
