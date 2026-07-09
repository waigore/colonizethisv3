// Compact application-helpers expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game ahGameWithResourceByTile(Map<String, String> resourceByTileKey) {
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

TileMapResult ahSingleTileMap({
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

void ahExpectParseTileKey(
  String tileKey, {
  required String regionId,
  required String provinceLocalId,
  required int x,
  required int y,
}) {
  final parsed = parseTileKeyCoordinates(tileKey);
  expect(parsed, isNotNull);
  expect(parsed!.regionId, regionId);
  expect(parsed.provinceLocalId, provinceLocalId);
  expect(parsed.x, x);
  expect(parsed.y, y);
}

void ahExpectMalformedTileKeys(List<String> tileKeys) {
  for (final key in tileKeys) {
    expect(parseTileKeyCoordinates(key), isNull);
  }
}

Unit ahWorkingUnit({
  required String id,
  String type = 'worker',
  String ownerId = 'p1',
  String locationProvinceId = 'oldWorld|P1',
  String tileKey = 'oldWorld|P1|2|2',
  String? originTileKey = 'oldWorld|P1|1|1',
  String? assignedTileKey = 'oldWorld|P1|3|3',
  String workTarget = kWorkTargetBuildRoad,
  String workTileKey = 'oldWorld|P1|3|3',
  int remainingTurns = 2,
  int totalTurns = 3,
}) {
  return Unit(
    id: id,
    type: type,
    ownerId: ownerId,
    locationProvinceId: locationProvinceId,
    tileKey: tileKey,
    originTileKey: originTileKey,
    assignedTileKey: assignedTileKey,
    status: UnitStatus.working,
    currentWork: CurrentWork(
      workTarget: workTarget,
      tileKey: workTileKey,
      remainingTurns: remainingTurns,
      totalTurns: totalTurns,
    ),
  );
}

void ahExpectCancelWorkClearsState(
  Unit unit, {
  String? restoredTile,
  required String expectedTile,
}) {
  final cancelled = cancelUnitWork(unit, restoredTile: restoredTile);
  expect(cancelled.status, UnitStatus.idle);
  expect(cancelled.tileKey, expectedTile);
  expect(cancelled.currentWork, isNull);
  if (restoredTile == null) {
    expect(cancelled.originTileKey, isNull);
    expect(cancelled.assignedTileKey, isNull);
  }
}

Game ahOwBuilderGame(
  Unit unit, {
  String playerId = 'gp1',
  String ow = 'oldWorld',
  String provinceLocalId = 'p1',
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: '$ow|$provinceLocalId',
            regionId: ow,
            ownerId: playerId,
          ),
        ],
        units: [unit],
      ),
      newWorld: const RegionData(),
    ),
    players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
  );
}

void ahExpectClearWorkUnchanged(Game game, String unitId) {
  final result = clearUnitCurrentWork(game, unitId);
  expect(identical(result, game), isTrue);
}

void ahExpectClearWorkIdleAtOrigin(Game game, String unitId, String originTile) {
  final result = clearUnitCurrentWork(game, unitId);
  final unit = result.worldState.oldWorld.units.single;
  expect(unit.currentWork, isNull);
  expect(unit.status, UnitStatus.idle);
  expect(unit.tileKey, originTile);
  expect(unit.originTileKey, isNull);
  expect(unit.assignedTileKey, isNull);
}

void ahExpectMineralEligible({
  required Map<String, String> resourceByTile,
  required String tileKey,
  Map<String, TileMapResult>? tileMapByRegion,
  required bool expected,
}) {
  final game = ahGameWithResourceByTile(resourceByTile);
  expect(
    isMineralEligibleTile(game, tileMapByRegion, tileKey),
    expected,
  );
}

const ahMineralTileKey = 'oldWorld|p1|0|0';

void ahExpectMountainProspectableWithoutResource() {
  ahExpectMineralEligible(
    resourceByTile: const {},
    tileKey: ahMineralTileKey,
    tileMapByRegion: {
      'oldWorld': ahSingleTileMap(terrain: TerrainType.mountain),
    },
    expected: true,
  );
}

void ahExpectPlainsGoldNotProspectable() {
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

void ahExpectHillsWoolNotProspectable() {
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

void ahExpectHillsIronProspectable() {
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

void ahExpectAbsentResourceNotMineral() {
  ahExpectMineralEligible(
    resourceByTile: const {},
    tileKey: ahMineralTileKey,
    expected: false,
  );
}

void ahExpectGrainNotMineral() {
  ahExpectMineralEligible(
    resourceByTile: const {ahMineralTileKey: 'grain'},
    tileKey: ahMineralTileKey,
    expected: false,
  );
}

void ahExpectCoalMineral() {
  ahExpectMineralEligible(
    resourceByTile: const {ahMineralTileKey: 'coal'},
    tileKey: ahMineralTileKey,
    expected: true,
  );
}

void ahExpectParseValidTileKeyDefault() {
  ahExpectParseTileKey(
    'oldWorld|P1|12|7',
    regionId: 'oldWorld',
    provinceLocalId: 'P1',
    x: 12,
    y: 7,
  );
}

void ahExpectParseMalformedTileKeysDefault() {
  ahExpectMalformedTileKeys(['oldWorld|P1|12', 'oldWorld|P1|x|7']);
}

void ahExpectCancelWorkDefault() {
  ahExpectCancelWorkClearsState(
    ahWorkingUnit(id: 'u1'),
    expectedTile: 'oldWorld|P1|1|1',
  );
}

void ahExpectCancelWorkRestoredTileOverride() {
  ahExpectCancelWorkClearsState(
    ahWorkingUnit(
      id: 'u2',
      originTileKey: null,
      assignedTileKey: null,
    ),
    restoredTile: 'oldWorld|P1|0|0',
    expectedTile: 'oldWorld|P1|0|0',
  );
}

void ahExpectClearWorkUnchangedIdleBuilder() {
  ahExpectClearWorkUnchanged(
    ahOwBuilderGame(ahIdleBuilderUnit()),
    'u1',
  );
}

void ahExpectClearWorkBuilderImprovementIdleAtOrigin() {
  ahExpectClearWorkIdleAtOrigin(
    ahOwBuilderGame(ahBuilderWithImprovementWork()),
    'u1',
    'oldWorld|p1|0|0',
  );
}

Unit ahIdleBuilderUnit({
  String id = 'u1',
  String ownerId = 'gp1',
  String locationProvinceId = 'oldWorld|p1',
  String tileKey = 'oldWorld|p1|0|0',
}) {
  return Unit(
    id: id,
    type: kUnitTypeBuilder,
    ownerId: ownerId,
    locationProvinceId: locationProvinceId,
    tileKey: tileKey,
  );
}

Unit ahBuilderWithImprovementWork({
  String id = 'u1',
  String ownerId = 'gp1',
  String locationProvinceId = 'oldWorld|p1',
  String tileKey = 'oldWorld|p1|0|0',
  String originTileKey = 'oldWorld|p1|0|0',
  String assignedTileKey = 'oldWorld|p1|1|0',
  String workTileKey = 'oldWorld|p1|1|0',
}) {
  return Unit(
    id: id,
    type: kUnitTypeBuilder,
    ownerId: ownerId,
    locationProvinceId: locationProvinceId,
    tileKey: tileKey,
    originTileKey: originTileKey,
    assignedTileKey: assignedTileKey,
    status: UnitStatus.working,
    currentWork: CurrentWork(
      workTarget: kWorkTargetBuildImprovement,
      tileKey: workTileKey,
      totalTurns: 2,
      remainingTurns: 1,
    ),
  );
}
