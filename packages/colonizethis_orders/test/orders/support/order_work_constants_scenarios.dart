// Table-driven order/work constant ownership scenarios (Refs #3949 wave 3).

import 'scenario_runner.dart';
import 'order_work_constants_run_rows.dart';

class OrderWorkConstantsScenario implements LabeledScenario {
  const OrderWorkConstantsScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runOrderWorkConstantsScenario(OrderWorkConstantsScenario scenario) {
  scenario.run();
}

List<OrderWorkConstantsScenario> orderWorkConstantsScenarios() => const [
      OrderWorkConstantsScenario(
        label: 'work-target / mineral / prospect constants are defined in the orders domain file',
        run: owcRunDefinedInOrdersDomain,
      ),
      OrderWorkConstantsScenario(
        label: 'lib/src/constants.dart re-exports the same order constants (back-compat)',
        run: owcRunCoreReexportsBackCompat,
      ),
      OrderWorkConstantsScenario(
        label: 'public colonizethis_logic barrel still exposes the order constants',
        run: owcRunBarrelStillExposes,
      ),
      OrderWorkConstantsScenario(
        label: 'definitions moved out of the neutral core file into the orders domain',
        run: owcRunMovedOutOfNeutralCore,
      ),
    ];
