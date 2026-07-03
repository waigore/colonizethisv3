import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_turn/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/world_market_test_support.dart';

/// Per-commodity Deal Book ledger emission tests for the World Market phase
/// handler (Refs #2993 E6 / #2988 § UI Design — Deal Book).
///
/// SPEC anchors:
/// - `SPEC/program/world-market-resolution.md` § Step F Activity rollup
///   (`MarketActivity.deals` carries the per-commodity `FilledDeal` list).
/// - `SPEC/ui/trade-screen.md` § Deal Book tab (consumes
///   `Game.worldMarketState.lastTurnActivity[commodity].deals`).
void main() {
  group(
    'worldMarketTurnPhaseHandler — Deal Book ledger emission '
    '(Refs #2993 E6, SPEC/program/world-market-resolution.md § Step F)',
    () {
      test(
        'GP↔GP fill emits a FilledDeal on the resolved commodity activity',
        () {
          final acc = TurnPipelineState(
            game: gameWithTwoGps(
              sellerStockpile: const Stockpile().applyDelta('timber', 10),
              sellerTreasury: 0,
              buyerTreasury: 1000,
              marketPrices: const {'timber': 30},
            ),
          );
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: Orders(
              tradeOrdersByPlayerId: {
                'gpSeller': [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.offer,
                    quantity: 5,
                    priority: 1,
                  ),
                ],
                'gpBuyer': [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.bid,
                    quantity: 5,
                    priority: 1,
                  ),
                ],
              },
            ),
          );

          final next = (worldMarketTurnPhaseHandler(acc, config, 3)
                  as TurnPhaseStepContinue)
              .pipeline
              .game;

          final activity = next.worldMarketState.lastTurnActivity['timber']!;
          expect(activity.deals, hasLength(1));
          final deal = activity.deals.single;
          expect(deal.sellerFactionId, 'gpSeller');
          expect(deal.buyerFactionId, 'gpBuyer');
          expect(deal.commodityId, 'timber');
          expect(deal.quantity, 5);
          expect(deal.pricePerUnit, closeTo(30.0, 1e-9));
          expect(deal.isFirstRightOfRefusalMatch, isFalse);
          expect(deal.isFtpMatch, isFalse);
        },
      );

      test(
        'multi-commodity matching emits deals scoped to each commodity',
        () {
          final acc = TurnPipelineState(
            game: gameWithTwoGps(
              sellerStockpile: const Stockpile()
                  .applyDelta('timber', 10)
                  .applyDelta('iron', 4),
              sellerTreasury: 0,
              buyerTreasury: 10000,
              marketPrices: const {'timber': 30, 'iron': 80},
            ),
          );
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: Orders(
              tradeOrdersByPlayerId: {
                'gpSeller': [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.offer,
                    quantity: 5,
                    priority: 1,
                  ),
                  TradeOrder(
                    commodityId: 'iron',
                    type: TradeOrderType.offer,
                    quantity: 3,
                    priority: 1,
                  ),
                ],
                'gpBuyer': [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.bid,
                    quantity: 5,
                    priority: 1,
                  ),
                  TradeOrder(
                    commodityId: 'iron',
                    type: TradeOrderType.bid,
                    quantity: 3,
                    priority: 1,
                  ),
                ],
              },
            ),
          );

          final next = (worldMarketTurnPhaseHandler(acc, config, 3)
                  as TurnPhaseStepContinue)
              .pipeline
              .game;

          final timberDeals =
              next.worldMarketState.lastTurnActivity['timber']!.deals;
          final ironDeals =
              next.worldMarketState.lastTurnActivity['iron']!.deals;
          expect(timberDeals, hasLength(1));
          expect(timberDeals.single.commodityId, 'timber');
          expect(timberDeals.single.quantity, 5);
          expect(ironDeals, hasLength(1));
          expect(ironDeals.single.commodityId, 'iron');
          expect(ironDeals.single.quantity, 3);
          // Each commodity activity only carries its own deals — no
          // cross-commodity leakage.
          expect(
            timberDeals.map((d) => d.commodityId).toSet(),
            equals(<String>{'timber'}),
          );
          expect(
            ironDeals.map((d) => d.commodityId).toSet(),
            equals(<String>{'iron'}),
          );
        },
      );

      test(
        'commodity with no fills carries empty deals list',
        () {
          // Offer-only turn: the matcher emits no fills, so the activity
          // entry for the commodity must carry an empty deals list (not
          // null, not absent — the UI iterates deals.where(buyer/seller)).
          final acc = TurnPipelineState(
            game: gameWithTwoGps(
              sellerStockpile: const Stockpile().applyDelta('timber', 10),
              sellerTreasury: 0,
              buyerTreasury: 0,
              marketPrices: const {'timber': 30},
            ),
          );
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: Orders(
              tradeOrdersByPlayerId: {
                'gpSeller': [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.offer,
                    quantity: 5,
                    priority: 1,
                  ),
                ],
              },
            ),
          );

          final next = (worldMarketTurnPhaseHandler(acc, config, 3)
                  as TurnPhaseStepContinue)
              .pipeline
              .game;

          final activity = next.worldMarketState.lastTurnActivity['timber']!;
          expect(activity.filledQuantity, 0);
          expect(activity.deals, isEmpty);
          // The default `MarketActivity()` deals constant is the canonical
          // shared const; emitted activity must also expose an empty (not
          // null) list with `==` semantics matching the empty default.
          expect(
            activity.deals,
            equals(const <FilledDeal>[]),
          );
        },
      );

      test(
        'partial fill emits one deal at the matched quantity, residual '
        'carries forward but no extra deal appears',
        () {
          // Seller has only 3 timber for a 10-bid: matcher emits a single
          // FilledDeal of 3 units; the bid's residual 7 carries forward via
          // `unfilledBidsByFactionId`. The activity deal list must contain
          // exactly the matched portion, not the residual.
          final acc = TurnPipelineState(
            game: gameWithTwoGps(
              sellerStockpile: const Stockpile().applyDelta('timber', 3),
              sellerTreasury: 0,
              buyerTreasury: 1000,
              marketPrices: const {'timber': 30},
            ),
          );
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: Orders(
              tradeOrdersByPlayerId: {
                'gpSeller': [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.offer,
                    quantity: 3,
                    priority: 1,
                  ),
                ],
                'gpBuyer': [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.bid,
                    quantity: 10,
                    priority: 1,
                  ),
                ],
              },
            ),
          );

          final next = (worldMarketTurnPhaseHandler(acc, config, 3)
                  as TurnPhaseStepContinue)
              .pipeline
              .game;

          final activity = next.worldMarketState.lastTurnActivity['timber']!;
          expect(activity.filledQuantity, 3);
          expect(activity.deals, hasLength(1));
          expect(activity.deals.single.quantity, 3);
          // Residual is on the carry-forward queue, not in the deal list.
          final carriedBids = next
              .worldMarketState
              .carryForwardBidsByFactionId['gpBuyer'];
          expect(carriedBids, isNotNull);
          expect(carriedBids!.single.quantity, 7);
        },
      );

      test(
        'empty-turn semantics: no activity entries, no deals',
        () {
          final priorMarket = WorldMarketState.empty.copyWith(
            prices: const {'timber': 30},
          );
          final acc = TurnPipelineState(
            game: gameWithTwoGps(
              sellerStockpile: Stockpile.empty,
              sellerTreasury: 0,
              buyerTreasury: 0,
              marketPrices: const {'timber': 30},
            ).copyWith(worldMarketState: priorMarket),
          );
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: const Orders(),
          );

          final next = (worldMarketTurnPhaseHandler(acc, config, 3)
                  as TurnPhaseStepContinue)
              .pipeline
              .game;

          expect(next.worldMarketState.lastTurnActivity, isEmpty);
        },
      );
    },
  );
}
