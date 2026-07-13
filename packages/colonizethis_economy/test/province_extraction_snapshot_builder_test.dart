import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  group('computeProvinceExtractionSnapshots (Refs #4002)', () {
    test('transport limit yields effective < full with brackets', () {
      const tk = 'oldWorld|p1|0|0';
      final tileState = tileStateFromSpecs([
        const TileImprovementSpec(tk, 5, 4),
      ]);
      final game = resourceExtractorGame(
        tileState: tileState,
        townDevelopmentLevel: 4,
        capitalTileGrainBonusPerTurn: 0,
      );
      final snaps = computeProvinceExtractionSnapshots(
        game: game,
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.grain)},
        connectivityResult: connectivityFor(
          {tk},
          pathTransportCap: const {tk: 1},
          connectedByRoadRule: {tk},
        ),
        techCapForPlayer: (_) => 4,
      );
      final grain = snaps['oldWorld|p1']!.byCommodity['grain']!;
      expect(grain.effective, 1);
      expect(grain.full, 4);
      expect(grain.tileKeys, [tk]);
    });

    test('town development cap yields effective < full', () {
      const tk = 'oldWorld|p1|0|0';
      final tileState = tileStateFromSpecs([
        const TileImprovementSpec(tk, 4, 4),
      ]);
      final game = resourceExtractorGame(
        tileState: tileState,
        townDevelopmentLevel: 1,
        capitalTileGrainBonusPerTurn: 0,
      );
      final snaps = computeProvinceExtractionSnapshots(
        game: game,
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.grain)},
        connectivityResult: connectivityFor({tk}, connectedByRoadRule: {tk}),
        techCapForPlayer: (_) => 4,
      );
      final grain = snaps['oldWorld|p1']!.byCommodity['grain']!;
      expect(grain.effective, 1);
      expect(grain.full, 4);
    });

    test('disconnected improved tile contributes 0 (N)', () {
      const tk = 'oldWorld|p1|0|0';
      final tileState = tileStateFromSpecs([
        const TileImprovementSpec(tk, 3, 1),
      ]);
      final game = resourceExtractorGame(
        tileState: tileState,
        townDevelopmentLevel: 4,
        capitalTileGrainBonusPerTurn: 0,
      );
      final snaps = computeProvinceExtractionSnapshots(
        game: game,
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.grain)},
        connectivityResult: connectivityFor(const {}),
        techCapForPlayer: (_) => 4,
      );
      final grain = snaps['oldWorld|p1']!.byCommodity['grain']!;
      expect(grain.effective, 0);
      expect(grain.full, 3);
      expect(grain.tileKeys, [tk]);
    });

    test('road-rule path with no binding constraints has no brackets', () {
      const tk = 'oldWorld|p1|0|0';
      final tileState = tileStateFromSpecs([
        const TileImprovementSpec(tk, 2, 4),
      ]);
      final game = resourceExtractorGame(
        tileState: tileState,
        townDevelopmentLevel: 4,
        capitalTileGrainBonusPerTurn: 0,
      );
      final snaps = computeProvinceExtractionSnapshots(
        game: game,
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.grain)},
        connectivityResult: connectivityFor({tk}, connectedByRoadRule: {tk}),
        techCapForPlayer: (_) => 4,
      );
      final grain = snaps['oldWorld|p1']!.byCommodity['grain']!;
      expect(grain.effective, grain.full);
      expect(grain.effective, 2);
    });

    test('combined limits aggregate to a single effective (full) pair', () {
      const t0 = 'oldWorld|p1|0|0';
      const t1 = 'oldWorld|p1|1|0';
      final tileState = tileStateFromSpecs([
        const TileImprovementSpec(t0, 4, 4),
        const TileImprovementSpec(t1, 4, 4),
      ]);
      final game = resourceExtractorGame(
        tileState: tileState,
        townDevelopmentLevel: 4,
        capitalTileGrainBonusPerTurn: 0,
      );
      final map = tileMapFromGrids(
        grid: const [
          ['p1', 'p1'],
        ],
        resourceGrid: const [
          [Resource.grain, Resource.grain],
        ],
      );
      final snaps = computeProvinceExtractionSnapshots(
        game: game,
        tileMapByRegion: {'oldWorld': map},
        connectivityResult: connectivityFor(
          {t0, t1},
          pathTransportCap: const {t0: 1, t1: 2},
          connectedByRoadRule: {t0, t1},
        ),
        techCapForPlayer: (_) => 4,
      );
      final grain = snaps['oldWorld|p1']!.byCommodity['grain']!;
      expect(grain.effective, 3);
      expect(grain.full, 8);
      expect(grain.tileKeys, [t0, t1]);
    });

    test('capital grain bonus adds equal effective and full', () {
      const tk = 'oldWorld|p1|0|0';
      final tileState = tileStateFromSpecs([
        const TileImprovementSpec(tk, 1, 1),
      ]);
      final game = resourceExtractorGame(
        tileState: tileState,
        townDevelopmentLevel: 4,
        capitalTileGrainBonusPerTurn: 5,
      );
      final snaps = computeProvinceExtractionSnapshots(
        game: game,
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.grain)},
        connectivityResult: connectivityFor({tk}, connectedByRoadRule: {tk}),
        techCapForPlayer: (_) => 4,
      );
      final grain = snaps['oldWorld|p1']!.byCommodity['grain']!;
      expect(grain.effective, 6);
      expect(grain.full, 6);
    });
  });

  group('provinceImprovableResourceTileCounts (Refs #4002)', () {
    test('counts improvable tiles including partially improved below cap', () {
      final map = tileMapFromGrids(
        grid: const [
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
        ],
        resourceGrid: const [
          [Resource.grain, Resource.grain, Resource.grain],
          [Resource.timber, Resource.timber, null],
        ],
      );
      final keys = <String>[
        for (var y = 0; y < 2; y++)
          for (var x = 0; x < 3; x++)
            if (map.resourceAt(x, y) != null) 'oldWorld|p1|$x|$y',
      ];
      // One grain already extracting (level 1) but still below tech/terrain cap 4.
      final tileState = tileStateFromSpecs([
        const TileImprovementSpec('oldWorld|p1|0|0', 1, 0),
      ]);
      final game = spainExtractorGame(
        tileState: tileState,
        oldWorld: RegionData(
          provinces: [owP1Province(townDevelopmentLevel: 4)],
        ),
        tileKeysByRegionAndProvince: {
          'oldWorld': {'p1': keys},
        },
      );
      final counts = provinceImprovableResourceTileCounts(
        game: game,
        provinceId: 'oldWorld|p1',
        ownerId: 'pl1',
        tileMapByRegion: {'oldWorld': map},
        ownerTechUnlocked: const {'moldboard_plow': true, 'circular_saw': true},
      );
      expect(counts['grain']?.count, 3);
      expect(counts['timber']?.count, 2);
      expect(counts.keys.toList(), ['grain', 'timber']);
    });

    test('excludes unprospected mineral tiles', () {
      const tk = 'oldWorld|p1|0|0';
      final game = resourceExtractorGame(
        tileState: const TileMapState(),
        playerProspectedTiles: const {},
      );
      final counts = provinceImprovableResourceTileCounts(
        game: game,
        provinceId: 'oldWorld|p1',
        ownerId: 'pl1',
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.iron)},
      );
      expect(counts.containsKey('iron'), isFalse);

      final prospectedGame = resourceExtractorGame(
        tileState: const TileMapState(),
        playerProspectedTiles: {
          'pl1': {tk},
        },
      );
      final prospectedCounts = provinceImprovableResourceTileCounts(
        game: prospectedGame,
        provinceId: 'oldWorld|p1',
        ownerId: 'pl1',
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.iron)},
      );
      expect(prospectedCounts['iron']?.count, 1);
      expect(prospectedCounts['iron']?.tileKeys, [tk]);
    });

    test('empty when no improvable tiles', () {
      const tk = 'oldWorld|p1|0|0';
      final tileState = tileStateFromSpecs([
        const TileImprovementSpec(tk, 1, 0),
      ]);
      final game = resourceExtractorGame(tileState: tileState);
      final counts = provinceImprovableResourceTileCounts(
        game: game,
        provinceId: 'oldWorld|p1',
        ownerId: 'pl1',
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.grain)},
      );
      // Default grain cap is 1; improvement 1 => not improvable.
      expect(counts, isEmpty);
    });
  });
}
