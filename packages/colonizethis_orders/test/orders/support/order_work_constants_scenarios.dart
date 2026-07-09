// Table-driven order/work constant ownership scenarios (Refs #3949 wave 3).

import 'scenario_runner.dart';
import 'order_work_constants_expectations.dart';

class OrderWorkConstantsScenario implements LabeledScenario {
  const OrderWorkConstantsScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final OrderWorkConstantsTarget target;
}

void runOrderWorkConstantsScenario(OrderWorkConstantsScenario scenario) {
  runOrderWorkConstantsExpectation(scenario.target);
}

List<OrderWorkConstantsScenario> orderWorkConstantsScenarios() => const [
      OrderWorkConstantsScenario(
        label: 'work-target / mineral / prospect constants are defined in the orders domain file',
        target: OrderWorkConstantsTarget.definedInOrdersDomain,
      ),
      OrderWorkConstantsScenario(
        label: 'lib/src/constants.dart re-exports the same order constants (back-compat)',
        target: OrderWorkConstantsTarget.coreReexportsBackCompat,
      ),
      OrderWorkConstantsScenario(
        label: 'public colonizethis_logic barrel still exposes the order constants',
        target: OrderWorkConstantsTarget.barrelStillExposes,
      ),
      OrderWorkConstantsScenario(
        label: 'definitions moved out of the neutral core file into the orders domain',
        target: OrderWorkConstantsTarget.movedOutOfNeutralCore,
      ),
    ];
