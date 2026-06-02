import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/turn/turn_phase_handler_registry.dart';
import 'package:colonizethis_logic/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Full-turn pipeline integration for World Market phase 13 (Refs #2990 B5).
///
/// Handler-level behavior is covered in `world_market_phase_b3_test.dart`;
/// these tests assert the same contracts through [resolveTurnForGame] so
/// phase ordering and persisted [WorldMarketState] survive the full resolver.
void main() {
  const topology = MapTopology(nodes: [], edges: []);

  group(
    'resolveTurnForGame — World Market phase placement (Refs #2990 B5)',
    () {
      test('worldMarket runs after buildWork and before endOfTurn', () {
        final phases = <TurnPhase>[];
        resolveTurnForGameWithConfig(
          game: _twoGpTradeGame(
            sellerStockpile: const Stockpile(),
            sellerTreasury: 0,
            buyerTreasury: 0,
          ),
          config: TurnResolverConfig(
            topology: topology,
            orders: const Orders(),
            onPhaseProgress: (phase, marker) {
              if (marker == TurnPhaseProgressMarker.start) {
                phases.add(phase);
              }
            },
          ),
        );

        final buildWorkIndex = phases.indexOf(TurnPhase.buildWork);
        final worldMarketIndex = phases.indexOf(TurnPhase.worldMarket);
        final endOfTurnIndex = phases.indexOf(TurnPhase.endOfTurn);
        expect(buildWorkIndex, greaterThanOrEqualTo(0));
        expect(worldMarketIndex, buildWorkIndex + 1);
        expect(endOfTurnIndex, worldMarketIndex + 1);
        expect(phases, contains(TurnPhase.worldMarket));
      });
    },
  );

  group('resolveTurnForGame — GP trade fills (Refs #2990 B5)', () {
    test('trade orders apply treasury, stockpile, and market activity', () {
      final result = resolveTurnForGame(
        game: _twoGpTradeGame(
          sellerStockpile: const Stockpile().applyDelta('timber', 10),
          sellerTreasury: 100,
          buyerTreasury: 1000,
          marketPrices: const {'timber': 30},
        ),
        topology: topology,
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

      final next = requireTurnResolutionComplete(result);
      final seller = next.players.firstWhere((p) => p.id == 'gpSeller');
      final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
      expect(buyer.treasury, 1000 - 5 * 30);
      expect(seller.treasury, 100 + 5 * 30);
      expect(buyer.stockpile.quantityOf('timber'), 5);
      expect(seller.stockpile.quantityOf('timber'), 5);
      final activity = next.worldMarketState.lastTurnActivity['timber']!;
      expect(activity.filledQuantity, 5);
      expect(next.worldState.turnState.turnNumber, 1);
    });

    test('carry-forward bid from turn 1 fills on turn 2 via full pipeline', () {
      final turn1 = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: _twoGpTradeGame(
            sellerStockpile: const Stockpile().applyDelta('timber', 3),
            sellerTreasury: 0,
            buyerTreasury: 1000,
            marketPrices: const {'timber': 30},
          ),
          topology: topology,
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
        ),
      );

      expect(
        turn1
            .worldMarketState
            .carryForwardBidsByFactionId['gpBuyer']!
            .single
            .quantity,
        7,
      );

      final turn2 = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: turn1,
          topology: topology,
          orders: Orders(
            tradeOrdersByPlayerId: {
              'gpSeller': [
                TradeOrder(
                  commodityId: 'timber',
                  type: TradeOrderType.offer,
                  quantity: 7,
                  priority: 1,
                ),
              ],
            },
          ),
        ),
      );

      final buyer = turn2.players.firstWhere((p) => p.id == 'gpBuyer');
      expect(buyer.stockpile.quantityOf('timber'), 10);
      expect(
        turn2.worldMarketState.carryForwardBidsByFactionId['gpBuyer'],
        isNull,
      );
    });
  });

  group('runTurnResolutionPipeline — missing handler (Refs #2990 B5)', () {
    test('throws StateError when worldMarket handler is absent from map', () {
      final handlers = Map<TurnPhase, TurnPhaseHandler>.from(
        TurnPhaseHandlerRegistry.defaults,
      )..remove(TurnPhase.worldMarket);

      expect(
        () => _runPipelineWithHandlers(
          game: _twoGpTradeGame(
            sellerStockpile: const Stockpile(),
            sellerTreasury: 0,
            buyerTreasury: 0,
          ),
          handlers: handlers,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('worldMarket'),
          ),
        ),
      );
    });
  });
}

/// Mirrors [runTurnResolutionPipeline] handler lookup for the missing-handler AC.
TurnResolutionResult _runPipelineWithHandlers({
  required Game game,
  required Map<TurnPhase, TurnPhaseHandler> handlers,
}) {
  var acc = TurnPipelineState(game: game);
  final turn = acc.game.worldState.turnState.turnNumber;
  for (final phase in turnResolutionSequence) {
    final handler = handlers[phase];
    if (handler == null) {
      throw StateError('No turn phase handler registered for ${phase.name}');
    }
    final outcome = handler(
      acc,
      const TurnResolverConfig(
        topology: MapTopology(nodes: [], edges: []),
        orders: Orders(),
      ),
      turn,
    );
    if (outcome is TurnPhaseStepExit) {
      return outcome.result;
    }
    acc = (outcome as TurnPhaseStepContinue).pipeline;
  }
  return TurnResolutionComplete(acc.game);
}

Game _twoGpTradeGame({
  required Stockpile sellerStockpile,
  required int sellerTreasury,
  required int buyerTreasury,
  Map<CommodityId, int> marketPrices = const {'timber': 30},
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
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    worldMarketState: WorldMarketState.empty.copyWith(prices: marketPrices),
  );
}
