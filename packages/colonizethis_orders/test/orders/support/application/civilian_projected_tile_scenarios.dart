// Table-driven civilian projected-tile scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'civilian_projected_tile_run_rows.dart';

/// One row in [civilianProjectedTileScenarios].
class CivilianProjectedTileScenario implements RefsScenario {
  const CivilianProjectedTileScenario({
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

void runCivilianProjectedTileScenario(CivilianProjectedTileScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for civilian_projected_tile family tests.
List<CivilianProjectedTileScenario> civilianProjectedTileScenarios() =>
    const [
      CivilianProjectedTileScenario(
        label: 'prefers pending work-order target tile key',
        run: cptRunPrefersPendingWorkOrderTargetTileKey,
      ),
      CivilianProjectedTileScenario(
        label: 'keeps exact pending tile key for explore projection',
        run: cptRunKeepsExactPendingTileKeyForExplore,
      ),
    ];
