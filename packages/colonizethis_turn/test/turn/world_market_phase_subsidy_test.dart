import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/world_market_test_support.dart';

/// Phase-handler integration for the subsidy price adjustment (Refs #3753
/// R3.4): a Great Power that subsidises a Minor pays a surcharge when buying
/// that Minor's goods on the world market.
///
/// SPEC anchors:
///
/// - `SPEC/game/world-market.md` § Subsidy price adjustment (Minor/Tribe deals).
/// - `SPEC/program/world-market-resolution.md` § Step D — Subsidy price
///   adjustment.
void main() {
  group('worldMarketTurnPhaseHandler subsidy surcharge (Refs #3753 R3.4b)', () {
    for (final row in const [
      (
        label: '10% surcharge debited when subsidy active',
        clearSubsidy: false,
        expectedTreasury: 780,
        expectedTimber: 10,
      ),
      (
        label: 'unadjusted price when subsidy cleared',
        clearSubsidy: true,
        expectedTreasury: 800,
        expectedTimber: null,
      ),
    ]) {
      test(row.label, () {
        var game = subsidySurchargeGame(subsidyPercent: 10);
        if (row.clearSubsidy) {
          game = game.copyWith(subsidyStates: const <SubsidyState>[]);
        }
        final next = runWorldMarketFrrCreditPhase(
          game: game,
          tradeOrdersByPlayerId: {
            'M1': minorTimberOffer(quantity: 10),
            'gpA': gpTimberBid(quantity: 10),
          },
        );

        expect(
          next.players.firstWhere((p) => p.id == 'gpA').treasury,
          row.expectedTreasury,
        );
        if (row.expectedTimber != null) {
          expect(
            next.players.firstWhere((p) => p.id == 'gpA').stockpile.quantityOf(
              'timber',
            ),
            row.expectedTimber,
          );
        }
      });
    }
  });
}
