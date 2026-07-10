// Table-driven application helpers / clearUnit / mineral eligibility scenarios
// (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'application_helpers_run_rows.dart';

/// One row in [applicationHelpersScenarios].
class ApplicationHelpersScenario implements RefsScenario {
  const ApplicationHelpersScenario({
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

void runApplicationHelpersScenario(ApplicationHelpersScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for helpers + clearUnitCurrentWork family tests.
List<ApplicationHelpersScenario> applicationHelpersScenarios() => const [
  // dart format off
  ApplicationHelpersScenario(
    label: 'returns parsed coordinates for a valid tile key',
    run: ahRunReturnsParsedCoordinatesForAValidTileKey,
  ),
  ApplicationHelpersScenario(
    label: 'returns null for malformed tile key',
    run: ahRunReturnsNullForMalformedTileKey,
  ),
  ApplicationHelpersScenario(
    label: 'clears work state and restores origin tile by default',
    run: ahRunClearsWorkStateAndRestoresOriginTileByDefault,
  ),
  ApplicationHelpersScenario(
    label: 'uses explicit restored tile override',
    run: ahRunUsesExplicitRestoredTileOverride,
  ),
  ApplicationHelpersScenario(
    label: 'returns game unchanged when unit has no currentWork',
    run: ahRunReturnsGameUnchangedWhenUnitHasNoCurrentWork,
  ),
  ApplicationHelpersScenario(
    label: 'clears currentWork, restores origin tile, and sets status idle',
    run: ahRunClearsCurrentWorkRestoresOriginTileAndSetsStatusIdle,
  ),
  ApplicationHelpersScenario(
    label: 'returns true for prospectable terrain even when no resource is present',
    run: ahRunReturnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent,
  ),
  ApplicationHelpersScenario(
    label: 'returns false for non-prospectable terrain even when mineral resource exists',
    run: ahRunReturnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists,
  ),
  ApplicationHelpersScenario(
    label: 'returns false for wool on hills when tile map shows prospectable terrain',
    run: ahRunReturnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain,
  ),
  ApplicationHelpersScenario(
    label: 'returns true for iron on hills with tile map when not prospected',
    run: ahRunReturnsTrueForIronOnHillsWithTileMapWhenNotProspected,
  ),
  ApplicationHelpersScenario(
    label: 'returns false when resource is absent',
    run: ahRunReturnsFalseWhenResourceIsAbsent,
  ),
  ApplicationHelpersScenario(
    label: 'returns false for non-mineral resource',
    run: ahRunReturnsFalseForNonMineralResource,
  ),
  ApplicationHelpersScenario(
    label: 'returns true for mineral resource',
    run: ahRunReturnsTrueForMineralResource,
  ),
  // dart format on
];
