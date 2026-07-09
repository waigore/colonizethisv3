// Table-driven build_rail work-rules scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'build_rail_work_rules_expectations.dart';

/// One row in [rejectionReasonForBuildRailOrderScenarios].
class RejectionReasonForBuildRailOrderScenario implements RefsScenario {
  const RejectionReasonForBuildRailOrderScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final RejectionReasonForBuildRailOrderTarget target;
  @override
  final String? refs;
}

void runRejectionReasonForBuildRailOrderScenario(
  RejectionReasonForBuildRailOrderScenario scenario,
) {
  runRejectionReasonForBuildRailOrderExpectation(scenario.target);
}

/// One row in [terrainTypeForTileKeyScenarios].
class TerrainTypeForTileKeyScenario implements RefsScenario {
  const TerrainTypeForTileKeyScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final TerrainTypeForTileKeyTarget target;
  @override
  final String? refs;
}

void runTerrainTypeForTileKeyScenario(TerrainTypeForTileKeyScenario scenario) {
  runTerrainTypeForTileKeyExpectation(scenario.target);
}

/// Canonical scenarios for rejectionReasonForBuildRailOrder family tests.
List<RejectionReasonForBuildRailOrderScenario>
    rejectionReasonForBuildRailOrderScenarios() => const [
          RejectionReasonForBuildRailOrderScenario(
            label: 'rejects when road level is neither 1 nor 2 (too high)',
            target: RejectionReasonForBuildRailOrderTarget.rejectsWhenRoadLevelTooHigh,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'rejects when road level is 3 (intermediate, not 1 or 2)',
            target:
                RejectionReasonForBuildRailOrderTarget.rejectsWhenRoadLevelIntermediate,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'rejects when road level is 0',
            target: RejectionReasonForBuildRailOrderTarget.rejectsWhenRoadLevelZero,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'rejects when terrain is null',
            target: RejectionReasonForBuildRailOrderTarget.rejectsWhenTerrainNull,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'plains: rejects without rail tech',
            target: RejectionReasonForBuildRailOrderTarget.plainsRejectsWithoutRailTech,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'plains: allows with Early Steam',
            target: RejectionReasonForBuildRailOrderTarget.plainsAllowsWithEarlySteam,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'hills: rejects without Later Steam or Dynamite',
            target: RejectionReasonForBuildRailOrderTarget
                .hillsRejectsWithoutLaterSteamOrDynamite,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'hills: allows with Later Steam',
            target: RejectionReasonForBuildRailOrderTarget.hillsAllowsWithLaterSteam,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'mountain: rejects without Dynamite',
            target:
                RejectionReasonForBuildRailOrderTarget.mountainRejectsWithoutDynamite,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'hills: allows with Dynamite only',
            target: RejectionReasonForBuildRailOrderTarget.hillsAllowsWithDynamiteOnly,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'plains: allows with Later Steam only',
            target:
                RejectionReasonForBuildRailOrderTarget.plainsAllowsWithLaterSteamOnly,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'mountain: allows with Dynamite',
            target: RejectionReasonForBuildRailOrderTarget.mountainAllowsWithDynamite,
          ),
        ];

/// Canonical scenarios for terrainTypeForTileKey family tests.
List<TerrainTypeForTileKeyScenario> terrainTypeForTileKeyScenarios() => const [
      TerrainTypeForTileKeyScenario(
        label: 'returns null for malformed tile key',
        target: TerrainTypeForTileKeyTarget.malformedTileKey,
      ),
      TerrainTypeForTileKeyScenario(
        label: 'returns null when region map is missing',
        target: TerrainTypeForTileKeyTarget.missingRegionMap,
      ),
      TerrainTypeForTileKeyScenario(
        label: 'returns null when x or y are not integers',
        target: TerrainTypeForTileKeyTarget.nonIntegerCoordinates,
      ),
      TerrainTypeForTileKeyScenario(
        label: 'returns null when coordinates are out of bounds',
        target: TerrainTypeForTileKeyTarget.outOfBoundsCoordinates,
      ),
      TerrainTypeForTileKeyScenario(
        label: 'returns terrain from tile map',
        target: TerrainTypeForTileKeyTarget.returnsTerrainFromTileMap,
      ),
    ];
