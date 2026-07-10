// Table-driven build_rail work-rules scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'build_rail_work_rules_run_rows.dart';

/// One row in [rejectionReasonForBuildRailOrderScenarios].
class RejectionReasonForBuildRailOrderScenario implements RefsScenario {
  const RejectionReasonForBuildRailOrderScenario({
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

void runRejectionReasonForBuildRailOrderScenario(
  RejectionReasonForBuildRailOrderScenario scenario,
) {
  scenario.run();
}

/// One row in [terrainTypeForTileKeyScenarios].
class TerrainTypeForTileKeyScenario implements RefsScenario {
  const TerrainTypeForTileKeyScenario({
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

void runTerrainTypeForTileKeyScenario(TerrainTypeForTileKeyScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for rejectionReasonForBuildRailOrder family tests.
List<RejectionReasonForBuildRailOrderScenario>
    rejectionReasonForBuildRailOrderScenarios() => const [
          RejectionReasonForBuildRailOrderScenario(
            label: 'rejects when road level is neither 1 nor 2 (too high)',
            run: brwrRunRejectsWhenRoadLevelTooHigh,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'rejects when road level is 3 (intermediate, not 1 or 2)',
            run: brwrRunRejectsWhenRoadLevelIntermediate,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'rejects when road level is 0',
            run: brwrRunRejectsWhenRoadLevelZero,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'rejects when terrain is null',
            run: brwrRunRejectsWhenTerrainNull,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'plains: rejects without rail tech',
            run: brwrRunPlainsRejectsWithoutRailTech,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'plains: allows with Early Steam',
            run: brwrRunPlainsAllowsWithEarlySteam,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'hills: rejects without Later Steam or Dynamite',
            run: brwrRunHillsRejectsWithoutLaterSteamOrDynamite,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'hills: allows with Later Steam',
            run: brwrRunHillsAllowsWithLaterSteam,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'mountain: rejects without Dynamite',
            run: brwrRunMountainRejectsWithoutDynamite,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'hills: allows with Dynamite only',
            run: brwrRunHillsAllowsWithDynamiteOnly,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'plains: allows with Later Steam only',
            run: brwrRunPlainsAllowsWithLaterSteamOnly,
          ),
          RejectionReasonForBuildRailOrderScenario(
            label: 'mountain: allows with Dynamite',
            run: brwrRunMountainAllowsWithDynamite,
          ),
        ];

/// Canonical scenarios for terrainTypeForTileKey family tests.
List<TerrainTypeForTileKeyScenario> terrainTypeForTileKeyScenarios() => const [
      TerrainTypeForTileKeyScenario(
        label: 'returns null for malformed tile key',
        run: ttftkRunMalformedTileKey,
      ),
      TerrainTypeForTileKeyScenario(
        label: 'returns null when region map is missing',
        run: ttftkRunMissingRegionMap,
      ),
      TerrainTypeForTileKeyScenario(
        label: 'returns null when x or y are not integers',
        run: ttftkRunNonIntegerCoordinates,
      ),
      TerrainTypeForTileKeyScenario(
        label: 'returns null when coordinates are out of bounds',
        run: ttftkRunOutOfBoundsCoordinates,
      ),
      TerrainTypeForTileKeyScenario(
        label: 'returns terrain from tile map',
        run: ttftkRunReturnsTerrainFromTileMap,
      ),
    ];
