// dart format off
// Compact province Extraction/Available assertions (Refs #4002, #4014, #4410).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'extraction_fixture_support.dart';
import 'province_extraction_snapshot_scenarios.dart';

void assertProvinceExtractionSnapshot(ProvinceExtractionSnapshotScenario scenario) {
  final tileState = tileStateFromSpecs(scenario.specs);
  final game = resourceExtractorGame(
    tileState: tileState,
    townDevelopmentLevel: scenario.townDevelopmentLevel,
    capitalTileGrainBonusPerTurn: scenario.capitalBonus,
  );
  final snaps = computeProvinceExtractionSnapshots(
    game: game,
    tileMapByRegion: {'oldWorld': scenario.map ?? singleTileMap(Resource.grain)},
    connectivityResult: scenario.connectivity,
    techCapForPlayer: (_) => 4,
  );
  final provinceSnap = snaps['oldWorld|p1']!;
  final grain = provinceSnap.byCommodity['grain']!;
  expect(grain.effective, scenario.expectEffective);
  expect(grain.full, scenario.expectFull);
  if (scenario.expectTileKeys != null) {
    expect(grain.tileKeys, scenario.expectTileKeys);
  }
  expect(provinceSnap.capitalGrainBonus, scenario.capitalBonus);
}

/// Pins for Available/improvable-count rows (no local `void Function() run`).
enum ProvinceImprovableCountsPin {
  partiallyImprovedBelowCap,
  excludesUnprospectedMineral,
  emptyWhenFullyImproved,
}

void assertProvinceImprovableCounts(ProvinceImprovableCountsPin pin) {
  switch (pin) {
    case ProvinceImprovableCountsPin.partiallyImprovedBelowCap:
      final map = tileMapFromGrids(
        grid: const [['p1', 'p1', 'p1'], ['p1', 'p1', 'p1']],
        resourceGrid: const [[Resource.grain, Resource.grain, Resource.grain], [Resource.timber, Resource.timber, null]],
      );
      final keys = <String>[
        for (var y = 0; y < 2; y++)
          for (var x = 0; x < 3; x++)
            if (map.resourceAt(x, y) != null) 'oldWorld|p1|$x|$y',
      ];
      final game = spainExtractorGame(
        tileState: tileStateFromSpecs([const TileImprovementSpec('oldWorld|p1|0|0', 1, 0)]),
        oldWorld: RegionData(provinces: [owP1Province(townDevelopmentLevel: 4)]),
        tileKeysByRegionAndProvince: {'oldWorld': {'p1': keys}},
      );
      final counts = provinceImprovableResourceTileCounts(
        game: game,
        provinceId: 'oldWorld|p1',
        ownerId: 'pl1',
        tileMapByRegion: {'oldWorld': map},
        ownerTechUnlocked: const {kTechIdMoldboardPlow: true, kTechIdCircularSaw: true},
      );
      expect(counts['grain']?.count, 3);
      expect(counts['timber']?.count, 2);
      expect(counts.keys.toList(), ['grain', 'timber']);
    case ProvinceImprovableCountsPin.excludesUnprospectedMineral:
      const tk = kOwP1Tile00;
      final counts = provinceImprovableResourceTileCounts(
        game: resourceExtractorGame(tileState: const TileMapState(), playerProspectedTiles: const {}),
        provinceId: 'oldWorld|p1',
        ownerId: 'pl1',
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.iron)},
      );
      expect(counts.containsKey('iron'), isFalse);
      final prospectedCounts = provinceImprovableResourceTileCounts(
        game: resourceExtractorGame(tileState: const TileMapState(), playerProspectedTiles: {'pl1': {tk}}),
        provinceId: 'oldWorld|p1',
        ownerId: 'pl1',
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.iron)},
      );
      expect(prospectedCounts['iron']?.count, 1);
      expect(prospectedCounts['iron']?.tileKeys, [tk]);
    case ProvinceImprovableCountsPin.emptyWhenFullyImproved:
      const tk = kOwP1Tile00;
      final counts = provinceImprovableResourceTileCounts(
        game: resourceExtractorGame(tileState: tileStateFromSpecs([const TileImprovementSpec(tk, 1, 0)])),
        provinceId: 'oldWorld|p1',
        ownerId: 'pl1',
        tileMapByRegion: {'oldWorld': singleTileMap(Resource.grain)},
      );
      expect(counts, isEmpty);
  }
}
// dart format on
