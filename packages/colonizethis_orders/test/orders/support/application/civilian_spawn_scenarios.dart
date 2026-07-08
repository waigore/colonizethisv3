// Table-driven civilian / New World spawn scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'civilian_spawn_expectations.dart';

/// One row in [civilianSpawnScenarios].
class CivilianSpawnScenario implements RefsScenario {
  const CivilianSpawnScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final CivilianSpawnTarget target;
  @override
  final String? refs;
}

void runCivilianSpawnScenario(CivilianSpawnScenario scenario) {
  runCivilianSpawnExpectation(scenario.target);
}

/// Canonical scenarios for civilian / New World spawn family tests.
List<CivilianSpawnScenario> civilianSpawnScenarios() => const [
  // dart format off
  CivilianSpawnScenario(
    label: 'civilian spawn uses capitalTile key even when spawnProvinceId is different owned province',
    target: CivilianSpawnTarget.civilianSpawnUsesCapitalTileKeyEvenWhenSpawnProvinceIdIsDifferentOwnedProvince,
  ),
  CivilianSpawnScenario(
    label: 'civilian build with empty spawnProvinceId uses capital tile and province',
    target: CivilianSpawnTarget.civilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince,
  ),
  CivilianSpawnScenario(
    label: 'civilian build with missing capital tile throws explicit error',
    target: CivilianSpawnTarget.civilianBuildWithMissingCapitalTileThrowsExplicitError,
  ),
  CivilianSpawnScenario(
    label: 'New World spawn adds unit to newWorld',
    target: CivilianSpawnTarget.newWorldSpawnAddsUnitToNewWorld,
  ),
  // dart format on
];
