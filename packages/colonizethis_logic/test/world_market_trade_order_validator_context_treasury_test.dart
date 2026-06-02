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

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'world_market_treasury_bid_budget_test_support.dart';

void main() {
  group('tradeOrderValidationContextFromGame (Refs #3123)', () {
    test('positive treasury surfaces as TradeOrderValidationContext.'
        'treasuryBudgetForBids', () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId);
      expect(ctx.treasuryBudgetForBids, 175);
    });

    test(
      'negative treasury clamps the context budget at 0 (defensive guard)',
      () {
        final game = buildTreasuryBidBudgetGame(treasury: -25);
        final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId);
        expect(ctx.treasuryBudgetForBids, 0);
      },
    );

    test('negative treasury context rejects any priced bid end-to-end '
        '(SPEC/game/world-market.md — cross-commodity bid treasury cap, '
        'clamped negative treasury AC)', () {
      // Pins the game-side AC "Cross-commodity bid treasury cap —
      // clamped negative treasury": negative `Player.treasury` clamps
      // `treasuryBudgetForBids` at 0 via `tradeOrderValidationContextFromGame`,
      // and the validator then rejects any priced bid with
      // `trade_order_bid_exceeds_treasury_budget`.
      final game = buildTreasuryBidBudgetGame(
        treasury: -25,
        prices: const {'timber': 30},
      );
      final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId);
      expect(ctx.treasuryBudgetForBids, 0);
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
      );
    });

    test('zero treasury surfaces as a zero budget (any priced bid is rejected '
        'when validated against this context)', () {
      final game = buildTreasuryBidBudgetGame(
        treasury: 0,
        prices: const {'timber': 30},
      );
      final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId);
      expect(ctx.treasuryBudgetForBids, 0);
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
      );
    });

    test('ghost player id returns a zero-budget context (ghost guard)', () {
      final game = buildTreasuryBidBudgetGame(treasury: 200);
      final ctx = tradeOrderValidationContextFromGame(game, 'gp_ghost');
      expect(ctx.treasuryBudgetForBids, 0);
    });

    test(
      'deterministic for identical inputs (two calls return identical budgets)',
      () {
        final game = buildTreasuryBidBudgetGame(treasury: 123);
        final ctxA = tradeOrderValidationContextFromGame(game, humanPlayerId);
        final ctxB = tradeOrderValidationContextFromGame(game, humanPlayerId);
        expect(ctxA.treasuryBudgetForBids, ctxB.treasuryBudgetForBids);
      },
    );
  });
}
