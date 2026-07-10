// Table-driven propagate-road-to-adjacent-capital scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'propagate_road_to_adjacent_capital_run_rows.dart';

/// One row in [propagateRoadToAdjacentCapitalScenarios].
class PropagateRoadToAdjacentCapitalScenario implements RefsScenario {
  const PropagateRoadToAdjacentCapitalScenario({
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

void runPropagateRoadToAdjacentCapitalScenario(
  PropagateRoadToAdjacentCapitalScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for propagate_road_to_adjacent_capital family tests.
List<PropagateRoadToAdjacentCapitalScenario>
    propagateRoadToAdjacentCapitalScenarios() => const [
          PropagateRoadToAdjacentCapitalScenario(
            label: 'returns unchanged when player is null',
            run: pracRunUnchangedWhenPlayerNull,
          ),
          PropagateRoadToAdjacentCapitalScenario(
            label: 'returns unchanged when tile key is malformed',
            run: pracRunUnchangedWhenTileKeyMalformed,
          ),
          PropagateRoadToAdjacentCapitalScenario(
            label: 'propagates road level to adjacent capital tile when higher',
            run: pracRunPropagatesToAdjacentCapitalWhenHigher,
          ),
          PropagateRoadToAdjacentCapitalScenario(
            label: 'propagates road level to adjacent port tile when higher',
            run: pracRunPropagatesToAdjacentPortWhenHigher,
          ),
        ];
