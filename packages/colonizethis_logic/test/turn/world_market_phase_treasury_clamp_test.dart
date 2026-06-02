import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_logic/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_logic/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Phase-handler coverage for the world-market treasury clamp (Refs #3115).
///
/// SPEC anchors:
/// - `SPEC/program/world-market-resolution.md` § Step C (treasury clamp,
///   matchQty formula, running tally, truncation note).
/// - `SPEC/program/world-market-resolution.md` § Step E (bid-side
///   filled-quantity aggregation for price discovery).
/// - `SPEC/game/world-market.md` § Treasury budget for bids
///   (resolver-side enforcement).
void main() {
  group('worldMarketTurnPhaseHandler — treasury clamp (Refs #3115)', () {
    test(
      'AC#1 — treasury 100, bid 10 @ 30 with offer 10 fills only 3; '
      'treasury post-phase = 10; residual 7 carries forward',
      () {
        final acc = TurnPipelineState(
          game: _gameWithTwoGps(
            sellerStockpile: const Stockpile().applyDelta('timber', 10),
            sellerTreasury: 0,
            buyerTreasury: 100,
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
                  quantity: 10,
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

        final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
        expect(buyer.treasury, 10,
            reason: 'buyer post-phase treasury = 100 - 3*30 = 10');
        expect(buyer.stockpile.quantityOf('timber'), 3);

        final carryBids =
            next.worldMarketState.carryForwardBidsByFactionId['gpBuyer'];
        expect(carryBids, isNotNull);
        expect(carryBids!.single.commodityId, 'timber');
        expect(carryBids.single.quantity, 7);
        expect(carryBids.single.priority, 1);

        final notes = next
            .worldMarketState.lastTurnActivity['timber']!.notes
            .where(
              (n) =>
                  n.kind ==
                  MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
            )
            .toList();
        expect(notes, hasLength(1),
            reason: 'exactly one treasury-insufficient note per truncated bid');
        expect(notes.single.factionId, 'gpBuyer');
        expect(notes.single.quantity, 10,
            reason: 'note carries the original submitted bid quantity');
      },
    );

    test(
      'AC#2 — treasury 100, two tier-1 bids of 5 @ 20 each: '
      'A fills 5, B fills 0 and carries forward; post-phase treasury = 0',
      () {
        final acc = TurnPipelineState(
          game: _gameWithTwoGps(
            sellerStockpile: const Stockpile()
                .applyDelta('alpha', 5)
                .applyDelta('beta', 5),
            sellerTreasury: 0,
            buyerTreasury: 100,
            marketPrices: const {'alpha': 20, 'beta': 20},
          ),
        );
        final config = TurnResolverConfig(
          topology: const MapTopology(nodes: [], edges: []),
          orders: Orders(
            tradeOrdersByPlayerId: {
              'gpSeller': [
                TradeOrder(
                  commodityId: 'alpha',
                  type: TradeOrderType.offer,
                  quantity: 5,
                  priority: 1,
                ),
                TradeOrder(
                  commodityId: 'beta',
                  type: TradeOrderType.offer,
                  quantity: 5,
                  priority: 1,
                ),
              ],
              'gpBuyer': [
                TradeOrder(
                  commodityId: 'alpha',
                  type: TradeOrderType.bid,
                  quantity: 5,
                  priority: 1,
                ),
                TradeOrder(
                  commodityId: 'beta',
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

        final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
        expect(buyer.treasury, 0,
            reason: 'A fully fills (100 spent); B emits no fill');
        expect(buyer.stockpile.quantityOf('alpha'), 5);
        expect(buyer.stockpile.quantityOf('beta'), 0);

        final carryBids =
            next.worldMarketState.carryForwardBidsByFactionId['gpBuyer'];
        expect(carryBids, isNotNull);
        expect(carryBids!.single.commodityId, 'beta');
        expect(carryBids.single.quantity, 5,
            reason: 'B preserves full submitted quantity as carry-forward');
      },
    );

    test(
      'AC#3 — negative-treasury buyer fully suppressed; all bids carry '
      'forward at submitted quantity; treasury unchanged',
      () {
        final acc = TurnPipelineState(
          game: _gameWithTwoGps(
            sellerStockpile: const Stockpile().applyDelta('timber', 10),
            sellerTreasury: 0,
            buyerTreasury: -50,
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
                  quantity: 10,
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

        final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
        expect(buyer.treasury, -50,
            reason: 'no fills, treasury unchanged from start-of-phase');
        expect(buyer.stockpile.quantityOf('timber'), 0);

        final carryBids =
            next.worldMarketState.carryForwardBidsByFactionId['gpBuyer'];
        expect(carryBids, isNotNull);
        expect(carryBids!.single.quantity, 10,
            reason: 'full submitted quantity carries forward');
      },
    );

    test(
      'AC#7 — price discovery: totalBid_new[c] reports filled portion '
      'of newly-submitted bids (not submitted quantity)',
      () {
        // S = 10 submitted bid, F = 3 filled (treasury-truncated); offer
        // submitted = 10. Expected: totalBidQuantity = 3, totalOfferQuantity
        // = 10.
        final acc = TurnPipelineState(
          game: _gameWithTwoGps(
            sellerStockpile: const Stockpile().applyDelta('timber', 10),
            sellerTreasury: 0,
            buyerTreasury: 100,
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
                  quantity: 10,
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

        final activity =
            next.worldMarketState.lastTurnActivity['timber']!;
        expect(activity.totalBidQuantity, 3,
            reason: 'filled portion of newly-submitted bids only');
        expect(activity.totalOfferQuantity, 10,
            reason: 'submitted offer quantity (offers are stockpile-bounded)');
        expect(activity.filledQuantity, 3);
      },
    );

    test(
      'price discovery: bid-side cap shifts Δ% toward offer dominance '
      'when treasury clamps bids',
      () {
        // With submitted bids 10, submitted offers 10, no treasury cap:
        // Δ% = 0 → price unchanged. With treasury truncating bids to 3,
        // Δ% should be negative (10 offers vs 3 bids); price drops by
        // the capped amount (subject to the 30%-of-base floor).
        final basePriceTimber = 30; // matches ResourceRules baseline
        final acc = TurnPipelineState(
          game: _gameWithTwoGps(
            sellerStockpile: const Stockpile().applyDelta('timber', 10),
            sellerTreasury: 0,
            buyerTreasury: 100,
            marketPrices: {'timber': basePriceTimber},
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
                  quantity: 10,
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

        final priceAfter = next.worldMarketState.prices['timber']!;
        expect(priceAfter, lessThan(basePriceTimber),
            reason:
                'low-treasury bid no longer inflates Δ%; offer-dominant '
                'aggregate pushes price down');
      },
    );

    test('treasury never goes negative under any resolved phase outcome', () {
      // Defense for the SPEC purpose: no scenario should leave treasury
      // negative after phase 13 application. Sweep across a few price
      // points to guard against integer-rounding edge cases.
      for (final price in const [7, 13, 30]) {
        final acc = TurnPipelineState(
          game: _gameWithTwoGps(
            sellerStockpile: const Stockpile().applyDelta('timber', 50),
            sellerTreasury: 0,
            buyerTreasury: 100,
            marketPrices: {'timber': price},
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
                  quantity: 50,
                  priority: 1,
                ),
              ],
              'gpBuyer': [
                TradeOrder(
                  commodityId: 'timber',
                  type: TradeOrderType.bid,
                  quantity: 50,
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

        final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
        expect(buyer.treasury, greaterThanOrEqualTo(0),
            reason: 'buyer treasury must not go negative at price $price');
      }
    });

    test('full-fill happy path unchanged when treasury is sufficient', () {
      // Regression guard: with abundant treasury the clamp is inert; the
      // baseline GP↔GP fill (matches `world_market_phase_b3_test`) still
      // produces a 5-unit deal at old price 30.
      final acc = TurnPipelineState(
        game: _gameWithTwoGps(
          sellerStockpile: const Stockpile().applyDelta('timber', 10),
          sellerTreasury: 100,
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

      final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
      expect(buyer.treasury, 1000 - 5 * 30);
      expect(buyer.stockpile.quantityOf('timber'), 5);

      final activity =
          next.worldMarketState.lastTurnActivity['timber']!;
      expect(activity.totalBidQuantity, 5);
      expect(activity.filledQuantity, 5);
      expect(activity.notes, isEmpty,
          reason: 'no truncation notes when treasury is sufficient');
    });
  });
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
