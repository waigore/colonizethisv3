// Table-driven application helpers / clearUnit / mineral eligibility scenarios

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'application_helpers_expectation_shorthand.dart';

void ahRunReturnsParsedCoordinatesForAValidTileKey() {
  const tileKey = 'oldWorld|P1|12|7';
  final parsed = parseTileKeyCoordinates(tileKey);
  expect(parsed, isNotNull);
  expect(parsed!.regionId, 'oldWorld');
  expect(parsed.provinceLocalId, 'P1');
  expect(parsed.x, 12);
  expect(parsed.y, 7);
}

void ahRunReturnsNullForMalformedTileKey() {
  for (final key in ['oldWorld|P1|12', 'oldWorld|P1|x|7']) {
    expect(parseTileKeyCoordinates(key), isNull);
  }
}

void ahRunClearsWorkStateAndRestoresOriginTileByDefault() {
  ahExpectCancelWorkClearsState(
    ahWorkingUnit(id: 'u1'),
    expectedTile: 'oldWorld|P1|1|1',
  );
}

void ahRunUsesExplicitRestoredTileOverride() {
  ahExpectCancelWorkClearsState(
    ahWorkingUnit(id: 'u2', originTileKey: null, assignedTileKey: null),
    restoredTile: 'oldWorld|P1|0|0',
    expectedTile: 'oldWorld|P1|0|0',
  );
}

void ahRunReturnsGameUnchangedWhenUnitHasNoCurrentWork() {
  final game = ahOwBuilderGame(
    Unit(
      id: 'u1',
      type: kUnitTypeBuilder,
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|p1',
      tileKey: 'oldWorld|p1|0|0',
    ),
  );
  final result = clearUnitCurrentWork(game, 'u1');
  expect(identical(result, game), isTrue);
}

void ahRunClearsCurrentWorkRestoresOriginTileAndSetsStatusIdle() {
  const originTile = 'oldWorld|p1|0|0';
  final game = ahOwBuilderGame(
    Unit(
      id: 'u1',
      type: kUnitTypeBuilder,
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|p1',
      tileKey: originTile,
      originTileKey: originTile,
      assignedTileKey: 'oldWorld|p1|1|0',
      status: UnitStatus.working,
      currentWork: CurrentWork(
        workTarget: kWorkTargetBuildImprovement,
        tileKey: 'oldWorld|p1|1|0',
        totalTurns: 2,
        remainingTurns: 1,
      ),
    ),
  );
  final result = clearUnitCurrentWork(game, 'u1');
  final unit = result.worldState.oldWorld.units.single;
  expect(unit.currentWork, isNull);
  expect(unit.status, UnitStatus.idle);
  expect(unit.tileKey, originTile);
  expect(unit.originTileKey, isNull);
  expect(unit.assignedTileKey, isNull);
}

void ahRunReturnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent() {
  ahExpectMineralEligible(
    resourceByTile: const {},
    tileKey: ahMineralTileKey,
    tileMapByRegion: {
      'oldWorld': ahSingleTileMap(terrain: TerrainType.mountain),
    },
    expected: true,
  );
}

void ahRunReturnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists() {
  ahExpectMineralEligible(
    resourceByTile: const {ahMineralTileKey: 'gold'},
    tileKey: ahMineralTileKey,
    tileMapByRegion: {
      'oldWorld': ahSingleTileMap(
        terrain: TerrainType.plains,
        resource: Resource.gold,
      ),
    },
    expected: false,
  );
}

void ahRunReturnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain() {
  ahExpectMineralEligible(
    resourceByTile: const {ahMineralTileKey: 'wool'},
    tileKey: ahMineralTileKey,
    tileMapByRegion: {
      'oldWorld': ahSingleTileMap(
        terrain: TerrainType.hills,
        resource: Resource.wool,
      ),
    },
    expected: false,
  );
}

void ahRunReturnsTrueForIronOnHillsWithTileMapWhenNotProspected() {
  ahExpectMineralEligible(
    resourceByTile: const {ahMineralTileKey: 'iron'},
    tileKey: ahMineralTileKey,
    tileMapByRegion: {
      'oldWorld': ahSingleTileMap(
        terrain: TerrainType.hills,
        resource: Resource.iron,
      ),
    },
    expected: true,
  );
}

void ahRunReturnsFalseWhenResourceIsAbsent() {
  ahExpectMineralEligible(
    resourceByTile: const {},
    tileKey: ahMineralTileKey,
    expected: false,
  );
}

void ahRunReturnsFalseForNonMineralResource() {
  ahExpectMineralEligible(
    resourceByTile: const {ahMineralTileKey: 'grain'},
    tileKey: ahMineralTileKey,
    expected: false,
  );
}

void ahRunReturnsTrueForMineralResource() {
  ahExpectMineralEligible(
    resourceByTile: const {ahMineralTileKey: 'coal'},
    tileKey: ahMineralTileKey,
    expected: true,
  );
}

/// Canonical scenarios for helpers + clearUnitCurrentWork family tests.
List<RunnableScenario> applicationHelpersScenarios() => const [
  // dart format off
  rs('returns parsed coordinates for a valid tile key', ahRunReturnsParsedCoordinatesForAValidTileKey),
  rs('returns null for malformed tile key', ahRunReturnsNullForMalformedTileKey),
  rs('clears work state and restores origin tile by default', ahRunClearsWorkStateAndRestoresOriginTileByDefault),
  rs('uses explicit restored tile override', ahRunUsesExplicitRestoredTileOverride),
  rs('returns game unchanged when unit has no currentWork', ahRunReturnsGameUnchangedWhenUnitHasNoCurrentWork),
  rs('clears currentWork, restores origin tile, and sets status idle', ahRunClearsCurrentWorkRestoresOriginTileAndSetsStatusIdle),
  rs('returns true for prospectable terrain even when no resource is present', ahRunReturnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent),
  rs('returns false for non-prospectable terrain even when mineral resource exists', ahRunReturnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists),
  rs('returns false for wool on hills when tile map shows prospectable terrain', ahRunReturnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain),
  rs('returns true for iron on hills with tile map when not prospected', ahRunReturnsTrueForIronOnHillsWithTileMapWhenNotProspected),
  rs('returns false when resource is absent', ahRunReturnsFalseWhenResourceIsAbsent),
  rs('returns false for non-mineral resource', ahRunReturnsFalseForNonMineralResource),
  rs('returns true for mineral resource', ahRunReturnsTrueForMineralResource),
  // dart format on
];
