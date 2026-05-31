import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Integration tests for `DefaultOrderSuggestionAPI.suggestTradeOrders` per
/// `SPEC/program/world-market-resolution.md` § Trade order suggestion API
/// § Default `OrderSuggestionAPI` wiring. Refs #2989 A6.
///
/// The pure suggester logic is exercised in
/// `world_market_trade_order_suggester_test.dart`; these tests verify the
/// `DefaultOrderSuggestionAPI` wiring derives the context conservatively
/// (current-turn stockpile minus riches; `worldMarketBidTypeCap`;
/// `cargoHoldsForHomeFleet`) so the impl never proposes orders that
/// would violate `TradeOrderValidator`.
void main() {
  group('DefaultOrderSuggestionAPI.suggestTradeOrders — wiring', () {
    test(
      'no embassy ⇒ bidTypeCap = 0; suggester emits offers only from current '
      'stockpile (riches excluded) and no bids',
      () {
        const ow = 'oldWorld';
        final stockpile = const Stockpile()
            .applyDelta('timber', 12)
            .applyDelta('iron', 4)
            .applyDelta('gold', 99); // riches → must not be offered
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'A',
              isHuman: false,
              capitalProvinceId: '$ow|p1',
              stockpile: stockpile,
            ),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        const api = DefaultOrderSuggestionAPI();
        final result = api.suggestTradeOrders(view, game);
        expect(result.bids, isEmpty);
        final offerIds =
            result.offers.map((o) => o.commodityId).toSet();
        expect(offerIds, containsAll(<String>{'iron', 'timber'}));
        expect(
          offerIds.intersection(richesCommodityIds.toSet()),
          isEmpty,
          reason: 'Riches must not appear in trade offers (rule 2).',
        );
      },
    );

    test('contextOverride passes through to the pure suggester', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(
            phase: TurnPhase.orders,
            turnNumber: 1,
          ),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            capitalProvinceId: 'oldWorld|p1',
          ),
        ],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      const api = DefaultOrderSuggestionAPI();
      final result = api.suggestTradeOrders(
        view,
        game,
        contextOverride: const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 100,
          commodityNeedByCommodityId: {'timber': 5},
        ),
      );
      expect(result.offers, isEmpty);
      expect(result.bids, hasLength(1));
      expect(result.bids.single.commodityId, 'timber');
      expect(result.bids.single.quantity, 5);
    });

    test(
      'default impl returns validator-clean output for the wired context',
      () {
        const ow = 'oldWorld';
        final stockpile =
            const Stockpile().applyDelta('timber', 8).applyDelta('iron', 3);
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'A',
              isHuman: false,
              capitalProvinceId: '$ow|p1',
              stockpile: stockpile,
            ),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        const api = DefaultOrderSuggestionAPI();
        final result = api.suggestTradeOrders(view, game);
        final available = <CommodityId, int>{
          for (final entry in stockpile.quantities.entries)
            if (!richesCommodityIds.contains(entry.key)) entry.key: entry.value,
        };
        final all = <TradeOrder>[...result.offers, ...result.bids];
        final validatorResults = TradeOrderValidator.validate(
          context: TradeOrderValidationContext(
            playerId: 'gp1',
            bidTypeCap: worldMarketBidTypeCap(game, 'gp1'),
            tradeCargoCapacity: cargoHoldsForHomeFleet(game, 'gp1'),
            availableStockpileByCommodityId: available,
          ),
          proposedOrders: all,
        );
        for (final r in validatorResults) {
          expect(r.isAccepted, isTrue, reason: r.reason);
        }
      },
    );
  });
}
