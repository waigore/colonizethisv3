// Table-driven civilian / New World spawn scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'civilian_spawn_run_rows.dart';

/// One row in [civilianSpawnScenarios].
class CivilianSpawnScenario implements RefsScenario {
  const CivilianSpawnScenario({
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

void runCivilianSpawnScenario(CivilianSpawnScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for civilian / New World spawn family tests.
List<CivilianSpawnScenario> civilianSpawnScenarios() => const [
  // dart format off
  CivilianSpawnScenario(
    label: 'civilian spawn uses capitalTile key even when spawnProvinceId is different owned province',
    run: cspRunCivilianSpawnUsesCapitalTileKeyEvenWhenSpawnProvinceIdIsDifferentOwnedProvince,
  ),
  CivilianSpawnScenario(
    label: 'civilian build with empty spawnProvinceId uses capital tile and province',
    run: cspRunCivilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince,
  ),
  CivilianSpawnScenario(
    label: 'civilian build with missing capital tile throws explicit error',
    run: cspRunCivilianBuildWithMissingCapitalTileThrowsExplicitError,
  ),
  CivilianSpawnScenario(
    label: 'New World spawn adds unit to newWorld',
    run: cspRunNewWorldSpawnAddsUnitToNewWorld,
  ),
  // dart format on
];
