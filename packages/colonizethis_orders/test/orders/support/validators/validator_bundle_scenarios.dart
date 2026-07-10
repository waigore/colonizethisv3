// Table-driven validator-bundle scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'validator_bundle_expectations.dart';

/// One row in [validatorBundleScenarios].
class ValidatorBundleScenario implements RefsScenario {
  const ValidatorBundleScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final ValidatorBundleTarget target;
  @override
  final String? refs;
}

void runValidatorBundleScenario(ValidatorBundleScenario scenario) {
  runValidatorBundleExpectation(scenario.target);
}

/// Canonical scenarios for validator_bundle family tests.
List<ValidatorBundleScenario> validatorBundleScenarios() => const [
      ValidatorBundleScenario(
        label: 'createOrderValidators returns wired validators (Refs #2391 AC6)',
        target: ValidatorBundleTarget.createOrderValidatorsReturnsWiredValidators,
        refs: '#2391 AC6',
      ),
    ];
