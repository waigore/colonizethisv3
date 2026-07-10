// Table-driven explore work handler scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'explore_work_handler_run_rows.dart';

/// One row in [exploreWorkHandlerScenarios].
class ExploreWorkHandlerScenario implements RefsScenario {
  const ExploreWorkHandlerScenario({
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

void runExploreWorkHandlerScenario(ExploreWorkHandlerScenario scenario) =>
    scenario.run();

/// Canonical scenarios for explore_work_handler family tests.
List<ExploreWorkHandlerScenario> exploreWorkHandlerScenarios() => const [
      ExploreWorkHandlerScenario(
        label: 'supports only explore target',
        run: ewhRunSupportsOnlyExplore,
      ),
      ExploreWorkHandlerScenario(
        label: 'assigns explore currentWork when province has discoverable tiles',
        run: ewhRunAssignsExploreCurrentWork,
      ),
      ExploreWorkHandlerScenario(
        label: 'returns false when province has no tile keys in world state',
        run: ewhRunReturnsFalseNoTileKeys,
      ),
    ];
