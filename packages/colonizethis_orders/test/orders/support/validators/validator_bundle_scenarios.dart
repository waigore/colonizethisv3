// Table-driven validator-bundle scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'validator_bundle_run_rows.dart';

/// One row in [validatorBundleScenarios].
class ValidatorBundleScenario implements RefsScenario {
  const ValidatorBundleScenario({
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

void runValidatorBundleScenario(ValidatorBundleScenario scenario) =>
    scenario.run();

/// Canonical scenarios for validator_bundle family tests.
List<ValidatorBundleScenario> validatorBundleScenarios() => [
      ValidatorBundleScenario(
        label: 'createOrderValidators returns wired validators (Refs #2391 AC6)',
        run: vbRunCreateOrderValidatorsReturnsWiredValidators,
        refs: '#2391 AC6',
      ),
    ];
