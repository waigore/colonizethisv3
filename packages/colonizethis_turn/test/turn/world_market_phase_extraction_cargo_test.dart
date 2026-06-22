import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show defaultCargoHoldsStub;
import 'package:colonizethis_turn/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Cargo-released-by-extraction integration for the world market phase
/// (Refs #2990 B2 / SPEC/game/world-market.md § Cargo — AC *Cargo released
/// by under-used extraction*).
///
/// The world-market phase now subtracts the per-player overseas tonnage
/// shipped by the extraction phase (read from
/// [TurnPipelineState.overseasExtractionShippedTonnageByPlayerId]) from
/// the home-fleet cargo holds when sizing each Great Power's trade cargo
/// capacity. These tests assert the consumer side of that contract end to
/// end through [worldMarketTurnPhaseHandler] — the extraction handler's
/// populate side is exercised by
/// `extraction_phase_overseas_shipped_tonnage_test.dart`.
void main() {
  group(
    'worldMarketTurnPhaseHandler — extraction tonnage subtraction '
    '(Refs #2990 B2)',
    () {
      test(
        'tradeCapacity = homeFleetCargo − overseasShippedTonnage; '
        'bid partial-fills against the reduced cap',
        () {
          // No home fleet → cargoHoldsForHomeFleet returns the default stub
          // of 24 holds. Extraction shipped 12 of those holds this turn, so
          // remaining trade cargo = 24 − 12 = 12. The buyer bids 24 timber
          // at the matching offer, and the matcher must partial-fill at 12
          // (the released cargo) with the remaining 12 carrying forward.
          const buyerId = 'gpBuyer';
          const sellerId = 'gpSeller';
          final game = _gameWithTwoGps(
            sellerStockpile: const Stockpile().applyDelta('timber', 30),
            sellerTreasury: 0,
            buyerTreasury: 100000,
            marketPrices: const {'timber': 30},
          );
          // Sanity: the default stub for a player without a home fleet is
          // 24 — anchor the assertion on the public constant so the test
          // documents the arithmetic without re-coupling to internals.
          expect(defaultCargoHoldsStub, 24);

          final acc = TurnPipelineState(
            game: game,
            overseasExtractionShippedTonnageByPlayerId: const <String, int>{
              buyerId: 12,
            },
          );
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: Orders(
              tradeOrdersByPlayerId: {
                sellerId: [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.offer,
                    quantity: 24,
                    priority: 1,
                  ),
                ],
                buyerId: [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.bid,
                    quantity: 24,
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

          final buyer = next.players.firstWhere((p) => p.id == buyerId);
          expect(
            buyer.stockpile.quantityOf('timber'),
            12,
            reason:
                'bid capped by trade cargo capacity (24 stub − 12 extraction '
                'tonnage = 12 holds available for trade shipping)',
          );
          final carryBids =
              next.worldMarketState.carryForwardBidsByFactionId[buyerId];
          expect(carryBids, isNotNull);
          expect(carryBids!.single.commodityId, 'timber');
          expect(
            carryBids.single.quantity,
            12,
            reason:
                'residual 12 units of the 24-unit bid carry forward at the '
                'original priority',
          );
        },
      );

      test(
        'overseas shipped tonnage ≥ home-fleet capacity clamps trade cargo '
        'to 0 — no fills, full bid carry-forward',
        () {
          // Extraction shipped 24 holds (saturating the default stub) so
          // trade cargo capacity clamps at 0 for the buyer this turn. No
          // bid quantity should match.
          const buyerId = 'gpBuyer';
          const sellerId = 'gpSeller';
          final game = _gameWithTwoGps(
            sellerStockpile: const Stockpile().applyDelta('timber', 10),
            sellerTreasury: 0,
            buyerTreasury: 100000,
            marketPrices: const {'timber': 30},
          );
          final acc = TurnPipelineState(
            game: game,
            overseasExtractionShippedTonnageByPlayerId: const <String, int>{
              buyerId: 24,
            },
          );
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: Orders(
              tradeOrdersByPlayerId: {
                sellerId: [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.offer,
                    quantity: 5,
                    priority: 1,
                  ),
                ],
                buyerId: [
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

          final buyer = next.players.firstWhere((p) => p.id == buyerId);
          expect(
            buyer.stockpile.quantityOf('timber'),
            0,
            reason: 'tradeCapacity clamped to 0 leaves zero room for fills',
          );
          expect(
            buyer.treasury,
            100000,
            reason: 'no debit when no deal fills',
          );
          final carryBids =
              next.worldMarketState.carryForwardBidsByFactionId[buyerId];
          expect(carryBids, isNotNull);
          expect(carryBids!.single.quantity, 5);
        },
      );

      test(
        'overseas shipped tonnage exceeding home-fleet capacity does not '
        'underflow tradeCapacity (released-cargo clamp at 0)',
        () {
          // Tonnage > home-fleet capacity should still clamp at 0, never
          // negative. This guards against accidental signed arithmetic.
          const buyerId = 'gpBuyer';
          const sellerId = 'gpSeller';
          final game = _gameWithTwoGps(
            sellerStockpile: const Stockpile().applyDelta('timber', 5),
            sellerTreasury: 0,
            buyerTreasury: 1000,
            marketPrices: const {'timber': 30},
          );
          final acc = TurnPipelineState(
            game: game,
            overseasExtractionShippedTonnageByPlayerId: const <String, int>{
              buyerId: 999,
            },
          );
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: Orders(
              tradeOrdersByPlayerId: {
                sellerId: [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.offer,
                    quantity: 5,
                    priority: 1,
                  ),
                ],
                buyerId: [
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

          final buyer = next.players.firstWhere((p) => p.id == buyerId);
          expect(buyer.stockpile.quantityOf('timber'), 0);
          // The deal matcher must not have observed a negative capacity.
          // Carry-forward should preserve the full bid quantity.
          final carryBids =
              next.worldMarketState.carryForwardBidsByFactionId[buyerId];
          expect(carryBids, isNotNull);
          expect(carryBids!.single.quantity, 5);
        },
      );

      test(
        'missing tonnage entry defaults to 0 — buyer keeps full home-fleet '
        'capacity (legacy contract preserved)',
        () {
          // Empty extraction tonnage map → behaviour identical to the
          // pre-#2990 B2 handler: trade cargo capacity equals the full
          // home-fleet stub, so a 5-unit bid against a 5-unit offer fills
          // completely.
          const buyerId = 'gpBuyer';
          const sellerId = 'gpSeller';
          final game = _gameWithTwoGps(
            sellerStockpile: const Stockpile().applyDelta('timber', 5),
            sellerTreasury: 0,
            buyerTreasury: 1000,
            marketPrices: const {'timber': 30},
          );
          final acc = TurnPipelineState(game: game);
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: Orders(
              tradeOrdersByPlayerId: {
                sellerId: [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.offer,
                    quantity: 5,
                    priority: 1,
                  ),
                ],
                buyerId: [
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

          final buyer = next.players.firstWhere((p) => p.id == buyerId);
          expect(
            buyer.stockpile.quantityOf('timber'),
            5,
            reason:
                'no extraction tonnage on the pipeline state → full home-fleet '
                'cargo available for trade (matches the pre-B2 contract)',
          );
          expect(
            next.worldMarketState.carryForwardBidsByFactionId,
            isEmpty,
          );
        },
      );
    },
  );
}

Game _gameWithTwoGps({
  required Stockpile sellerStockpile,
  required int sellerTreasury,
  required int buyerTreasury,
  required Map<CommodityId, int> marketPrices,
}) {
  return Game(
    id: 'g1',
    players: [
      Player(
        id: 'gpSeller',
        displayName: 'Seller',
        isHuman: false,
        stockpile: sellerStockpile,
        treasury: sellerTreasury,
      ),
      Player(
        id: 'gpBuyer',
        displayName: 'Buyer',
        isHuman: false,
        stockpile: Stockpile.empty,
        treasury: buyerTreasury,
      ),
    ],
    worldState: const WorldState(
      turnState: TurnState(
        phase: TurnPhase.worldMarket,
        turnNumber: 3,
      ),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    worldMarketState: WorldMarketState.empty.copyWith(prices: marketPrices),
  );
}
