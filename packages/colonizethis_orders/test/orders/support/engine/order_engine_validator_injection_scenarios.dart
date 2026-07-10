// Table-driven OrderEngine validator-injection scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validator_injection_run_rows.dart';

/// One row in [orderEngineValidatorInjectionScenarios].
class OrderEngineValidatorInjectionScenario implements RefsScenario {
  const OrderEngineValidatorInjectionScenario({
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

void runOrderEngineValidatorInjectionScenario(
  OrderEngineValidatorInjectionScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for order_engine_validator_injection family tests.
List<OrderEngineValidatorInjectionScenario>
orderEngineValidatorInjectionScenarios() => const [
  OrderEngineValidatorInjectionScenario(
    label: 'OrderEngine validator factory allows injected validators',
    run: oeviRunFactoryAllowsInjectedValidators,
  ),
  OrderEngineValidatorInjectionScenario(
    label: 'validatePlayerOrdersWithContext builds six validator bundles (shared move+army, then fresh per later category; #2391 AC7, #2692 S4)',
    run: oeviRunValidateBuildsSixValidatorBundles,
    refs: '#2391 AC7',
  ),
];
