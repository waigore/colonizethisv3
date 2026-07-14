// TradeOrderValidator scenario row type and runner (Refs #3836, #3939 phase 3 slice 30).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'validator_expectations.dart';
/// One row for validator cap / rules / treasury scenarios (Refs #3939 slice 63).
typedef TradeOrderValidatorScenario = ({
  String label,
  TradeOrderValidationContext context,
  List<TradeOrder> proposedOrders,
  void Function(List<OrderValidationResult> results) verify,
  String? refs,
});
/// Compact expect-wired row (Refs #3939 slice 59).
// dart format off
TradeOrderValidatorScenario validatorExpectRow({
  required String label,
  required TradeOrderValidationContext context,
  required List<TradeOrder> proposedOrders,
  required ValidatorExpectation expect,
  String? refs,
}) => (
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
// dart format on
