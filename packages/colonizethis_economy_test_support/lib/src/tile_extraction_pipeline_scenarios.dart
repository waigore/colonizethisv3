// Table-driven tile extraction pipeline scenarios (Refs #3939 phase 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'extraction_fixture_support.dart';
import 'scenario_runner.dart';

/// One row in [resolveTileKeyResourceContextScenarios].
class ResolveTileKeyResourceContextScenario implements RefsScenario {
  const ResolveTileKeyResourceContextScenario({
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

void runResolveTileKeyResourceContextScenario(
  ResolveTileKeyResourceContextScenario scenario,
) {
  scenario.run();
}

TileMapResult _tileMapForResourceContext() {
  return tileMapAllInProvinceForNonGpExtractionTest(
    provinceId: 'oldWorld|p1',
    width: 2,
    height: 1,
    resources: [
      [Resource.grain, Resource.iron],
    ],
  );
}

/// Canonical scenarios for [resolveTileKeyResourceContext].
List<ResolveTileKeyResourceContextScenario>
    resolveTileKeyResourceContextScenarios() {
  final tileMap = _tileMapForResourceContext();
  final tileMapByRegion = {'oldWorld': tileMap};

  return [
    ResolveTileKeyResourceContextScenario(
      label: 'returns resource context for valid tile key',
      run: () {
        final ctx = resolveTileKeyResourceContext(
          tileKey: 'oldWorld|p1|0|0',
          tileMapByRegion: tileMapByRegion,
        );

        expect(ctx, isNotNull);
        expect(ctx!.commodityId, CommodityCatalog.grain.id);
        expect(ctx.provinceId, 'oldWorld|p1');
        expect(ctx.resource, Resource.grain);
      },
    ),
    ResolveTileKeyResourceContextScenario(
      label: 'maps commodity id via resource.name consistently',
      run: () {
        final ctx = resolveTileKeyResourceContext(
          tileKey: 'oldWorld|p1|1|0',
          tileMapByRegion: tileMapByRegion,
        );

        expect(ctx!.commodityId, Resource.iron.name);
        expect(ctx.commodityId, CommodityCatalog.iron.id);
      },
    ),
    ResolveTileKeyResourceContextScenario(
      label: 'returns null for invalid or out-of-range keys',
      run: () {
        expect(
          resolveTileKeyResourceContext(
            tileKey: 'bad-key',
            tileMapByRegion: tileMapByRegion,
          ),
          isNull,
        );
        expect(
          resolveTileKeyResourceContext(
            tileKey: 'oldWorld|p1|-1|0',
            tileMapByRegion: tileMapByRegion,
          ),
          isNull,
        );
        expect(
          resolveTileKeyResourceContext(
            tileKey: 'newWorld|p1|0|0',
            tileMapByRegion: tileMapByRegion,
          ),
          isNull,
        );
      },
    ),
  ];
}

/// One row in [resolveTileKeyExtractionContextScenarios].
class ResolveTileKeyExtractionContextScenario implements RefsScenario {
  const ResolveTileKeyExtractionContextScenario({
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

void runResolveTileKeyExtractionContextScenario(
  ResolveTileKeyExtractionContextScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [resolveTileKeyExtractionContext].
List<ResolveTileKeyExtractionContextScenario>
    resolveTileKeyExtractionContextScenarios() {
  const provinceId = 'oldWorld|p1';
  final province = capitalProvinceForNonGpExtractionTest(
    provinceId: provinceId,
  );
  final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
    provinceId: provinceId,
    width: 1,
    height: 1,
    resources: [
      [Resource.grain],
    ],
  );
  final tileMapByRegion = {'oldWorld': tileMap};

  return [
    ResolveTileKeyExtractionContextScenario(
      label: 'resolves province from provincesByFullId index',
      run: () {
        final ctx = resolveTileKeyExtractionContext(
          tileKey: '$provinceId|0|0',
          tileMapByRegion: tileMapByRegion,
          provincesByFullId: {provinceId: province},
          logContext: 'test',
        );

        expect(ctx, isNotNull);
        expect(ctx!.province.id, provinceId);
        expect(ctx.commodityId, CommodityCatalog.grain.id);
      },
    ),
    ResolveTileKeyExtractionContextScenario(
      label: 'falls back to game.worldState when index misses',
      run: () {
        final game = gameForNonGpExtractionTest(provinces: [province]);
        final ctx = resolveTileKeyExtractionContext(
          tileKey: '$provinceId|0|0',
          tileMapByRegion: tileMapByRegion,
          game: game,
          logContext: 'test',
        );

        expect(ctx!.province.id, provinceId);
      },
    ),
    ResolveTileKeyExtractionContextScenario(
      label: 'returns null when province row is missing',
      run: () {
        final ctx = resolveTileKeyExtractionContext(
          tileKey: '$provinceId|0|0',
          tileMapByRegion: tileMapByRegion,
          provincesByFullId: const {},
          logContext: 'test',
        );

        expect(ctx, isNull);
      },
    ),
  ];
}
