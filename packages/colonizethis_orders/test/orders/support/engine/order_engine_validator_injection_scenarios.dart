// Table-driven OrderEngine validator-injection scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validator_injection_expectations.dart';

/// One row in [orderEngineValidatorInjectionScenarios].
class OrderEngineValidatorInjectionScenario implements RefsScenario {
  const OrderEngineValidatorInjectionScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEngineValidatorInjectionTarget target;
  @override
  final String? refs;
}

void runOrderEngineValidatorInjectionScenario(
  OrderEngineValidatorInjectionScenario scenario,
) {
  runOrderEngineValidatorInjectionExpectation(scenario.target);
}

/// Canonical scenarios for order_engine_validator_injection family tests.
List<OrderEngineValidatorInjectionScenario>
    orderEngineValidatorInjectionScenarios() => const [
          OrderEngineValidatorInjectionScenario(
            label: 'OrderEngine validator factory allows injected validators',
            target: OrderEngineValidatorInjectionTarget
                .factoryAllowsInjectedValidators,
          ),
          OrderEngineValidatorInjectionScenario(
            label: 'validatePlayerOrdersWithContext builds six validator bundles (shared move+army, then fresh per later category; #2391 AC7, #2692 S4)',
            target: OrderEngineValidatorInjectionTarget
                .validateBuildsSixValidatorBundles,
            refs: '#2391 AC7',
          ),
        ];
