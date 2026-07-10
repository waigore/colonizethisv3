// TradeOrderValidator scenario row type and runner (Refs #3836, #3939 phase 3 slice 30).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'validator_expectations.dart';

/// One row for validator cap / rules / treasury scenarios.
class TradeOrderValidatorScenario {
  const TradeOrderValidatorScenario({
    required this.label,
    required this.context,
    required this.proposedOrders,
    required this.verify,
    this.refs,
  });

  final TradeOrderValidationContext context;
  final List<TradeOrder> proposedOrders;
  final String label;
  final void Function(List<OrderValidationResult> results) verify;
  final String? refs;
}

/// Compact expect-wired row (Refs #3939 slice 59).
TradeOrderValidatorScenario validatorExpectRow({
  required String label,
  required TradeOrderValidationContext context,
  required List<TradeOrder> proposedOrders,
  required ValidatorExpectation expect,
  String? refs,
}) => TradeOrderValidatorScenario(
  label: label,
  context: context,
  proposedOrders: proposedOrders,
  verify: (results) => assertValidatorExpectation(results, expect),
  refs: refs,
);

void runTradeOrderValidatorScenario(TradeOrderValidatorScenario scenario) {
  final results = TradeOrderValidator.validate(
    context: scenario.context,
    proposedOrders: scenario.proposedOrders,
  );
  scenario.verify(results);
}
