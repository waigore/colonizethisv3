// Compact orders_application_helpers + clearUnitCurrentWork assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Pins for [applicationHelpersScenarios] rows.
enum ApplicationHelpersTarget {
  returnsParsedCoordinatesForAValidTileKey,
  returnsNullForMalformedTileKey,
  clearsWorkStateAndRestoresOriginTileByDefault,
  usesExplicitRestoredTileOverride,
  returnsGameUnchangedWhenUnitHasNoCurrentWork,
  clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle,
  returnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent,
  returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists,
  returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain,
  returnsTrueForIronOnHillsWithTileMapWhenNotProspected,
  returnsFalseWhenResourceIsAbsent,
  returnsFalseForNonMineralResource,
  returnsTrueForMineralResource,
}

void runApplicationHelpersExpectation(ApplicationHelpersTarget target) {
  switch (target) {
    case ApplicationHelpersTarget.returnsParsedCoordinatesForAValidTileKey:
      _returnsParsedCoordinatesForAValidTileKey();
    case ApplicationHelpersTarget.returnsNullForMalformedTileKey:
      _returnsNullForMalformedTileKey();
    case ApplicationHelpersTarget.clearsWorkStateAndRestoresOriginTileByDefault:
      _clearsWorkStateAndRestoresOriginTileByDefault();
    case ApplicationHelpersTarget.usesExplicitRestoredTileOverride:
      _usesExplicitRestoredTileOverride();
    case ApplicationHelpersTarget.returnsGameUnchangedWhenUnitHasNoCurrentWork:
      _returnsGameUnchangedWhenUnitHasNoCurrentWork();
    case ApplicationHelpersTarget
        .clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle:
      _clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle();
    case ApplicationHelpersTarget
        .returnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent:
      _returnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent();
    case ApplicationHelpersTarget
        .returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists:
      _returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists();
    case ApplicationHelpersTarget
        .returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain:
      _returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain();
    case ApplicationHelpersTarget
        .returnsTrueForIronOnHillsWithTileMapWhenNotProspected:
      _returnsTrueForIronOnHillsWithTileMapWhenNotProspected();
    case ApplicationHelpersTarget.returnsFalseWhenResourceIsAbsent:
      _returnsFalseWhenResourceIsAbsent();
    case ApplicationHelpersTarget.returnsFalseForNonMineralResource:
      _returnsFalseForNonMineralResource();
    case ApplicationHelpersTarget.returnsTrueForMineralResource:
      _returnsTrueForMineralResource();
  }
}

Game _gameWithResourceByTile(Map<String, String> resourceByTileKey) {
  return Game(
    id: 'g-test',
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    minorNations: const [],
    tribes: const [],
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey,
    ),
  );
}

TileMapResult _singleTileMap({
  required TerrainType terrain,
  Resource? resource,
}) {
  return TileMapResult(
    width: 1,
    height: 1,
    grid: const [
      ['p1'],
    ],
    terrainGrid: [
      [terrain],
    ],
    resourceGrid: [
      [resource],
    ],
  );
}

void _returnsParsedCoordinatesForAValidTileKey() {
  final parsed = parseTileKeyCoordinates('oldWorld|P1|12|7');
  expect(parsed, isNotNull);
  expect(parsed!.regionId, 'oldWorld');
  expect(parsed.provinceLocalId, 'P1');
  expect(parsed.x, 12);
  expect(parsed.y, 7);
}

void _returnsNullForMalformedTileKey() {
  expect(parseTileKeyCoordinates('oldWorld|P1|12'), isNull);
  expect(parseTileKeyCoordinates('oldWorld|P1|x|7'), isNull);
}

void _clearsWorkStateAndRestoresOriginTileByDefault() {
  final unit = Unit(
    id: 'u1',
    type: 'worker',
    ownerId: 'p1',
    locationProvinceId: 'oldWorld|P1',
    tileKey: 'oldWorld|P1|2|2',
    originTileKey: 'oldWorld|P1|1|1',
    assignedTileKey: 'oldWorld|P1|3|3',
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildRoad,
      tileKey: 'oldWorld|P1|3|3',
      remainingTurns: 2,
      totalTurns: 3,
    ),
  );
  final cancelled = cancelUnitWork(unit);
  expect(cancelled.status, UnitStatus.idle);
  expect(cancelled.tileKey, 'oldWorld|P1|1|1');
  expect(cancelled.currentWork, isNull);
  expect(cancelled.originTileKey, isNull);
  expect(cancelled.assignedTileKey, isNull);
}

