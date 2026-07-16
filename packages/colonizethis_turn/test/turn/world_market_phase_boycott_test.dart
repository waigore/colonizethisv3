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
    for (final row in const [
      (
        boycottActive: true,
        label: 'boycotted GP blocked; supply flows to gpD',
        gpBTimber: 0,
        gpDTimber: 5,
      ),
      (
        boycottActive: false,
        label: 'without boycott gpB wins by ascending faction id',
        gpBTimber: 5,
        gpDTimber: 0,
      ),
    ]) {
      test(row.label, () {
        final next = runWorldMarketTradePhase(
          game: boycottColonyTradeGame(boycottActive: row.boycottActive),
          tradeOrdersByPlayerId: {
            boycottColonyTradeTribeId: tribeTimberOffer(5),
            'gpB': gpTimberBid(quantity: 5),
            'gpD': gpTimberBid(quantity: 5),
          },
        );

        expect(_timberOf(next, 'gpB'), row.gpBTimber);
        expect(_timberOf(next, 'gpD'), row.gpDTimber);
      });
    }
  });
}
