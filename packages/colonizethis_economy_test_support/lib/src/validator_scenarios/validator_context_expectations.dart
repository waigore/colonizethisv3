// Compact tradeOrderValidationContextFromGame assertions (Refs #3939 phase 3 slice 20).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../treasury_scenarios/treasury_test_support.dart';

/// Which factory path [ValidatorContextExpectation] exercises.
enum ValidatorContextScenarioTarget {
  treasuryBudget,
  treasuryClampsRejectPricedBid,
  ghostPlayerZeroBudget,
  projectedDeltaReducesBudget,
  nonNegativeProjectedDeltaUnchanged,
  omitProjectedDeltaUnchanged,
}

/// Data-driven expectations for [TradeOrderValidatorContextScenario] rows.
class ValidatorContextExpectation {
  const ValidatorContextExpectation({
    required this.target,
    this.treasury = 175,
    this.playerId = humanPlayerId,
    this.treasuryBudgetForBids,
    this.prices = const {'timber': 30},
    this.treasuryValuesToClamp = const [-25, 0],
    this.projectedTreasuryDelta = 0,
    this.stagedOrdersEmpty = false,
  });

  final ValidatorContextScenarioTarget target;
  final int treasury;
  final String playerId;
  final int? treasuryBudgetForBids;
  final Map<CommodityId, int> prices;
  final List<int> treasuryValuesToClamp;
  final int projectedTreasuryDelta;
  final bool stagedOrdersEmpty;
}

void assertValidatorContextExpectation(ValidatorContextExpectation expectation) {
  switch (expectation.target) {
    case ValidatorContextScenarioTarget.treasuryBudget:
      final game = buildTreasuryBidBudgetGame(treasury: expectation.treasury);
      final ctx = tradeOrderValidationContextFromGame(
        game,
        expectation.playerId,
      );
      expect(ctx.treasuryBudgetForBids, expectation.treasuryBudgetForBids);
    case ValidatorContextScenarioTarget.treasuryClampsRejectPricedBid:
      for (final treasury in expectation.treasuryValuesToClamp) {
        final game = buildTreasuryBidBudgetGame(
          treasury: treasury,
          prices: expectation.prices,
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
    case ValidatorContextScenarioTarget.ghostPlayerZeroBudget:
      final game = buildTreasuryBidBudgetGame(treasury: expectation.treasury);
      final ctx = tradeOrderValidationContextFromGame(game, 'gp_ghost');
      expect(ctx.treasuryBudgetForBids, 0);
    case ValidatorContextScenarioTarget.projectedDeltaReducesBudget:
      final game = buildTreasuryBidBudgetGame(treasury: expectation.treasury);
      final ctx = tradeOrderValidationContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
        projectedTreasuryDelta: expectation.projectedTreasuryDelta,
      );
      expect(ctx.treasuryBudgetForBids, expectation.treasuryBudgetForBids);
    case ValidatorContextScenarioTarget.nonNegativeProjectedDeltaUnchanged:
      final game = buildTreasuryBidBudgetGame(treasury: expectation.treasury);
      final ctx = tradeOrderValidationContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
        projectedTreasuryDelta: expectation.projectedTreasuryDelta,
      );
      expect(ctx.treasuryBudgetForBids, expectation.treasuryBudgetForBids);
    case ValidatorContextScenarioTarget.omitProjectedDeltaUnchanged:
      final game = buildTreasuryBidBudgetGame(treasury: expectation.treasury);
      final ctx = tradeOrderValidationContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
      );
      expect(ctx.treasuryBudgetForBids, expectation.treasuryBudgetForBids);
  }
}
