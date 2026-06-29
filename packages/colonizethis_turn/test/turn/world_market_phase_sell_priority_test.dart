import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';

import '../test_fixtures.dart';

/// Phase-handler integration for the #3753 R7.3 sell-priority relation
/// tiebreaker. Minor M1 auto-offers a limited quantity; two GPs bid for it at
/// the same priority. The consulate-holding buyer with the higher relation
/// wins the limited supply; consulate-less buyers fall back; GP sellers are
/// unaffected (R7.4).
///
/// SPEC anchors:
/// - `SPEC/game/world-market.md` § Sell-priority relation tiebreaker.
/// - `SPEC/program/world-market-resolution.md` § Step B item 4 + ACs.
const _ow = 'oldWorld';
const _minorProvinceId = '$_ow|M1';
const _tileKey = '$_ow|M1|0|0';

Game _sellPriorityGame({
  required int gpHighRelation,
  required int gpLowRelation,
  required List<OvertureState> overtureStates,
  String minorSellerId = 'M1',
}) {
  return TestFixtures.minimalGame(
    players: const [
      Player(
        id: 'gpHigh',
        displayName: 'GP High',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
      Player(
        id: 'gpLow',
        displayName: 'GP Low',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(id: _minorProvinceId, regionId: _ow, ownerId: 'M1'),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      _ow: {
        _minorProvinceId: [_tileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gpHigh',
        factionId2: minorSellerId,
        score: gpHighRelation,
      ),
      DiplomacyRelation(
        factionId1: 'gpLow',
        factionId2: minorSellerId,
        score: gpLowRelation,
      ),
    ],
    overtureStates: overtureStates,
  ).copyWith(
    worldMarketState: WorldMarketState.empty.copyWith(
      prices: const {'timber': 10},
    ),
  );
}

Game _runPhase({
  required Game game,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
}) {
  final acc = TurnPipelineState(game: game);
  final config = TurnResolverConfig(
    topology: const MapTopology(nodes: [], edges: []),
    orders: Orders(tradeOrdersByPlayerId: tradeOrdersByPlayerId),
  );
  return (worldMarketTurnPhaseHandler(acc, config, 3) as TurnPhaseStepContinue)
      .pipeline
      .game;
}

List<TradeOrder> _minorOffer(int quantity) => [
  TradeOrder(
    commodityId: 'timber',
    type: TradeOrderType.offer,
    quantity: quantity,
    priority: 1,
    originTileKey: _tileKey,
  ),
];

List<TradeOrder> _bid(int quantity) => [
  TradeOrder(
    commodityId: 'timber',
    type: TradeOrderType.bid,
    quantity: quantity,
    priority: 1,
  ),
];

void main() {
  group('worldMarketTurnPhaseHandler — #3753 R7.3 sell-priority', () {
    test('higher-relation consulate-holding buyer wins limited supply', () {
      final next = _runPhase(
        game: _sellPriorityGame(
          gpHighRelation: 80,
          gpLowRelation: 40,
          overtureStates: const [
            OvertureState(
              gpId: 'gpHigh',
              targetId: 'M1',
              stage: OvertureStage.tradeConsulate,
            ),
            OvertureState(
              gpId: 'gpLow',
              targetId: 'M1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
        ),
        tradeOrdersByPlayerId: {
          'M1': _minorOffer(5),
          'gpLow': _bid(5),
          'gpHigh': _bid(5),
        },
      );

      // M1 only sells 5 units; the higher-relation consulate holder wins them.
      expect(
        next.players.firstWhere((p) => p.id == 'gpHigh').stockpile.quantityOf(
          'timber',
        ),
        5,
      );
      expect(
        next.players.firstWhere((p) => p.id == 'gpLow').stockpile.quantityOf(
          'timber',
        ),
        0,
      );
      // gpLow's bid carries forward in full.
      expect(next.worldMarketState.carryForwardBidsByFactionId['gpLow'], [
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 5,
          priority: 1,
        ),
      ]);
    });

    test('consulate-less higher-relation buyer falls back behind holder', () {
      final next = _runPhase(
        game: _sellPriorityGame(
          gpHighRelation: 90,
          gpLowRelation: 30,
          // gpHigh holds NO overture with M1 (consulate-less); only gpLow does.
          overtureStates: const [
            OvertureState(
              gpId: 'gpLow',
              targetId: 'M1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
        ),
        tradeOrdersByPlayerId: {
          'M1': _minorOffer(5),
          'gpLow': _bid(5),
          'gpHigh': _bid(5),
        },
      );

      // The only consulate-holding buyer (gpLow) wins despite lower relation.
      expect(
        next.players.firstWhere((p) => p.id == 'gpLow').stockpile.quantityOf(
          'timber',
        ),
        5,
      );
      expect(
        next.players.firstWhere((p) => p.id == 'gpHigh').stockpile.quantityOf(
          'timber',
        ),
        0,
      );
    });

    test('embassy (higher than consulate) satisfies the gate', () {
      final next = _runPhase(
        game: _sellPriorityGame(
          gpHighRelation: 70,
          gpLowRelation: 95,
          overtureStates: const [
            OvertureState(
              gpId: 'gpHigh',
              targetId: 'M1',
              stage: OvertureStage.embassy,
            ),
            OvertureState(
              gpId: 'gpLow',
              targetId: 'M1',
              stage: OvertureStage.embassy,
            ),
          ],
        ),
        tradeOrdersByPlayerId: {
          'M1': _minorOffer(5),
          'gpHigh': _bid(5),
          'gpLow': _bid(5),
        },
      );

      // Both hold embassy (≥ consulate); gpLow's relation 95 > 70 wins.
      expect(
        next.players.firstWhere((p) => p.id == 'gpLow').stockpile.quantityOf(
          'timber',
        ),
        5,
      );
    });

    test('GP seller is unaffected by the tiebreaker (R7.4)', () {
      // gpSell is a Great Power offering timber (not a minor/tribe), so the
      // builder excludes it from the relation map and default ordering applies.
      // Default order is ascending faction id → gpA wins even though the
      // relation that WOULD apply favours gpZ.
      final game =
          TestFixtures.minimalGame(
            players: const [
              Player(
                id: 'gpA',
                displayName: 'GP A',
                isHuman: false,
                treasury: 1000,
                stockpile: Stockpile.empty,
              ),
              Player(
                id: 'gpSell',
                displayName: 'GP Seller',
                isHuman: false,
                treasury: 0,
                // Seller stock so the GP-seller credit path is realistic.
                stockpile: Stockpile(quantities: {'timber': 5}),
              ),
              Player(
                id: 'gpZ',
                displayName: 'GP Z',
                isHuman: false,
                treasury: 1000,
                stockpile: Stockpile.empty,
              ),
            ],
            // No minor/tribe sellers participate here.
            diplomacyRelations: const [
              DiplomacyRelation(
                factionId1: 'gpA',
                factionId2: 'gpSell',
                score: 10,
              ),
              DiplomacyRelation(
                factionId1: 'gpZ',
                factionId2: 'gpSell',
                score: 90,
              ),
            ],
          ).copyWith(
            worldMarketState: WorldMarketState.empty.copyWith(
              prices: const {'timber': 10},
            ),
          );

      final next = _runPhase(
        game: game,
        tradeOrdersByPlayerId: {
          'gpSell': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 5,
              priority: 1,
            ),
          ],
          'gpA': _bid(5),
          'gpZ': _bid(5),
        },
      );

      // Default ascending-faction-id ordering: gpA wins the GP seller's offer.
      expect(
        next.players.firstWhere((p) => p.id == 'gpA').stockpile.quantityOf(
          'timber',
        ),
        5,
      );
      expect(
        next.players.firstWhere((p) => p.id == 'gpZ').stockpile.quantityOf(
          'timber',
        ),
        0,
      );
    });
  });
}
