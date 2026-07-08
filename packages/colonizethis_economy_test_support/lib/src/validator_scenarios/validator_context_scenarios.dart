// Context-from-game validator scenarios (Refs #3123, #3290, #3939 phase 3 slice 30).

import 'validator_expectations.dart';

/// One row for `tradeOrderValidationContextFromGame` treasury scenarios.
class TradeOrderValidatorContextScenario {
  const TradeOrderValidatorContextScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  TradeOrderValidatorContextScenario.expect({
    required String label,
    required ValidatorContextExpectation expect,
    String? refs,
  }) : this(
          label: label,
          run: () => assertValidatorContextExpectation(expect),
          refs: refs,
        );

  final String label;
  final void Function() run;
  final String? refs;
}

void runTradeOrderValidatorContextScenario(
  TradeOrderValidatorContextScenario scenario,
) {
  scenario.run();
}

/// Context-from-game treasury scenarios from
/// `world_market_trade_order_validator_context_treasury_test.dart`.
List<TradeOrderValidatorContextScenario>
tradeOrderValidatorContextTreasuryScenarios() => [
  TradeOrderValidatorContextScenario.expect(
    label: 'positive treasury surfaces as TradeOrderValidationContext.'
        'treasuryBudgetForBids',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.treasuryBudget,
      treasury: 175,
      treasuryBudgetForBids: 175,
    ),
    refs: '#3123',
  ),
  TradeOrderValidatorContextScenario.expect(
    label: 'treasury at or below zero yields a zero bid budget that rejects any '
        'priced bid end-to-end (negative clamps; zero passes through) '
        '(SPEC/game/world-market.md — cross-commodity bid treasury cap)',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.treasuryClampsRejectPricedBid,
    ),
    refs: '#3123',
  ),
  TradeOrderValidatorContextScenario.expect(
    label: 'ghost player id returns a zero-budget context (ghost guard)',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.ghostPlayerZeroBudget,
      treasury: 200,
    ),
    refs: '#3123',
  ),
  TradeOrderValidatorContextScenario.expect(
    label: 'caller-supplied projectedTreasuryDelta reduces the budget by the '
        'projected non-bid deficit (Refs #3290 economy->orders inversion)',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.projectedDeltaReducesBudget,
      treasury: 175,
      treasuryBudgetForBids: 125,
      projectedTreasuryDelta: -50,
    ),
    refs: '#3290',
  ),
  TradeOrderValidatorContextScenario.expect(
    label: 'caller-supplied non-negative projectedTreasuryDelta leaves the raw '
        'treasury budget unchanged (income does not raise the budget)',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.nonNegativeProjectedDeltaUnchanged,
      treasury: 175,
      treasuryBudgetForBids: 175,
      projectedTreasuryDelta: 40,
    ),
    refs: '#3290',
  ),
  TradeOrderValidatorContextScenario.expect(
    label: 'omitting projectedTreasuryDelta keeps the raw-treasury budget even '
        'when staged orders are supplied',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.omitProjectedDeltaUnchanged,
      treasury: 175,
      treasuryBudgetForBids: 175,
    ),
    refs: '#3123',
  ),
];
