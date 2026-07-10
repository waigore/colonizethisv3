// Table-driven civilian projected-tile scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'civilian_projected_tile_expectations.dart';

/// One row in [civilianProjectedTileScenarios].
class CivilianProjectedTileScenario implements RefsScenario {
  const CivilianProjectedTileScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final CivilianProjectedTileTarget target;
  @override
  final String? refs;
}

void runCivilianProjectedTileScenario(CivilianProjectedTileScenario scenario) {
  runCivilianProjectedTileExpectation(scenario.target);
}

/// Canonical scenarios for civilian_projected_tile family tests.
List<CivilianProjectedTileScenario> civilianProjectedTileScenarios() =>
    const [
      CivilianProjectedTileScenario(
        label: 'prefers pending work-order target tile key',
        target: CivilianProjectedTileTarget.prefersPendingWorkOrderTargetTileKey,
      ),
      CivilianProjectedTileScenario(
        label: 'keeps exact pending tile key for explore projection',
        target: CivilianProjectedTileTarget.keepsExactPendingTileKeyForExplore,
      ),
    ];
