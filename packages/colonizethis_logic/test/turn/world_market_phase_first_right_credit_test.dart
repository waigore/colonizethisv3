import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';
import 'world_market_phase_first_right_credit_test_support.dart';

/// Phase-handler integration for the First Right of Refusal overseas-profit
/// treasury credit (Refs #2992 D4).
///
/// SPEC anchors:
///
/// - `SPEC/game/world-market.md` § Trade orders / Requirement 9.
/// - `SPEC/game/world-market-first-right-of-refusal.md` § Treasury transfer (D4).
/// - `SPEC/program/world-market-resolution.md` § Phase resolution Step E.
void main() {
  group('worldMarketTurnPhaseHandler applies First Right of Refusal '
      'overseas-profit credit to owning GP (Refs #2992 D4 integration)', () {
    test('GP B buys minor M1\'s timber from gpA\'s purchased tile: gpA '
        'receives `quantity * price * 0.30` credit at relation score 75', () {
      final next = runWorldMarketFrrCreditPhase(
        game: frrIntegrationGame(
          initialOwningGpTreasury: 100,
          initialBuyerGpTreasury: 1000,
          relationScore: 75,
          marketPrices: const {'timber': 20},
        ),
        tradeOrdersByPlayerId: {
          'M1': minorTimberOffer(
            quantity: 10,
            originTileKey: frrCreditTestTileKey,
          ),
          'gpB': gpTimberBid(quantity: 10),
        },
      );

      final gpA = next.players.firstWhere((p) => p.id == 'gpA');
      final gpB = next.players.firstWhere((p) => p.id == 'gpB');
      expect(gpA.treasury, 160, reason: '10 * 20 * 0.30 FRR credit');
      expect(gpB.treasury, 800);
      expect(gpB.stockpile.quantityOf('timber'), 10);
    });

    test('GP B buys at relation 0: owning gpA receives no credit', () {
      final next = runWorldMarketFrrCreditPhase(
        game: frrIntegrationGame(
          initialOwningGpTreasury: 100,
          initialBuyerGpTreasury: 1000,
          relationScore: 0,
          marketPrices: const {'timber': 20},
        ),
        tradeOrdersByPlayerId: {
          'M1': minorTimberOffer(
            quantity: 10,
            originTileKey: frrCreditTestTileKey,
          ),
          'gpB': gpTimberBid(quantity: 10),
        },
      );

      expect(
        next.players.firstWhere((p) => p.id == 'gpA').treasury,
        100,
        reason: 'relation 0 → profitRate 0 → treasury sink only',
      );
    });

    test(
      'GP B buys at relation 100: owning gpA receives maximum 40% credit',
      () {
        final next = runWorldMarketFrrCreditPhase(
          game: frrIntegrationGame(
            initialOwningGpTreasury: 100,
            initialBuyerGpTreasury: 1000,
            relationScore: 100,
            marketPrices: const {'timber': 10},
          ),
          tradeOrdersByPlayerId: {
            'M1': minorTimberOffer(
              quantity: 10,
              originTileKey: frrCreditTestTileKey,
            ),
            'gpB': gpTimberBid(quantity: 10),
          },
        );

        expect(next.players.firstWhere((p) => p.id == 'gpA').treasury, 140);
      },
    );

    test('owning GP wins FRR pre-pass: no D4 credit double-applied', () {
      final next = runWorldMarketFrrCreditPhase(
        game: frrIntegrationGame(
          initialOwningGpTreasury: 1000,
          initialBuyerGpTreasury: 0,
          relationScore: 100,
          marketPrices: const {'timber': 20},
        ),
        tradeOrdersByPlayerId: {
          'M1': minorTimberOffer(
            quantity: 10,
            originTileKey: frrCreditTestTileKey,
          ),
          'gpA': gpTimberBid(quantity: 10, priority: 5),
        },
      );

      final gpA = next.players.firstWhere((p) => p.id == 'gpA');
      expect(gpA.treasury, 800, reason: 'buyer pays clear price only');
      expect(gpA.stockpile.quantityOf('timber'), 10);
    });

    test('multiple GPs own different tiles: each receives credit only for '
        'their tiles', () {
      const tileA = '$frrCreditTestOw|M1|0|0';
      const tileB = '$frrCreditTestOw|M1|1|0';
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
                Province(
                  id: frrCreditTestMinorProvinceId,
                  regionId: frrCreditTestOw,
                  ownerId: 'M1',
                ),
              ],
            ),
            tileKeysByRegionAndProvince: const {
              frrCreditTestOw: {
                frrCreditTestMinorProvinceId: [tileA, tileB],
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
              prices: const {'timber': 10},
            ),
          );

      final next = runWorldMarketFrrCreditPhase(
        game: game,
        tradeOrdersByPlayerId: {
          'M1': [
            ...minorTimberOffer(quantity: 6, originTileKey: tileA),
            ...minorTimberOffer(quantity: 4, originTileKey: tileB),
          ],
          'gpC': gpTimberBid(quantity: 10),
        },
      );

      expect(next.players.firstWhere((p) => p.id == 'gpA').treasury, 124);
      expect(next.players.firstWhere((p) => p.id == 'gpB').treasury, 58);
      expect(next.players.firstWhere((p) => p.id == 'gpC').treasury, 900);
      expect(
        next.players
            .firstWhere((p) => p.id == 'gpC')
            .stockpile
            .quantityOf('timber'),
        10,
      );
    });

    test('no originTileKey: treasury sink only, no FRR credit', () {
      final next = runWorldMarketFrrCreditPhase(
        game: frrIntegrationGame(
          initialOwningGpTreasury: 100,
          initialBuyerGpTreasury: 1000,
          relationScore: 100,
          marketPrices: const {'timber': 20},
        ),
        tradeOrdersByPlayerId: {
          'M1': minorTimberOffer(quantity: 10),
          'gpB': gpTimberBid(quantity: 10),
        },
      );

      expect(
        next.players.firstWhere((p) => p.id == 'gpA').treasury,
        100,
        reason: 'no attribution → no FRR credit',
      );
    });
  });
}
