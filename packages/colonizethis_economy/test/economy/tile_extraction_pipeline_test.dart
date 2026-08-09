import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
const _tileKey = 'oldWorld|p1|0|0';
const _provinceId = 'oldWorld|p1';

void runTileContributionConnectedPin({required TileMapResult grainTileMap, required TileContributionConnectedPin pins}) {
  const connected = {_tileKey};
  final player = spainPl1Player(capitalProvinceId: _provinceId);
  final game = TestFixtures.minimalGame(
    id: 'g1',
    capitalTileGrainBonusPerTurn: 5,
    oldWorld: RegionData(
      provinces: [Province(id: _provinceId, regionId: 'oldWorld', ownerId: 'pl1', townDevelopmentLevel: 4)],
    ),
    tileState: tileStateFromSpecs(const [TileImprovementSpec(_tileKey, 1, 1)]),
    players: [player],
  );
  final contribution = computeTileExtractionContributionForPlayer(game: game, tileMapByRegion: {'oldWorld': grainTileMap}, player: player, tileKey: _tileKey, connectedTileKeys: connected, pathTransportCap: const {}, connectedByRoadRule: connected, portTileKeys: const {}, prospectedTileKeys: connected, capitalRegionId: 'oldWorld', techCapForPlayer: (_) => 4);
  expect(contribution, isNotNull);
  expect(contribution!.commodityId, pins.commodityId);
  expect(contribution.units, pins.units);
  if (pins.verifyProvinceIndexParity) {
    final provincesByFullId = {for (final p in game.worldState.oldWorld.provinces) p.id: p, for (final p in game.worldState.newWorld.provinces) p.id: p};
    final withIndex = computeTileExtractionContributionForPlayer(game: game, tileMapByRegion: {'oldWorld': grainTileMap}, player: player, tileKey: _tileKey, connectedTileKeys: connected, pathTransportCap: const {}, connectedByRoadRule: connected, portTileKeys: const {}, prospectedTileKeys: connected, capitalRegionId: 'oldWorld', techCapForPlayer: (_) => 4, provincesByFullId: provincesByFullId);
    expect(withIndex, isNotNull);
    expect(withIndex!.commodityId, contribution.commodityId);
    expect(withIndex.units, contribution.units);
  }
}

void runTileContributionDisconnectedPin({required TileMapResult grainTileMap}) {
  final player = spainPl1Player(capitalProvinceId: _provinceId);
  final game = TestFixtures.minimalGame(
    id: 'g1',
    oldWorld: RegionData(
      provinces: [Province(id: _provinceId, regionId: 'oldWorld', ownerId: 'pl1', townDevelopmentLevel: 4)],
    ),
    tileState: TileMapState(),
    players: [player],
  );
  final contribution = computeTileExtractionContributionForPlayer(game: game, tileMapByRegion: {'oldWorld': grainTileMap}, player: player, tileKey: _tileKey, connectedTileKeys: const {}, pathTransportCap: const {}, connectedByRoadRule: const {}, portTileKeys: const {}, prospectedTileKeys: const {}, capitalRegionId: 'oldWorld', techCapForPlayer: (_) => 4);
  expect(contribution, isNull);
}

void runTileExtractionContributionScenario(
  TileExtractionContributionScenario scenario,
) {
  final tileMap = scenario.grainTileMap ?? singleTileMap(Resource.grain);
  switch (scenario.pin) {
    case TileExtractionContributionPin.connectedGrainExcludesCapitalBonus:
      runTileContributionConnectedPin(
        grainTileMap: tileMap,
        pins: scenario.connectedPins!,
      );
    case TileExtractionContributionPin.disconnectedNull:
      runTileContributionDisconnectedPin(grainTileMap: tileMap);
  }
}

const _resourceContextProvinceId = 'oldWorld|p1';

TileMapResult _tileMapForResourceContext() {
  return nonGpProvMap(_resourceContextProvinceId, [
    [Resource.grain, Resource.iron],
  ]);
}

Map<String, TileMapResult> _resourceContextTileMapByRegion() => {'oldWorld': _tileMapForResourceContext()};

