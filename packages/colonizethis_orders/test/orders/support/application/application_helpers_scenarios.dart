// Table-driven application helpers / clearUnit / mineral eligibility scenarios
// (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'application_helpers_expectations.dart';

/// One row in [applicationHelpersScenarios].
class ApplicationHelpersScenario implements RefsScenario {
  const ApplicationHelpersScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final ApplicationHelpersTarget target;
  @override
  final String? refs;
}

void runApplicationHelpersScenario(ApplicationHelpersScenario scenario) {
  runApplicationHelpersExpectation(scenario.target);
}

/// Canonical scenarios for helpers + clearUnitCurrentWork family tests.
List<ApplicationHelpersScenario> applicationHelpersScenarios() => const [
  // dart format off
  ApplicationHelpersScenario(
    label: 'returns parsed coordinates for a valid tile key',
    target: ApplicationHelpersTarget.returnsParsedCoordinatesForAValidTileKey,
  ),
  ApplicationHelpersScenario(
    label: 'returns null for malformed tile key',
    target: ApplicationHelpersTarget.returnsNullForMalformedTileKey,
  ),
  ApplicationHelpersScenario(
    label: 'clears work state and restores origin tile by default',
    target: ApplicationHelpersTarget.clearsWorkStateAndRestoresOriginTileByDefault,
  ),
  ApplicationHelpersScenario(
    label: 'uses explicit restored tile override',
    target: ApplicationHelpersTarget.usesExplicitRestoredTileOverride,
  ),
  ApplicationHelpersScenario(
    label: 'returns game unchanged when unit has no currentWork',
    target: ApplicationHelpersTarget.returnsGameUnchangedWhenUnitHasNoCurrentWork,
  ),
  ApplicationHelpersScenario(
    label: 'clears currentWork, restores origin tile, and sets status idle',
    target: ApplicationHelpersTarget.clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle,
  ),
  ApplicationHelpersScenario(
    label: 'returns true for prospectable terrain even when no resource is present',
    target: ApplicationHelpersTarget.returnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent,
  ),
  ApplicationHelpersScenario(
    label: 'returns false for non-prospectable terrain even when mineral resource exists',
    target: ApplicationHelpersTarget.returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists,
  ),
  ApplicationHelpersScenario(
    label: 'returns false for wool on hills when tile map shows prospectable terrain',
    target: ApplicationHelpersTarget.returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain,
  ),
  ApplicationHelpersScenario(
    label: 'returns true for iron on hills with tile map when not prospected',
    target: ApplicationHelpersTarget.returnsTrueForIronOnHillsWithTileMapWhenNotProspected,
  ),
  ApplicationHelpersScenario(
    label: 'returns false when resource is absent',
    target: ApplicationHelpersTarget.returnsFalseWhenResourceIsAbsent,
  ),
  ApplicationHelpersScenario(
    label: 'returns false for non-mineral resource',
    target: ApplicationHelpersTarget.returnsFalseForNonMineralResource,
  ),
  ApplicationHelpersScenario(
    label: 'returns true for mineral resource',
    target: ApplicationHelpersTarget.returnsTrueForMineralResource,
  ),
  // dart format on
];
