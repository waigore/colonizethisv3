// Table-driven build_rail work-rules scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/build_rail_work_rules.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

const _early = kTechIdEarlySteamEngine;
const _later = kTechIdLaterSteamEngine;
const _dynamite = kTechIdDynamite;
// dart format off

void brwrRunRejectsWhenRoadLevelTooHigh() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {_early: true},roadLevel: 4,terrain: TerrainType.plains,),'Tile already has maximum transport level',);}

void brwrRunRejectsWhenRoadLevelIntermediate() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {_early: true},roadLevel: 3,terrain: TerrainType.plains,),'Railroad requires an existing road (transport level 1 or 2) on the tile',);}

void brwrRunRejectsWhenRoadLevelZero() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {_early: true},roadLevel: 0,terrain: TerrainType.plains,),'Railroad requires an existing road (transport level 1 or 2) on the tile',);}

void brwrRunRejectsWhenTerrainNull() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {_early: true},roadLevel: 1,terrain: null,),'Tile terrain data required for railroad work orders',);}

void brwrRunPlainsRejectsWithoutRailTech() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {},roadLevel: 1,terrain: TerrainType.plains,),'Early Steam Engine or later rail technology required for this terrain',);}

void brwrRunPlainsAllowsWithEarlySteam() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {_early: true},roadLevel: 2,terrain: TerrainType.hardwoodForest,),isNull,);}

void brwrRunHillsRejectsWithoutLaterSteamOrDynamite() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {_early: true},roadLevel: 1,terrain: TerrainType.hills,),'Later Steam Engine or Dynamite required for rail on this terrain',);}

void brwrRunHillsAllowsWithLaterSteam() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {_later: true},roadLevel: 1,terrain: TerrainType.swamp,),isNull,);}

void brwrRunMountainRejectsWithoutDynamite() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {_early: true,_later: true},roadLevel: 1,terrain: TerrainType.mountain,),'Dynamite required for rail in mountains',);}

void brwrRunHillsAllowsWithDynamiteOnly() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {_dynamite: true},roadLevel: 2,terrain: TerrainType.hills,),isNull,);}

void brwrRunPlainsAllowsWithLaterSteamOnly() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {_later: true},roadLevel: 1,terrain: TerrainType.desert,),isNull,);}

void brwrRunMountainAllowsWithDynamite() {expect(rejectionReasonForBuildRailOrder(techUnlocked: const {_dynamite: true},roadLevel: 1,terrain: TerrainType.mountain,),isNull,);}

void ttftkRunMalformedTileKey() {expect(terrainTypeForTileKey(null,'bad'),isNull);}

void ttftkRunMissingRegionMap() {expect(terrainTypeForTileKey({},'oldWorld|P|0|0'),isNull);}

void ttftkRunNonIntegerCoordinates() {final m = TileMapResult(width: 1,height: 1,grid: const [['P'],],terrainGrid: [[TerrainType.plains],],); expect(terrainTypeForTileKey({'oldWorld': m},'oldWorld|P|x|0'),isNull);}

void ttftkRunOutOfBoundsCoordinates() {final m = TileMapResult(width: 1,height: 1,grid: const [['P'],],terrainGrid: [[TerrainType.plains],],); expect(terrainTypeForTileKey({'oldWorld': m},'oldWorld|P|1|0'),isNull);}

void ttftkRunReturnsTerrainFromTileMap() {final m = TileMapResult(width: 1,height: 1,grid: const [['P'],],terrainGrid: [[TerrainType.desert],],); expect(terrainTypeForTileKey({'oldWorld': m},'oldWorld|P|0|0'),TerrainType.desert,);}

/// Canonical scenarios for rejectionReasonForBuildRailOrder family tests.
List<RunnableScenario> rejectionReasonForBuildRailOrderScenarios() => [
  rs('rejects when road level is neither 1 nor 2 (too high)', brwrRunRejectsWhenRoadLevelTooHigh),
  rs('rejects when road level is 3 (intermediate, not 1 or 2)', brwrRunRejectsWhenRoadLevelIntermediate),
  rs('rejects when road level is 0', brwrRunRejectsWhenRoadLevelZero),
  rs('rejects when terrain is null', brwrRunRejectsWhenTerrainNull),
  rs('plains: rejects without rail tech', brwrRunPlainsRejectsWithoutRailTech),
  rs('plains: allows with Early Steam', brwrRunPlainsAllowsWithEarlySteam),
  rs('hills: rejects without Later Steam or Dynamite', brwrRunHillsRejectsWithoutLaterSteamOrDynamite),
  rs('hills: allows with Later Steam', brwrRunHillsAllowsWithLaterSteam),
  rs('mountain: rejects without Dynamite', brwrRunMountainRejectsWithoutDynamite),
  rs('hills: allows with Dynamite only', brwrRunHillsAllowsWithDynamiteOnly),
  rs('plains: allows with Later Steam only', brwrRunPlainsAllowsWithLaterSteamOnly),
  rs('mountain: allows with Dynamite', brwrRunMountainAllowsWithDynamite),
];

/// Canonical scenarios for terrainTypeForTileKey family tests.
List<RunnableScenario> terrainTypeForTileKeyScenarios() => [
  rs('returns null for malformed tile key', ttftkRunMalformedTileKey),
  rs('returns null when region map is missing', ttftkRunMissingRegionMap),
  rs('returns null when x or y are not integers', ttftkRunNonIntegerCoordinates),
  rs('returns null when coordinates are out of bounds', ttftkRunOutOfBoundsCoordinates),
  rs('returns terrain from tile map', ttftkRunReturnsTerrainFromTileMap),
];
