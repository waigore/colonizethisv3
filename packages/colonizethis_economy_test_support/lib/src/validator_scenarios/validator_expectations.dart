// dart format off
// Compact TradeOrderValidator result assertions (Refs #3939 phase 3 slice 10+).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../treasury_scenarios/treasury_test_support.dart';

/// Per-order validation outcome for data-driven validator scenarios.
typedef ValidatorOrderOutcome = ({bool accepted, String? reason});

/// Data-driven expectations for validator scenario rows.
class ValidatorExpectation {
  const ValidatorExpectation({this.outcomes, this.allAccepted = false, this.allRejectedWithReason, this.allSameReason, this.singleAccepted, this.singleRejectedWithReason, this.resultsEmpty = false, this.firstNAccepted, this.thenRejectedWithReason, this.catalogDefaultCommodityId, this.catalogDefaultNotNullReason, this.orderAcceptedPin, this.firstOrderReason, this.custom});

  final List<ValidatorOrderOutcome>? outcomes;
  final bool allAccepted;
  final String? allRejectedWithReason;
  final String? allSameReason;
  final bool? singleAccepted;
  final String? singleRejectedWithReason;
  final bool resultsEmpty;
  final int? firstNAccepted;
  final String? thenRejectedWithReason;
  final String? catalogDefaultCommodityId;
  final String? catalogDefaultNotNullReason;
  final ({int index, bool accepted, String? reason})? orderAcceptedPin;
  final String? firstOrderReason;
  final void Function(List<OrderValidationResult> results)? custom;
}

void assertValidatorExpectation(List<OrderValidationResult> results, ValidatorExpectation expectation) {
  if (expectation.resultsEmpty) {
    expect(results, isEmpty);
  }
  if (expectation.allAccepted) {
    for (final result in results) {
      expect(result.isAccepted, isTrue, reason: result.reason);
    }
  }
  if (expectation.allRejectedWithReason != null) {
    for (final result in results) {
      expect(result.reason, expectation.allRejectedWithReason);
    }
  }
  if (expectation.allSameReason != null) {
    for (final result in results) {
      expect(result.reason, expectation.allSameReason);
    }
  }
  if (expectation.singleAccepted != null) {
    expect(results.single.isAccepted, expectation.singleAccepted);
  }
  if (expectation.singleRejectedWithReason != null) {
    expect(results.single.reason, expectation.singleRejectedWithReason);
  }
  if (expectation.outcomes != null) {
    expect(results, hasLength(expectation.outcomes!.length));
    for (var i = 0; i < expectation.outcomes!.length; i++) {
      final expected = expectation.outcomes![i];
      final actual = results[i];
      expect(actual.isAccepted, expected.accepted);
      if (!expected.accepted) {
        expect(actual.reason, expected.reason);
      }
    }
  }
  if (expectation.firstNAccepted != null) {
    final n = expectation.firstNAccepted!;
    for (var i = 0; i < n; i++) {
      expect(results[i].isAccepted, isTrue, reason: results[i].reason);
    }
    if (expectation.thenRejectedWithReason != null) {
      expect(results[n].reason, expectation.thenRejectedWithReason);
    }
  }
  if (expectation.catalogDefaultCommodityId != null) {
    final int? catalogDefault = ResourceRules.defaultRules.defaultMarketPriceForCommodityId(expectation.catalogDefaultCommodityId!);
    expect(catalogDefault, isNotNull, reason: expectation.catalogDefaultNotNullReason);
  }
  if (expectation.orderAcceptedPin != null) {
    final pin = expectation.orderAcceptedPin!;
    expect(results[pin.index].isAccepted, pin.accepted, reason: pin.reason);
  }
  if (expectation.firstOrderReason != null) {
    expect(results.first.reason, expectation.firstOrderReason);
  }
  expectation.custom?.call(results);
}

/// Which factory path [ValidatorContextExpectation] exercises.
enum ValidatorContextScenarioTarget { treasuryBudget, treasuryClampsRejectPricedBid, ghostPlayerZeroBudget, projectedDeltaReducesBudget, nonNegativeProjectedDeltaUnchanged, omitProjectedDeltaUnchanged }

/// Data-driven expectations for [TradeOrderValidatorContextScenario] rows.
class ValidatorContextExpectation {
  const ValidatorContextExpectation({required this.target, this.treasury = 175, this.playerId = humanPlayerId, this.treasuryBudgetForBids, this.prices = const {'timber': 30}, this.treasuryValuesToClamp = const [-25, 0], this.projectedTreasuryDelta = 0, this.stagedOrdersEmpty = false});

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
      final ctx = tradeOrderValidationContextFromGame(game, expectation.playerId);
      expect(ctx.treasuryBudgetForBids, expectation.treasuryBudgetForBids);
    case ValidatorContextScenarioTarget.treasuryClampsRejectPricedBid:
      for (final treasury in expectation.treasuryValuesToClamp) {
        final game = buildTreasuryBidBudgetGame(treasury: treasury, prices: expectation.prices);
        final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId);
        expect(ctx.treasuryBudgetForBids, 0, reason: 'treasury $treasury must yield a zero bid budget');
        final results = TradeOrderValidator.validate(
          context: ctx,
          proposedOrders: [TradeOrder(commodityId: 'timber', type: TradeOrderType.bid, quantity: 1, priority: 1)],
        );
        expect(results.single.reason, TradeOrderRejectionReasons.bidExceedsTreasuryBudget, reason: 'a priced bid must be rejected when treasury is $treasury');
      }
    case ValidatorContextScenarioTarget.ghostPlayerZeroBudget:
      final game = buildTreasuryBidBudgetGame(treasury: expectation.treasury);
      final ctx = tradeOrderValidationContextFromGame(game, 'gp_ghost');
      expect(ctx.treasuryBudgetForBids, 0);
    case ValidatorContextScenarioTarget.projectedDeltaReducesBudget:
      final game = buildTreasuryBidBudgetGame(treasury: expectation.treasury);
      final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId, stagedOrders: humanOrdersWith(const <TradeOrder>[]), projectedTreasuryDelta: expectation.projectedTreasuryDelta);
      expect(ctx.treasuryBudgetForBids, expectation.treasuryBudgetForBids);
    case ValidatorContextScenarioTarget.nonNegativeProjectedDeltaUnchanged:
      final game = buildTreasuryBidBudgetGame(treasury: expectation.treasury);
      final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId, stagedOrders: humanOrdersWith(const <TradeOrder>[]), projectedTreasuryDelta: expectation.projectedTreasuryDelta);
      expect(ctx.treasuryBudgetForBids, expectation.treasuryBudgetForBids);
    case ValidatorContextScenarioTarget.omitProjectedDeltaUnchanged:
      final game = buildTreasuryBidBudgetGame(treasury: expectation.treasury);
      final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId, stagedOrders: humanOrdersWith(const <TradeOrder>[]));
      expect(ctx.treasuryBudgetForBids, expectation.treasuryBudgetForBids);
  }
}
// dart format on
