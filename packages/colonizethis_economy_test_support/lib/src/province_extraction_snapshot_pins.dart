// dart format off
// Compact province Extraction/Available assertions (Refs #4002, #4014, #4410).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'extraction_fixture_support.dart';
import 'province_extraction_projection_scenarios.dart';
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

void assertProvinceExtractionProjection(
  ProvinceExtractionProjectionScenario scenario,
) {
  switch (scenario.pin) {
    case ProvinceExtractionProjectionPin.draftImproveIgnored:
      _assertDraftImproveIgnoredProjection();
    case ProvinceExtractionProjectionPin.ownershipChangeRefreshesDisplay:
      _assertOwnershipChangeProjection();
  }
}

void _assertDraftImproveIgnoredProjection() {
  const tk = 'oldWorld|p1|0|0';
  const provinceId = 'oldWorld|p1';
  final map = TileMapResult(
    width: 2,
    height: 1,
    grid: const [
      ['p1', 'p1'],
    ],
    resourceGrid: const [
      [Resource.grain, Resource.grain],
    ],
  );
  final topology = const MapTopology(
    nodes: [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [],
  );

  final unresolvedGame = resourceExtractorGame(
    tileState: tileStateFromSpecs([const TileImprovementSpec(tk, 1, 4)]),
  );
  final unresolved = projectProvinceExtraction(
    game: unresolvedGame,
    tileMapByRegion: {'oldWorld': map},
    topology: topology,
    provinceId: provinceId,
    techCapForPlayer: (_) => 4,
  );
  expect(unresolved, isNotNull);
  final unresolvedGrain = unresolved!.byCommodity['grain']!;
  expect(unresolvedGrain.full, 1);

  final again = projectProvinceExtraction(
    game: unresolvedGame,
    tileMapByRegion: {'oldWorld': map},
    topology: topology,
    provinceId: provinceId,
    techCapForPlayer: (_) => 4,
  );
  expect(again, unresolved);

  final resolvedGame = resourceExtractorGame(
    tileState: tileStateFromSpecs([const TileImprovementSpec(tk, 2, 4)]),
  );
  final resolved = projectProvinceExtraction(
    game: resolvedGame,
    tileMapByRegion: {'oldWorld': map},
    topology: topology,
    provinceId: provinceId,
    techCapForPlayer: (_) => 4,
  );
  expect(resolved, isNotNull);
  expect(resolved!.byCommodity['grain']!.full, 2);
  expect(resolved.byCommodity['grain']!.full, isNot(unresolvedGrain.full));
}

void _assertOwnershipChangeProjection() {
  const tk = 'oldWorld|p1|0|0';
  const provinceId = 'oldWorld|p1';
  const otherProvinceId = 'oldWorld|p2';
  final map = TileMapResult(
    width: 2,
    height: 1,
    grid: const [
      ['p1', 'p1'],
    ],
    resourceGrid: const [
      [Resource.grain, Resource.grain],
    ],
  );
  final topology = const MapTopology(
    nodes: [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [],
  );
  final tileState = tileStateFromSpecs([
    const TileImprovementSpec(tk, 2, 4),
  ]);

  Player gp({required String id, required String capitalId}) {
    return Player(
      id: id,
      displayName: id,
      isHuman: id == 'pl1',
      capitalProvinceId: capitalId,
      capitalTile: CapitalTile(
        regionId: 'oldWorld',
        provinceId: capitalId,
        x: 0,
        y: 0,
      ),
      techUnlocked: const {kTechIdMoldboardPlow: true},
    );
  }

  Game gameWithOwner(String p1OwnerId) {
    final p2OwnerId = p1OwnerId == 'pl1' ? 'pl2' : 'pl1';
    return gameForNonGpExtractionTest(
      id: 'g_ownership_projection',
      capitalTileGrainBonusPerTurn: 3,
      tileState: tileState,
      provinces: [
        Province(
          id: provinceId,
          regionId: 'oldWorld',
          ownerId: p1OwnerId,
          townDevelopmentLevel: 4,
        ),
        Province(
          id: otherProvinceId,
          regionId: 'oldWorld',
          ownerId: p2OwnerId,
          townDevelopmentLevel: 4,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          provinceId: [tk],
          otherProvinceId: <String>[],
        },
      },
      players: [
        gp(
          id: 'pl1',
          capitalId: p1OwnerId == 'pl1' ? provinceId : otherProvinceId,
        ),
        gp(
          id: 'pl2',
          capitalId: p1OwnerId == 'pl2' ? provinceId : otherProvinceId,
        ),
      ],
    );
  }

  final before = projectProvinceExtraction(
    game: gameWithOwner('pl1'),
    tileMapByRegion: {'oldWorld': map},
    topology: topology,
    provinceId: provinceId,
    techCapForPlayer: (_) => 4,
  );
  expect(before, isNotNull);
  expect(before!.ownerId, 'pl1');
  expect(before.byCommodity['grain']!.full, greaterThan(0));
  expect(before.capitalGrainBonus, 3);

  final after = projectProvinceExtraction(
    game: gameWithOwner('pl2'),
    tileMapByRegion: {'oldWorld': map},
    topology: topology,
    provinceId: provinceId,
    techCapForPlayer: (_) => 4,
  );
  expect(after, isNotNull);
  expect(after!.ownerId, 'pl2');
  expect(after.byCommodity['grain']!.full, greaterThan(0));
  expect(after.capitalGrainBonus, 3);
  expect(after.ownerId, isNot(before.ownerId));
}
// dart format on