void _usesExplicitRestoredTileOverride() {
  final unit = Unit(
    id: 'u2',
    type: 'worker',
    ownerId: 'p1',
    locationProvinceId: 'oldWorld|P1',
    tileKey: 'oldWorld|P1|2|2',
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildRoad,
      tileKey: 'oldWorld|P1|3|3',
      remainingTurns: 2,
      totalTurns: 3,
    ),
  );
  final cancelled = cancelUnitWork(unit, restoredTile: 'oldWorld|P1|0|0');
  expect(cancelled.tileKey, 'oldWorld|P1|0|0');
  expect(cancelled.currentWork, isNull);
}

void _returnsGameUnchangedWhenUnitHasNoCurrentWork() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
    tileKey: 'oldWorld|p1|0|0',
  );
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: playerId)],
        units: [unit],
      ),
      newWorld: const RegionData(),
    ),
    players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
  );
  final result = clearUnitCurrentWork(game, 'u1');
  expect(identical(result, game), isTrue);
}

void _clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
    tileKey: 'oldWorld|p1|0|0',
    originTileKey: 'oldWorld|p1|0|0',
    assignedTileKey: 'oldWorld|p1|1|0',
    status: UnitStatus.working,
    currentWork: CurrentWork(
      workTarget: kWorkTargetBuildImprovement,
      tileKey: 'oldWorld|p1|1|0',
      totalTurns: 2,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: playerId)],
        units: [unit],
      ),
      newWorld: const RegionData(),
    ),
    players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
  );
  final result = clearUnitCurrentWork(game, 'u1');
  expect(result.worldState.oldWorld.units.length, 1);
  expect(result.worldState.oldWorld.units.single.currentWork, isNull);
  expect(result.worldState.oldWorld.units.single.status, UnitStatus.idle);
  expect(result.worldState.oldWorld.units.single.tileKey, 'oldWorld|p1|0|0');
  expect(result.worldState.oldWorld.units.single.originTileKey, isNull);
  expect(result.worldState.oldWorld.units.single.assignedTileKey, isNull);
}

void _returnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent() {
  final game = _gameWithResourceByTile(const {});
  const tileKey = 'oldWorld|p1|0|0';
  final tileMapByRegion = <String, TileMapResult>{
    'oldWorld': _singleTileMap(terrain: TerrainType.mountain),
  };
  expect(isMineralEligibleTile(game, tileMapByRegion, tileKey), isTrue);
}

void _returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists() {
  final game = _gameWithResourceByTile(const {'oldWorld|p1|0|0': 'gold'});
  const tileKey = 'oldWorld|p1|0|0';
  final tileMapByRegion = <String, TileMapResult>{
    'oldWorld': _singleTileMap(
      terrain: TerrainType.plains,
      resource: Resource.gold,
    ),
  };
  expect(isMineralEligibleTile(game, tileMapByRegion, tileKey), isFalse);
}

void _returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain() {
  final game = _gameWithResourceByTile(const {'oldWorld|p1|0|0': 'wool'});
  const tileKey = 'oldWorld|p1|0|0';
  final tileMapByRegion = <String, TileMapResult>{
    'oldWorld': _singleTileMap(
      terrain: TerrainType.hills,
      resource: Resource.wool,
    ),
  };
  expect(isMineralEligibleTile(game, tileMapByRegion, tileKey), isFalse);
}

void _returnsTrueForIronOnHillsWithTileMapWhenNotProspected() {
  final game = _gameWithResourceByTile(const {'oldWorld|p1|0|0': 'iron'});
  const tileKey = 'oldWorld|p1|0|0';
  final tileMapByRegion = <String, TileMapResult>{
    'oldWorld': _singleTileMap(
      terrain: TerrainType.hills,
      resource: Resource.iron,
    ),
  };
  expect(isMineralEligibleTile(game, tileMapByRegion, tileKey), isTrue);
}

void _returnsFalseWhenResourceIsAbsent() {
  final game = _gameWithResourceByTile(const {});
  expect(isMineralEligibleTile(game, null, 'oldWorld|p1|0|0'), isFalse);
}

void _returnsFalseForNonMineralResource() {
  final game = _gameWithResourceByTile(const {'oldWorld|p1|0|0': 'grain'});
  expect(isMineralEligibleTile(game, null, 'oldWorld|p1|0|0'), isFalse);
}

void _returnsTrueForMineralResource() {
  final game = _gameWithResourceByTile(const {'oldWorld|p1|0|0': 'coal'});
  expect(isMineralEligibleTile(game, null, 'oldWorld|p1|0|0'), isTrue);
}
