// Table-driven propagate-road-to-adjacent-capital scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'propagate_road_to_adjacent_capital_expectations.dart';

/// One row in [propagateRoadToAdjacentCapitalScenarios].
class PropagateRoadToAdjacentCapitalScenario implements RefsScenario {
  const PropagateRoadToAdjacentCapitalScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final PropagateRoadToAdjacentCapitalTarget target;
  @override
  final String? refs;
}

void runPropagateRoadToAdjacentCapitalScenario(
  PropagateRoadToAdjacentCapitalScenario scenario,
) {
  runPropagateRoadToAdjacentCapitalExpectation(scenario.target);
}

/// Canonical scenarios for propagate_road_to_adjacent_capital family tests.
List<PropagateRoadToAdjacentCapitalScenario>
    propagateRoadToAdjacentCapitalScenarios() => const [
          PropagateRoadToAdjacentCapitalScenario(
            label: 'returns unchanged when player is null',
            target: PropagateRoadToAdjacentCapitalTarget.unchangedWhenPlayerNull,
          ),
          PropagateRoadToAdjacentCapitalScenario(
            label: 'returns unchanged when tile key is malformed',
            target:
                PropagateRoadToAdjacentCapitalTarget.unchangedWhenTileKeyMalformed,
          ),
          PropagateRoadToAdjacentCapitalScenario(
            label: 'propagates road level to adjacent capital tile when higher',
            target: PropagateRoadToAdjacentCapitalTarget
                .propagatesToAdjacentCapitalWhenHigher,
          ),
          PropagateRoadToAdjacentCapitalScenario(
            label: 'propagates road level to adjacent port tile when higher',
            target:
                PropagateRoadToAdjacentCapitalTarget.propagatesToAdjacentPortWhenHigher,
          ),
        ];
