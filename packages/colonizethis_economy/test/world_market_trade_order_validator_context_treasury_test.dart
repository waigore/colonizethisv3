// Tests for `tradeOrderValidationContextFromGame` — Refs #3123 budget-source
// acceptance criteria.
//
// SPEC/program/world-market-resolution.md § Validation (issue #2989).
//
// Verifies the validator context picks up the treasury bid budget from
// `treasuryAvailableForBidsByPlayer(game, playerId)` so rule 5 (cross-
// commodity bid spend) is enforced against live player state — both
// positive treasury (raw treasury surfaces directly) and negative
// treasury (clamped at zero per § Treasury budget for bids).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('tradeOrderValidationContextFromGame (Refs #3123)', () {
    test('positive treasury surfaces as TradeOrderValidationContext.'
        'treasuryBudgetForBids', () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId);
      expect(ctx.treasuryBudgetForBids, 175);
    });

    test('treasury at or below zero yields a zero bid budget that rejects any '
        'priced bid end-to-end (negative clamps; zero passes through) '
        '(SPEC/game/world-market.md — cross-commodity bid treasury cap)', () {
      // Refs #3661 step 2: merges the previously separate negative- and
      // zero-treasury e2e pins, which built a game, called
      // `tradeOrderValidationContextFromGame`, and validated the same single
      // timber bid, differing only in the treasury sign. Both the game-side
      // AC "Cross-commodity bid treasury cap — clamped negative treasury"
      // (negative `Player.treasury` clamps `treasuryBudgetForBids` to 0) and
      // the zero-treasury passthrough are retained: the validator rejects any
      // priced bid with `trade_order_bid_exceeds_treasury_budget`.
      for (final treasury in const <int>[-25, 0]) {
        final game = buildTreasuryBidBudgetGame(
          treasury: treasury,
          prices: const {'timber': 30},
        );
        final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId);
        expect(
          ctx.treasuryBudgetForBids,
          0,
          reason: 'treasury $treasury must yield a zero bid budget',
        );
        final results = TradeOrderValidator.validate(
          context: ctx,
          proposedOrders: [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.bid,
              quantity: 1,
              priority: 1,
            ),
          ],
        );
        expect(
          results.single.reason,
          TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
          reason: 'a priced bid must be rejected when treasury is $treasury',
        );
      }
    });

    test('ghost player id returns a zero-budget context (ghost guard)', () {
      final game = buildTreasuryBidBudgetGame(treasury: 200);
      final ctx = tradeOrderValidationContextFromGame(game, 'gp_ghost');
      expect(ctx.treasuryBudgetForBids, 0);
    });

    test('caller-supplied projectedTreasuryDelta reduces the budget by the '
        'projected non-bid deficit (Refs #3290 economy->orders inversion)', () {
      // The economy builder no longer runs projectOrderEffects itself; the
      // order engine passes the projected treasury delta. With no staged bids
      // (bidSpend == 0) and a projected deficit of -50, the budget is
      // max(0, 175 - max(0, 50)) == 125.
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final ctx = tradeOrderValidationContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
        projectedTreasuryDelta: -50,
      );
      expect(ctx.treasuryBudgetForBids, 125);
    });

    test('caller-supplied non-negative projectedTreasuryDelta leaves the raw '
        'treasury budget unchanged (income does not raise the budget)', () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final ctx = tradeOrderValidationContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
        projectedTreasuryDelta: 40,
      );
      expect(ctx.treasuryBudgetForBids, 175);
    });

    test('omitting projectedTreasuryDelta keeps the raw-treasury budget even '
        'when staged orders are supplied', () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final ctx = tradeOrderValidationContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
      );
      expect(ctx.treasuryBudgetForBids, 175);
    });
  });
}
