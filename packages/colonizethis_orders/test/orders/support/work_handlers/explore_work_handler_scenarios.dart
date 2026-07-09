// Table-driven explore work handler scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'explore_work_handler_expectations.dart';

/// One row in [exploreWorkHandlerScenarios].
class ExploreWorkHandlerScenario implements RefsScenario {
  const ExploreWorkHandlerScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final ExploreWorkHandlerTarget target;
  @override
  final String? refs;
}

void runExploreWorkHandlerScenario(ExploreWorkHandlerScenario scenario) {
  runExploreWorkHandlerExpectation(scenario.target);
}

/// Canonical scenarios for explore_work_handler family tests.
List<ExploreWorkHandlerScenario> exploreWorkHandlerScenarios() => const [
      ExploreWorkHandlerScenario(
        label: 'supports only explore target',
        target: ExploreWorkHandlerTarget.supportsOnlyExplore,
      ),
      ExploreWorkHandlerScenario(
        label: 'assigns explore currentWork when province has discoverable tiles',
        target: ExploreWorkHandlerTarget.assignsExploreCurrentWork,
      ),
      ExploreWorkHandlerScenario(
        label: 'returns false when province has no tile keys in world state',
        target: ExploreWorkHandlerTarget.returnsFalseNoTileKeys,
      ),
    ];
