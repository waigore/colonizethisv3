// Integration tests for `worldMarketTurnPhaseHandler` minor/tribe auto-offer
// wiring (Refs #2991 C4).
//
// Anchors:
//   - SPEC/program/world-market-resolution.md § Step A Gather (Step A.2),
//     § Step D Apply transfers (Minor/Tribe sellers), § Treasury sink.
//   - SPEC/game/world-market.md § Minor and tribe auto-sell.
//
// The auto-offer pipeline only fires when `tileMapByRegion` is supplied on
// `TurnResolverConfig`; without it the world-market phase preserves the
// legacy GP↔GP behavior so the existing direct-handler tests stay green.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_logic/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_logic/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group(
    'worldMarketTurnPhaseHandler — minor/tribe auto-offer wiring (Refs #2991 C4)',
    () {
      test(
        'minor timber tile auto-emits a priority-1 offer that fills a GP '
        "bid; minor receives no treasury (sink); buyer's stockpile and "
        'treasury reflect the deal',
        () {
          final game = _gameWithBuyerAndMinor(
            buyerTreasury: 1000,
            timberPrice: 30.0,
          );
          final acc = TurnPipelineState(game: game);
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: Orders(
              tradeOrdersByPlayerId: {
                'gpBuyer': [
                  TradeOrder(
                    commodityId: 'timber',
                    type: TradeOrderType.bid,
                    quantity: 1,
                    priority: 1,
                  ),
                ],
              },
            ),
            tileMapByRegion: {'oldWorld': _minorTimberTileMap()},
          );

          final next =
              (worldMarketTurnPhaseHandler(acc, config, 3)
                      as TurnPhaseStepContinue)
                  .pipeline
                  .game;

          final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
          expect(buyer.treasury, equals(1000 - 1 * 30));
          expect(buyer.stockpile.quantityOf('timber'), equals(1));

          // Minors do not appear in `Game.players`, so the matcher treats
          // the auto-offer as a treasury-sink seller: no faction is credited.
          expect(
            next.players.where((p) => p.id == 'm1'),
            isEmpty,
            reason: 'minors are never stored as `Player` entries',
          );

          final activity = next.worldMarketState.lastTurnActivity['timber'];
          expect(activity, isNotNull);
          expect(activity!.filledQuantity, equals(1));
          // Auto-offers are excluded from price-discovery aggregation: only
          // the GP-submitted bid contributes to `totalBidQuantity`, and the
          // offer side reports 0 because the auto-offer was emitted by the
          // system, not submitted by a GP. (Per SPEC § Price discovery,
          // current-turn newly-submitted GP quantities only.)
          expect(activity.totalBidQuantity, equals(1));
          expect(activity.totalOfferQuantity, equals(0));
          expect(activity.deals, hasLength(1));
          expect(activity.deals.first.sellerFactionId, equals('m1'));
          expect(activity.deals.first.buyerFactionId, equals('gpBuyer'));
          expect(activity.deals.first.quantity, equals(1));
          expect(
            activity.deals.first.sellerOriginTileKey,
            equals('oldWorld|m1|0|0'),
            reason:
                'auto-offers carry originTileKey so FRR (#2992 D2/D4) can '
                'attribute purchased-tile flows',
          );
        },
      );

      test(
        'auto-offers do not carry forward — without a GP bid the minor '
        'offer disappears at end of turn (Step E: minor/tribe auto-offers '
        'do not carry forward)',
        () {
          final game = _gameWithBuyerAndMinor(
            buyerTreasury: 0,
            timberPrice: 30.0,
          );
          final acc = TurnPipelineState(game: game);
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: const Orders(),
            tileMapByRegion: {'oldWorld': _minorTimberTileMap()},
          );

          final next =
              (worldMarketTurnPhaseHandler(acc, config, 3)
                      as TurnPhaseStepContinue)
                  .pipeline
                  .game;

          expect(
            next.worldMarketState.carryForwardOffersByFactionId['m1'],
            isNull,
            reason:
                'minor/tribe auto-offers must not carry forward per '
                'SPEC/program/world-market-resolution.md § Step E',
          );
          expect(
            next.worldMarketState.carryForwardBidsByFactionId,
            isEmpty,
          );
        },
      );

      test(
        'auto-offer pipeline is dormant when `tileMapByRegion` is absent — '
        'GP↔GP legacy direct-handler path stays unaffected',
        () {
          final game = _gameWithBuyerAndMinor(
            buyerTreasury: 0,
            timberPrice: 30.0,
          );
          final acc = TurnPipelineState(game: game);
          final config = TurnResolverConfig(
            topology: const MapTopology(nodes: [], edges: []),
            orders: const Orders(),
          );

          final next =
              (worldMarketTurnPhaseHandler(acc, config, 3)
                      as TurnPhaseStepContinue)
                  .pipeline
                  .game;

          expect(
            next.worldMarketState.lastTurnActivity,
            isEmpty,
            reason: 'no auto-offers should be emitted without tile data',
          );
          expect(
            next.worldMarketState.carryForwardOffersByFactionId,
            isEmpty,
          );
        },
      );
    },
  );
}

Game _gameWithBuyerAndMinor({
  required int buyerTreasury,
  required double timberPrice,
}) {
  final minorProvince = Province(
    id: 'oldWorld|m1',
    regionId: 'oldWorld',
    ownerId: 'm1',
    townDevelopmentLevel: 1,
  );
  return Game(
    id: 'g_auto_offer',
    players: [
      Player(
        id: 'gpBuyer',
        displayName: 'Buyer',
        isHuman: false,
        stockpile: Stockpile.empty,
        treasury: buyerTreasury,
      ),
    ],
    minorNations: const [
      MinorNation(
        id: 'm1',
        capitalProvinceId: 'oldWorld|m1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|m1',
          x: 0,
          y: 0,
        ),
      ),
    ],
    worldState: WorldState(
      turnState: const TurnState(
        phase: TurnPhase.worldMarket,
        turnNumber: 3,
      ),
      oldWorld: RegionData(provinces: [minorProvince]),
      newWorld: const RegionData(),
      tileState: TileMapState()
          .setImprovement('oldWorld|m1|0|0', 1)
          .setRoadLevel('oldWorld|m1|0|0', 1),
    ),
    worldMarketState: WorldMarketState.empty.copyWith(
      prices: {'timber': timberPrice},
    ),
  );
}

TileMapResult _minorTimberTileMap() {
  return TileMapResult(
    width: 1,
    height: 1,
    grid: [
      ['m1'],
    ],
    resourceGrid: [
      [Resource.timber],
    ],
  );
}
