import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_logic/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_logic/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

/// Phase-handler integration for the First Right of Refusal overseas-profit
/// treasury credit (Refs #2992 D4).
///
/// SPEC anchors:
///
/// - `SPEC/game/world-market.md` § Trade orders / Order persistence and
///   Requirement 9 (treasury sink for minor/tribe sellers, with the FRR
///   overseas-profit credit as the only exception).
/// - `SPEC/game/world-market-first-right-of-refusal.md` § Treasury transfer
///   (D4) and the per-deal profit formula
///   `profitRate = clamp(relationScore / 100 * 0.40, 0.0, 0.40)`.
/// - `SPEC/program/world-market-resolution.md` § Phase resolution Step E.
///
/// The unit-level credit aggregation contract is covered by
/// `first_right_credits_test.dart` / `first_right_credits_aggregation_test.dart`;
/// these tests prove the phase handler **invokes** that aggregation against
/// the matcher output and applies the resulting treasury credit map to GP
/// player treasuries (additive on top of any GP-seller credit) without
/// disturbing the standard treasury-sink behaviour for minor/tribe sales.
void main() {
  const ow = 'oldWorld';
  const minorProvinceId = '$ow|M1';
  const tileKey = '$ow|M1|0|0';

  group('worldMarketTurnPhaseHandler applies First Right of Refusal '
      'overseas-profit credit to owning GP (Refs #2992 D4 integration)', () {
    test('GP B buys minor M1\'s timber from gpA\'s purchased tile: gpA '
        'receives `quantity * price * 0.30` credit at relation score 75', () {
      final game = _frrIntegrationGame(
        initialOwningGpTreasury: 100,
        initialBuyerGpTreasury: 1000,
        relationScore: 75,
        marketPrices: const {'timber': 20.0},
      );
      final acc = TurnPipelineState(game: game);
      final config = TurnResolverConfig(
        topology: const MapTopology(nodes: [], edges: []),
        orders: Orders(
          tradeOrdersByPlayerId: {
            'M1': [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.offer,
                quantity: 10,
                priority: 1,
                originTileKey: tileKey,
              ),
            ],
            'gpB': [
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

      final next =
          (worldMarketTurnPhaseHandler(acc, config, 3) as TurnPhaseStepContinue)
              .pipeline
              .game;

      final gpA = next.players.firstWhere((p) => p.id == 'gpA');
      final gpB = next.players.firstWhere((p) => p.id == 'gpB');
      // gpA does not bid — its treasury changes only via the FRR
      // overseas-profit credit. profitRate = 75/100 * 0.40 = 0.30;
      // profit = 10 * 20.0 * 0.30 = 60.
      expect(
        gpA.treasury,
        100 + 60,
        reason:
            'owning GP receives `filledQuantity * price * profitRate` '
            'as treasury credit per SPEC/game/world-market-first-right-'
            'of-refusal.md § Treasury transfer (D4).',
      );
      // gpB pays the full clear price (no double charge): 10 * 20 = 200.
      expect(gpB.treasury, 1000 - 200);
      // gpB receives the goods; M1 (minor seller) is not credited.
      expect(gpB.stockpile.quantityOf('timber'), 10);
    });

    test('GP B buys minor M1\'s timber at relation 0: owning gpA receives '
        'no credit (profitRate clamps to 0)', () {
      final game = _frrIntegrationGame(
        initialOwningGpTreasury: 100,
        initialBuyerGpTreasury: 1000,
        relationScore: 0,
        marketPrices: const {'timber': 20.0},
      );
      final acc = TurnPipelineState(game: game);
      final config = TurnResolverConfig(
        topology: const MapTopology(nodes: [], edges: []),
        orders: Orders(
          tradeOrdersByPlayerId: {
            'M1': [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.offer,
                quantity: 10,
                priority: 1,
                originTileKey: tileKey,
              ),
            ],
            'gpB': [
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

      final next =
          (worldMarketTurnPhaseHandler(acc, config, 3) as TurnPhaseStepContinue)
              .pipeline
              .game;

      final gpA = next.players.firstWhere((p) => p.id == 'gpA');
      expect(
        gpA.treasury,
        100,
        reason:
            'relation 0 → profitRate 0 → no credit (full payment is '
            'a treasury sink per Requirement 9).',
      );
    });

    test('GP B buys minor M1\'s timber at relation 100: owning gpA receives '
        'the maximum 40% credit', () {
      final game = _frrIntegrationGame(
        initialOwningGpTreasury: 100,
        initialBuyerGpTreasury: 1000,
        relationScore: 100,
        marketPrices: const {'timber': 10.0},
      );
      final acc = TurnPipelineState(game: game);
      final config = TurnResolverConfig(
        topology: const MapTopology(nodes: [], edges: []),
        orders: Orders(
          tradeOrdersByPlayerId: {
            'M1': [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.offer,
                quantity: 10,
                priority: 1,
                originTileKey: tileKey,
              ),
            ],
            'gpB': [
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

      final next =
          (worldMarketTurnPhaseHandler(acc, config, 3) as TurnPhaseStepContinue)
              .pipeline
              .game;

      final gpA = next.players.firstWhere((p) => p.id == 'gpA');
      // 10 * 10.0 * 0.40 = 40.
      expect(gpA.treasury, 100 + 40);
    });

    test('owning GP wins the FRR pre-pass: no D4 credit double-applied '
        '(buyer == owning GP path is excluded from D4 by design)', () {
      final game = _frrIntegrationGame(
        initialOwningGpTreasury: 1000,
        initialBuyerGpTreasury: 0,
        relationScore: 100,
        marketPrices: const {'timber': 20.0},
      );
      final acc = TurnPipelineState(game: game);
      final config = TurnResolverConfig(
        topology: const MapTopology(nodes: [], edges: []),
        orders: Orders(
          tradeOrdersByPlayerId: {
            'M1': [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.offer,
                quantity: 10,
                priority: 1,
                originTileKey: tileKey,
              ),
            ],
            // Owning GP bids and wins via FRR pre-pass.
            'gpA': [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: 10,
                priority: 5,
              ),
            ],
          },
        ),
      );

      final next =
          (worldMarketTurnPhaseHandler(acc, config, 3) as TurnPhaseStepContinue)
              .pipeline
              .game;

      final gpA = next.players.firstWhere((p) => p.id == 'gpA');
      // gpA pays the full clear price as a regular buyer (no FRR
      // overseas-profit credit on its own purchase): 10 * 20 = 200.
      expect(
        gpA.treasury,
        1000 - 200,
        reason:
            'when the owning GP itself wins the FRR pre-pass match, '
            'no overseas profit applies — the buyer pays the standard '
            'clear price and no credit is layered on top.',
      );
      expect(gpA.stockpile.quantityOf('timber'), 10);
    });

    test('multiple GPs own different tiles on the same minor: each receives '
        'credit only for the tiles they own (no cross-credit)', () {
      const tileA = '$ow|M1|0|0';
      const tileB = '$ow|M1|1|0';
      // Build a custom scenario with gpA owning tileA, gpB owning
      // tileB, and gpC buying the residual.
      final game =
          TestFixtures.minimalGame(
            players: const [
              Player(
                id: 'gpA',
                displayName: 'GP A',
                isHuman: true,
                treasury: 100,
              ),
              Player(
                id: 'gpB',
                displayName: 'GP B',
                isHuman: false,
                treasury: 50,
              ),
              Player(
                id: 'gpC',
                displayName: 'GP C',
                isHuman: false,
                treasury: 1000,
                stockpile: Stockpile.empty,
              ),
            ],
            oldWorld: const RegionData(
              provinces: [
                Province(id: minorProvinceId, regionId: ow, ownerId: 'M1'),
              ],
            ),
            tileKeysByRegionAndProvince: const {
              ow: {
                minorProvinceId: [tileA, tileB],
              },
            },
            minorNations: const [MinorNation(id: 'M1', displayName: 'M1')],
            purchasedTilesByTileKey: const {tileA: 'gpA', tileB: 'gpB'},
            diplomacyRelations: const [
              DiplomacyRelation(
                factionId1: 'gpA',
                factionId2: 'M1',
                score: 100,
              ),
              DiplomacyRelation(factionId1: 'gpB', factionId2: 'M1', score: 50),
            ],
          ).copyWith(
            worldMarketState: WorldMarketState.empty.copyWith(
              prices: const {'timber': 10.0},
            ),
          );
      final acc = TurnPipelineState(game: game);
      final config = TurnResolverConfig(
        topology: const MapTopology(nodes: [], edges: []),
        orders: Orders(
          tradeOrdersByPlayerId: {
            'M1': [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.offer,
                quantity: 6,
                priority: 1,
                originTileKey: tileA,
              ),
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.offer,
                quantity: 4,
                priority: 1,
                originTileKey: tileB,
              ),
            ],
            'gpC': [
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

      final next =
          (worldMarketTurnPhaseHandler(acc, config, 3) as TurnPhaseStepContinue)
              .pipeline
              .game;

      final gpA = next.players.firstWhere((p) => p.id == 'gpA');
      final gpB = next.players.firstWhere((p) => p.id == 'gpB');
      final gpC = next.players.firstWhere((p) => p.id == 'gpC');
      // gpA: relation 100 → 40% on 6 units @ 10 = 24.
      expect(gpA.treasury, 100 + 24);
      // gpB: relation 50 → 20% on 4 units @ 10 = 8.
      expect(gpB.treasury, 50 + 8);
      // gpC pays full clear price for the 10 units (no double charge):
      // 10 * 10 = 100.
      expect(gpC.treasury, 1000 - 100);
      expect(gpC.stockpile.quantityOf('timber'), 10);
    });

    test('no purchased-tile attribution (plain minor offer, no originTileKey): '
        'standard treasury-sink behaviour — buyer pays, no FRR credit', () {
      final game = _frrIntegrationGame(
        initialOwningGpTreasury: 100,
        initialBuyerGpTreasury: 1000,
        relationScore: 100,
        marketPrices: const {'timber': 20.0},
      );
      final acc = TurnPipelineState(game: game);
      final config = TurnResolverConfig(
        topology: const MapTopology(nodes: [], edges: []),
        orders: Orders(
          tradeOrdersByPlayerId: {
            'M1': [
              // Offer with no originTileKey — must not generate FRR credit.
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.offer,
                quantity: 10,
                priority: 1,
              ),
            ],
            'gpB': [
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

      final next =
          (worldMarketTurnPhaseHandler(acc, config, 3) as TurnPhaseStepContinue)
              .pipeline
              .game;

      final gpA = next.players.firstWhere((p) => p.id == 'gpA');
      expect(
        gpA.treasury,
        100,
        reason:
            'offer without `originTileKey` does not trigger FRR (no '
            'attribution available); owning GP receives no credit.',
      );
    });
  });
}

/// Builds an integration scenario with two GPs (gpA = owning, gpB = buyer)
/// and a minor `M1` that owns the source province. A single purchased-tile
/// attribution maps `tileKey` → `gpA`. The `relationScore` is wired into
/// [DiplomacyRelation] between `gpA` and `M1` so the phase handler resolves
/// the FRR profit rate deterministically via [getRelation].
Game _frrIntegrationGame({
  required int initialOwningGpTreasury,
  required int initialBuyerGpTreasury,
  required int relationScore,
  required Map<CommodityId, double> marketPrices,
}) {
  const ow = 'oldWorld';
  const minorProvinceId = '$ow|M1';
  const tileKey = '$ow|M1|0|0';
  return TestFixtures.minimalGame(
    players: [
      Player(
        id: 'gpA',
        displayName: 'GP A',
        isHuman: true,
        treasury: initialOwningGpTreasury,
      ),
      Player(
        id: 'gpB',
        displayName: 'GP B',
        isHuman: false,
        treasury: initialBuyerGpTreasury,
        stockpile: Stockpile.empty,
      ),
    ],
    oldWorld: const RegionData(
      provinces: [Province(id: minorProvinceId, regionId: ow, ownerId: 'M1')],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        minorProvinceId: [tileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
    purchasedTilesByTileKey: const {tileKey: 'gpA'},
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gpA',
        factionId2: 'M1',
        score: relationScore,
      ),
    ],
  ).copyWith(
    worldMarketState: WorldMarketState.empty.copyWith(prices: marketPrices),
  );
}
