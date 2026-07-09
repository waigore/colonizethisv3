// Table-driven purchase-land work handler scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'purchase_land_work_handler_expectations.dart';

/// One row in [purchaseLandWorkHandlerScenarios].
class PurchaseLandWorkHandlerScenario implements RefsScenario {
  const PurchaseLandWorkHandlerScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final PurchaseLandWorkHandlerTarget target;
  @override
  final String? refs;
}

void runPurchaseLandWorkHandlerScenario(
  PurchaseLandWorkHandlerScenario scenario,
) {
  runPurchaseLandWorkHandlerExpectation(scenario.target);
}

/// Canonical scenarios for purchase_land_work_handler family tests.
List<PurchaseLandWorkHandlerScenario> purchaseLandWorkHandlerScenarios() =>
    const [
      PurchaseLandWorkHandlerScenario(
        label: 'supports only purchase_land target',
        target: PurchaseLandWorkHandlerTarget.supportsOnlyPurchaseLand,
      ),
      PurchaseLandWorkHandlerScenario(
        label: 'tryApply assigns currentWork without treasury deduction',
        target: PurchaseLandWorkHandlerTarget.tryApplyWithoutTreasuryDeduction,
      ),
      PurchaseLandWorkHandlerScenario(
        label: 'returns unchanged treasury when tile has no resource entry',
        target: PurchaseLandWorkHandlerTarget.unchangedTreasuryNoResource,
      ),
    ];
