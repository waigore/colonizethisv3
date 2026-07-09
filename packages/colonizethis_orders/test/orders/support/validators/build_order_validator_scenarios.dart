// Table-driven BuildOrderValidator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'build_order_validator_expectations.dart';

/// One row in [buildOrderValidatorScenarios].
class BuildOrderValidatorScenario implements RefsScenario {
  const BuildOrderValidatorScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final BuildOrderValidatorTarget target;
  @override
  final String? refs;
}

void runBuildOrderValidatorScenario(BuildOrderValidatorScenario scenario) {
  runBuildOrderValidatorExpectation(scenario.target);
}

/// Canonical scenarios for BuildOrderValidator.
List<BuildOrderValidatorScenario> buildOrderValidatorScenarios() => const [
      BuildOrderValidatorScenario(
        label: 'validate returns rejected when previousRejected is true',
        target: BuildOrderValidatorTarget.validateRejectedWhenPreviousRejected,
      ),
      BuildOrderValidatorScenario(
        label: 'civilian build is rejected when capital tile cannot be resolved',
        target: BuildOrderValidatorTarget.civilianBuildRejectedNoCapitalTile,
      ),
    ];
