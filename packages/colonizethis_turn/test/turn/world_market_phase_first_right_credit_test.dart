import 'package:colonizethis_test/test.dart';

import '../support/world_market_test_support.dart';
import 'world_market_phase_first_right_credit_cases.dart';

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
    for (final c
        in <
          ({
            String name,
            int relationScore,
            int marketPrice,
            int expectedOwningTreasury,
            String reason,
          })
        >[
          (
            name: 'relation 75: owning GP receives 75% full share',
            relationScore: 75,
            marketPrice: 20,
            expectedOwningTreasury: 250,
            reason: '10 * 20 * 0.75 full-share credit',
          ),
          (
            name: 'relation 0: owning GP receives no credit',
            relationScore: 0,
            marketPrice: 20,
            expectedOwningTreasury: 100,
            reason: 'relation 0 → profitRate 0 → treasury sink only',
          ),
          (
            name: 'relation 100: owning GP receives full 100% share',
            relationScore: 100,
            marketPrice: 10,
            expectedOwningTreasury: 200,
            reason: '10 * 10 * 1.0 full-share credit (no 40% cap, #3753 R8.2)',
          ),
        ]) {
      test(c.name, () {
        final next = runWorldMarketFrrCreditPhase(
          game: frrIntegrationGame(
            initialOwningGpTreasury: 100,
            initialBuyerGpTreasury: 1000,
            relationScore: c.relationScore,
            marketPrices: {'timber': c.marketPrice},
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
          c.expectedOwningTreasury,
          reason: c.reason,
        );
        if (c.relationScore == 75) {
          final gpB = next.players.firstWhere((p) => p.id == 'gpB');
          expect(gpB.treasury, 800);
          expect(gpB.stockpile.quantityOf('timber'), 10);
        }
      });
    }

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
      final next = runWorldMarketFrrCreditPhase(
        game: frrMultiOwnerTilesGame(),
        tradeOrdersByPlayerId: {
          'M1': [
            ...minorTimberOffer(quantity: 6, originTileKey: frrCreditTileA),
            ...minorTimberOffer(quantity: 4, originTileKey: frrCreditTileB),
          ],
          'gpC': gpTimberBid(quantity: 10),
        },
      );

      expect(next.players.firstWhere((p) => p.id == 'gpA').treasury, 160);
      expect(next.players.firstWhere((p) => p.id == 'gpB').treasury, 70);
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

    test('embassy-holding non-owner GP receives 10% kickback while tile '
        'owner gets full share (#3753 R8.3)', () {
      final next = runWorldMarketFrrCreditPhase(
        game: frrEmbassyKickbackGame(),
        tradeOrdersByPlayerId: {
          'M1': minorTimberOffer(
            quantity: 10,
            originTileKey: frrCreditTestTileKey,
          ),
          'gpB': gpTimberBid(quantity: 10),
        },
      );

      expect(next.players.firstWhere((p) => p.id == 'gpA').treasury, 300);
      expect(next.players.firstWhere((p) => p.id == 'gpC').treasury, 110);
      expect(next.players.firstWhere((p) => p.id == 'gpB').treasury, 800);
    });
  });
}