void runResolveTileKeyResourceContextExpectation(ResolveTileKeyResourceContextTarget target) {
  final tileMapByRegion = _resourceContextTileMapByRegion();
  switch (target) {
    case ResolveTileKeyResourceContextTarget.validGrain:
      final ctx = resolveTileKeyResourceContext(tileKey: '$_resourceContextProvinceId|0|0', tileMapByRegion: tileMapByRegion);
      expect(ctx, isNotNull);
      expect(ctx!.commodityId, 'grain');
      expect(ctx.provinceId, _resourceContextProvinceId);
      expect(ctx.resource, Resource.grain);
    case ResolveTileKeyResourceContextTarget.ironCommodityMapping:
      final ctx = resolveTileKeyResourceContext(tileKey: '$_resourceContextProvinceId|1|0', tileMapByRegion: tileMapByRegion);
      expect(ctx!.commodityId, Resource.iron.name);
      expect(ctx.commodityId, 'iron');
    case ResolveTileKeyResourceContextTarget.invalidKeys:
      for (final tileKey in ['bad-key', '$_resourceContextProvinceId|-1|0', 'newWorld|p1|0|0']) {
        expect(resolveTileKeyResourceContext(tileKey: tileKey, tileMapByRegion: tileMapByRegion), isNull);
      }
  }
}

void runResolveTileKeyResourceContextScenario(
  ResolveTileKeyResourceContextScenario scenario,
) {
  runResolveTileKeyResourceContextExpectation(scenario.target);
}

const _extractionContextProvinceId = 'oldWorld|p1';

({Map<String, TileMapResult> tileMapByRegion, Province province}) _extractionContextFixtures() {
  final province = capitalProvinceForNonGpExtractionTest(provinceId: _extractionContextProvinceId);
  final tileMap = nonGpProvMap(_extractionContextProvinceId, [
    [Resource.grain],
  ]);
  return (tileMapByRegion: {'oldWorld': tileMap}, province: province);
}

void runResolveTileKeyExtractionContextExpectation(ResolveTileKeyExtractionContextTarget target) {
  final fixtures = _extractionContextFixtures();
  final tileKey = '$_extractionContextProvinceId|0|0';
  switch (target) {
    case ResolveTileKeyExtractionContextTarget.fromIndex:
      final ctx = resolveTileKeyExtractionContext(tileKey: tileKey, tileMapByRegion: fixtures.tileMapByRegion, provincesByFullId: {_extractionContextProvinceId: fixtures.province}, logContext: 'test');
      expect(ctx, isNotNull);
      expect(ctx!.province.id, _extractionContextProvinceId);
      expect(ctx.commodityId, 'grain');
    case ResolveTileKeyExtractionContextTarget.fallbackGame:
      final game = gameForNonGpExtractionTest(provinces: [fixtures.province]);
      final ctx = resolveTileKeyExtractionContext(tileKey: tileKey, tileMapByRegion: fixtures.tileMapByRegion, game: game, logContext: 'test');
      expect(ctx!.province.id, _extractionContextProvinceId);
    case ResolveTileKeyExtractionContextTarget.missingProvince:
      final ctx = resolveTileKeyExtractionContext(tileKey: tileKey, tileMapByRegion: fixtures.tileMapByRegion, provincesByFullId: const {}, logContext: 'test');
      expect(ctx, isNull);
  }
}

void runResolveTileKeyExtractionContextScenario(ResolveTileKeyExtractionContextScenario scenario) {
  runResolveTileKeyExtractionContextExpectation(scenario.target);
}
// dart format on

final TileMapResult _grainTileMap = singleTileMap(Resource.grain);

void main() {
  runLabeledScenarioGroup(
    'resolveTileKeyResourceContext',
    resolveTileKeyResourceContextScenarios(),
    runResolveTileKeyResourceContextScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'resolveTileKeyExtractionContext',
    resolveTileKeyExtractionContextScenarios(),
    runResolveTileKeyExtractionContextScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'computeTileExtractionContributionForPlayer',
    tileExtractionContributionScenarios(grainTileMap: _grainTileMap),
    runTileExtractionContributionScenario,
    labelOf: (s) => s.label,
  );
}
