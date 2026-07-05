import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/world_market_test_support.dart';

/// Phase-handler integration for the #3753 R6 boycott colony trade embargo.
/// Tribe `tribeT` (a colony of GP `gpA`) offers timber; the boycotted GP `gpB`
/// and a non-boycotted GP `gpD` both bid. The boycott `(gpA, gpB)` blocks the
/// `tribeT ↔ gpB` deal so the supply flows to `gpD`.
///
/// SPEC anchors:
/// - `SPEC/game/diplomacy.md` § GP–Tribe Rules (Boycott).
/// - `SPEC/program/world-market-resolution.md` § Deal matching engine
///   (boycott exclusion).
int _timberOf(Game game, String playerId) =>
    game.players.firstWhere((p) => p.id == playerId).stockpile.quantityOf(
      'timber',
    );

void main() {
  group('worldMarketTurnPhaseHandler — #3753 R6 boycott exclusion', () {
    test('boycotted GP is blocked; supply flows to the non-boycotted GP', () {
      final next = runWorldMarketTradePhase(
        game: boycottColonyTradeGame(boycottActive: true),
        tradeOrdersByPlayerId: {
          // gpB sorts first by faction id but is boycotted; only 5 units exist.
          boycottColonyTradeTribeId: tribeTimberOffer(5),
          'gpB': gpTimberBid(quantity: 5),
          'gpD': gpTimberBid(quantity: 5),
        },
      );

      expect(_timberOf(next, 'gpB'), 0);
      expect(_timberOf(next, 'gpD'), 5);
    });

    test('without a boycott the same orders fill for the (now) target GP', () {
      final next = runWorldMarketTradePhase(
        game: boycottColonyTradeGame(boycottActive: false),
        tradeOrdersByPlayerId: {
          boycottColonyTradeTribeId: tribeTimberOffer(5),
          'gpB': gpTimberBid(quantity: 5),
          'gpD': gpTimberBid(quantity: 5),
        },
      );

      // No boycott: default ascending-faction-id ordering serves gpB first.
      expect(_timberOf(next, 'gpB'), 5);
      expect(_timberOf(next, 'gpD'), 0);
    });
  });
}
