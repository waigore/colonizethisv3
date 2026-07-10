// Table-driven runBuildPhase index-map scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'run_build_phase_index_maps_run_rows.dart';

/// One row in [runBuildPhaseIndexMapsScenarios].
class RunBuildPhaseIndexMapsScenario implements LabeledScenario {
  const RunBuildPhaseIndexMapsScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runRunBuildPhaseIndexMapsScenario(RunBuildPhaseIndexMapsScenario scenario) {
  scenario.run();
}

List<RunBuildPhaseIndexMapsScenario> runBuildPhaseIndexMapsScenarios() =>
    const [
      RunBuildPhaseIndexMapsScenario(
        label:
            'consecutive military recruits build one home army with all regiments',
        run: rbpiRunMilitarySingleHomeArmy,
      ),
      RunBuildPhaseIndexMapsScenario(
        label:
            'consecutive ship recruits add ships to a single home fleet (cache reuse)',
        run: rbpiRunNavalSingleHomeFleet,
      ),
    ];
