// dart format off
// Context-from-game validator scenarios (Refs #3123, #3290, #3939 phase 3 slice 30).

import 'validator_expectations.dart';

/// One row for `TradeOrderValidatorContextScenario` tables (Refs #3939 slice 63).
typedef TradeOrderValidatorContextScenario = ({String label, void Function() run, String? refs});

/// Compact expect-wired row (Refs #3939 slice 59).
TradeOrderValidatorContextScenario validatorContextRow({required String label, required ValidatorContextExpectation expect, String? refs}) => (label: label, run: () => assertValidatorContextExpectation(expect), refs: refs);

void runTradeOrderValidatorContextScenario(TradeOrderValidatorContextScenario scenario) {
  scenario.run();
}

/// Context-from-game treasury scenarios from
/// `world_market_trade_order_validator_context_treasury_test.dart`.
List<TradeOrderValidatorContextScenario> tradeOrderValidatorContextTreasuryScenarios() => [
  validatorContextRow(
    label:
        'positive treasury surfaces as TradeOrderValidationContext.'
        'treasuryBudgetForBids',
    expect: const ValidatorContextExpectation(target: ValidatorContextScenarioTarget.treasuryBudget, treasury: 175, treasuryBudgetForBids: 175),
    refs: '#3123',
  ),
  validatorContextRow(
    label:
        'treasury at or below zero yields a zero bid budget that rejects any '
        'priced bid end-to-end (negative clamps; zero passes through) '
        '(SPEC/game/world-market.md — cross-commodity bid treasury cap)',
    expect: const ValidatorContextExpectation(target: ValidatorContextScenarioTarget.treasuryClampsRejectPricedBid),
    refs: '#3123',
  ),
  validatorContextRow(
    label: 'ghost player id returns a zero-budget context (ghost guard)',
    expect: const ValidatorContextExpectation(target: ValidatorContextScenarioTarget.ghostPlayerZeroBudget, treasury: 200),
    refs: '#3123',
  ),
  validatorContextRow(
    label:
        'caller-supplied projectedTreasuryDelta reduces the budget by the '
        'projected non-bid deficit (Refs #3290 economy->orders inversion)',
    expect: const ValidatorContextExpectation(target: ValidatorContextScenarioTarget.projectedDeltaReducesBudget, treasury: 175, treasuryBudgetForBids: 125, projectedTreasuryDelta: -50),
    refs: '#3290',
  ),
  validatorContextRow(
    label:
        'caller-supplied non-negative projectedTreasuryDelta leaves the raw '
        'treasury budget unchanged (income does not raise the budget)',
    expect: const ValidatorContextExpectation(target: ValidatorContextScenarioTarget.nonNegativeProjectedDeltaUnchanged, treasury: 175, treasuryBudgetForBids: 175, projectedTreasuryDelta: 40),
    refs: '#3290',
  ),
  validatorContextRow(
    label:
        'omitting projectedTreasuryDelta keeps the raw-treasury budget even '
        'when staged orders are supplied',
    expect: const ValidatorContextExpectation(target: ValidatorContextScenarioTarget.omitProjectedDeltaUnchanged, treasury: 175, treasuryBudgetForBids: 175),
    refs: '#3123',
  ),
];
// dart format on
