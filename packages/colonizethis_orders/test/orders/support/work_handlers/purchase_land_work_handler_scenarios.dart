// Table-driven purchase-land work handler scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'purchase_land_work_handler_run_rows.dart';

/// One row in [purchaseLandWorkHandlerScenarios].
class PurchaseLandWorkHandlerScenario implements RefsScenario {
  const PurchaseLandWorkHandlerScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runPurchaseLandWorkHandlerScenario(
  PurchaseLandWorkHandlerScenario scenario,
) =>
    scenario.run();

/// Canonical scenarios for purchase_land_work_handler family tests.
List<PurchaseLandWorkHandlerScenario> purchaseLandWorkHandlerScenarios() =>
    const [
      PurchaseLandWorkHandlerScenario(
        label: 'supports only purchase_land target',
        run: plwhRunSupportsOnlyPurchaseLand,
      ),
      PurchaseLandWorkHandlerScenario(
        label: 'tryApply assigns currentWork without treasury deduction',
        run: plwhRunTryApplyWithoutTreasuryDeduction,
      ),
      PurchaseLandWorkHandlerScenario(
        label: 'returns unchanged treasury when tile has no resource entry',
        run: plwhRunUnchangedTreasuryNoResource,
      ),
    ];
