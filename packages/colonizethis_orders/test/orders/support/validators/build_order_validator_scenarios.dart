// Table-driven BuildOrderValidator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'build_order_validator_run_rows.dart';

/// One row in [buildOrderValidatorScenarios].
class BuildOrderValidatorScenario implements RefsScenario {
  const BuildOrderValidatorScenario({
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

void runBuildOrderValidatorScenario(BuildOrderValidatorScenario scenario) =>
    scenario.run();

/// Canonical scenarios for BuildOrderValidator.
List<BuildOrderValidatorScenario> buildOrderValidatorScenarios() => [
      BuildOrderValidatorScenario(
        label: 'validate returns rejected when previousRejected is true',
        run: bovRunValidateRejectedWhenPreviousRejected,
      ),
      BuildOrderValidatorScenario(
        label: 'civilian build is rejected when capital tile cannot be resolved',
        run: bovRunCivilianBuildRejectedNoCapitalTile,
      ),
    ];
