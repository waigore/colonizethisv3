// Table-driven runBuildPhase index-map scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'run_build_phase_index_maps_expectations.dart';

/// One row in [runBuildPhaseIndexMapsScenarios].
class RunBuildPhaseIndexMapsScenario implements LabeledScenario {
  const RunBuildPhaseIndexMapsScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final RunBuildPhaseIndexMapsTarget target;
}

void runRunBuildPhaseIndexMapsScenario(RunBuildPhaseIndexMapsScenario scenario) {
  runRunBuildPhaseIndexMapsExpectation(scenario.target);
}

List<RunBuildPhaseIndexMapsScenario> runBuildPhaseIndexMapsScenarios() => const [
      RunBuildPhaseIndexMapsScenario(
        label:
            'consecutive military recruits build one home army with all regiments',
        target: RunBuildPhaseIndexMapsTarget.militarySingleHomeArmy,
      ),
      RunBuildPhaseIndexMapsScenario(
        label:
            'consecutive ship recruits add ships to a single home fleet (cache reuse)',
        target: RunBuildPhaseIndexMapsTarget.navalSingleHomeFleet,
      ),
    ];
