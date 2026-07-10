// Compact tile extraction pipeline assertions (Refs #3939 phase 3 slice 37).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'extraction_fixture_support.dart';
import 'tile_extraction_pipeline_scenarios.dart';

const _resourceContextProvinceId = 'oldWorld|p1';

TileMapResult _tileMapForResourceContext() {
  return nonGpProvMap(_resourceContextProvinceId, 2, 1, [
    [Resource.grain, Resource.iron],
  ]);
}

Map<String, TileMapResult> _resourceContextTileMapByRegion() => {
  'oldWorld': _tileMapForResourceContext(),
};

/// Pins for [resolveTileKeyResourceContext] rows.
enum ResolveTileKeyResourceContextTarget {
  validGrain,
  ironCommodityMapping,
  invalidKeys,
}

void runResolveTileKeyResourceContextExpectation(
  ResolveTileKeyResourceContextTarget target,
) {
  final tileMapByRegion = _resourceContextTileMapByRegion();
  switch (target) {
    case ResolveTileKeyResourceContextTarget.validGrain:
      final ctx = resolveTileKeyResourceContext(
        tileKey: '$_resourceContextProvinceId|0|0',
        tileMapByRegion: tileMapByRegion,
      );
      expect(ctx, isNotNull);
      expect(ctx!.commodityId, 'grain');
      expect(ctx.provinceId, _resourceContextProvinceId);
      expect(ctx.resource, Resource.grain);
    case ResolveTileKeyResourceContextTarget.ironCommodityMapping:
      final ctx = resolveTileKeyResourceContext(
        tileKey: '$_resourceContextProvinceId|1|0',
        tileMapByRegion: tileMapByRegion,
      );
      expect(ctx!.commodityId, Resource.iron.name);
      expect(ctx.commodityId, 'iron');
    case ResolveTileKeyResourceContextTarget.invalidKeys:
      for (final tileKey in [
        'bad-key',
        '$_resourceContextProvinceId|-1|0',
        'newWorld|p1|0|0',
      ]) {
        expect(
          resolveTileKeyResourceContext(
            tileKey: tileKey,
            tileMapByRegion: tileMapByRegion,
          ),
          isNull,
        );
      }
  }
}

ResolveTileKeyResourceContextScenario resolveTileKeyResourceContextScenario({
  required String label,
  required ResolveTileKeyResourceContextTarget target,
  String? refs,
}) => (
  label: label,
  run: () => runResolveTileKeyResourceContextExpectation(target),
  refs: refs,
);

const _extractionContextProvinceId = 'oldWorld|p1';

({Map<String, TileMapResult> tileMapByRegion, Province province})
_extractionContextFixtures() {
  final province = capitalProvinceForNonGpExtractionTest(
    provinceId: _extractionContextProvinceId,
  );
  final tileMap = nonGpProvMap(_extractionContextProvinceId, 1, 1, [
    [Resource.grain],
  ]);
  return (tileMapByRegion: {'oldWorld': tileMap}, province: province);
}

/// Pins for [resolveTileKeyExtractionContext] rows.
enum ResolveTileKeyExtractionContextTarget {
  fromIndex,
  fallbackGame,
  missingProvince,
}

void runResolveTileKeyExtractionContextExpectation(
  ResolveTileKeyExtractionContextTarget target,
) {
  final fixtures = _extractionContextFixtures();
  final tileKey = '$_extractionContextProvinceId|0|0';
  switch (target) {
    case ResolveTileKeyExtractionContextTarget.fromIndex:
      final ctx = resolveTileKeyExtractionContext(
        tileKey: tileKey,
        tileMapByRegion: fixtures.tileMapByRegion,
        provincesByFullId: {_extractionContextProvinceId: fixtures.province},
        logContext: 'test',
      );
      expect(ctx, isNotNull);
      expect(ctx!.province.id, _extractionContextProvinceId);
      expect(ctx.commodityId, 'grain');
    case ResolveTileKeyExtractionContextTarget.fallbackGame:
      final game = gameForNonGpExtractionTest(provinces: [fixtures.province]);
      final ctx = resolveTileKeyExtractionContext(
        tileKey: tileKey,
        tileMapByRegion: fixtures.tileMapByRegion,
        game: game,
        logContext: 'test',
      );
      expect(ctx!.province.id, _extractionContextProvinceId);
    case ResolveTileKeyExtractionContextTarget.missingProvince:
      final ctx = resolveTileKeyExtractionContext(
        tileKey: tileKey,
        tileMapByRegion: fixtures.tileMapByRegion,
        provincesByFullId: const {},
        logContext: 'test',
      );
      expect(ctx, isNull);
  }
}

ResolveTileKeyExtractionContextScenario
resolveTileKeyExtractionContextScenario({
  required String label,
  required ResolveTileKeyExtractionContextTarget target,
  String? refs,
}) => (
  label: label,
  run: () => runResolveTileKeyExtractionContextExpectation(target),
  refs: refs,
);
