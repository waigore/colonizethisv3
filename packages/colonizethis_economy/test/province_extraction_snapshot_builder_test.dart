import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

typedef _SnapScenario = ({
  String label,
  List<TileImprovementSpec> specs,
  Map<String, ConnectivityResult> connectivity,
  int townDevelopmentLevel,
  int capitalBonus,
  TileMapResult? map,
  int expectEffective,
  int expectFull,
  List<String>? expectTileKeys,
});

typedef _AvailableScenario = ({String label, void Function() run});

_SnapScenario _snap({
  required String label,
  required List<TileImprovementSpec> specs,
  required Map<String, ConnectivityResult> connectivity,
  required int expectEffective,
  required int expectFull,
  int townDevelopmentLevel = 4,
  int capitalBonus = 0,
  TileMapResult? map,
  List<String>? expectTileKeys,
}) => (
  label: label,
  specs: specs,
  connectivity: connectivity,
  townDevelopmentLevel: townDevelopmentLevel,
  capitalBonus: capitalBonus,
  map: map,
  expectEffective: expectEffective,
  expectFull: expectFull,
  expectTileKeys: expectTileKeys,
);

void main() {
  group('computeProvinceExtractionSnapshots (Refs #4002)', () {
    runLabeledScenarios(_snapshotScenarios(), (scenario) {
      final tileState = tileStateFromSpecs(scenario.specs);
      final game = resourceExtractorGame(
        tileState: tileState,
        townDevelopmentLevel: scenario.townDevelopmentLevel,
        capitalTileGrainBonusPerTurn: scenario.capitalBonus,
      );
      final snaps = computeProvinceExtractionSnapshots(
        game: game,
        tileMapByRegion: {
          'oldWorld': scenario.map ?? singleTileMap(Resource.grain),
        },
        connectivityResult: scenario.connectivity,
        techCapForPlayer: (_) => 4,
      );
      final grain = snaps['oldWorld|p1']!.byCommodity['grain']!;
      expect(grain.effective, scenario.expectEffective);
      expect(grain.full, scenario.expectFull);
      if (scenario.expectTileKeys != null) {
        expect(grain.tileKeys, scenario.expectTileKeys);
      }
    }, labelOf: (s) => s.label);
  });

  group('provinceImprovableResourceTileCounts (Refs #4002)', () {
    runLabeledScenarios(_availableScenarios(), (scenario) {
      scenario.run();
    }, labelOf: (s) => s.label);
  });
}

List<_SnapScenario> _snapshotScenarios() {
  const tk = 'oldWorld|p1|0|0';
  const t0 = 'oldWorld|p1|0|0';
  const t1 = 'oldWorld|p1|1|0';
  final twoTileMap = tileMapFromGrids(
    grid: const [
      ['p1', 'p1'],
    ],
    resourceGrid: const [
      [Resource.grain, Resource.grain],
    ],
  );
  return [
    _snap(
      label: 'transport limit yields effective < full with brackets',
      specs: [const TileImprovementSpec(tk, 5, 4)],
      connectivity: connectivityFor(
        {tk},
        pathTransportCap: const {tk: 1},
        connectedByRoadRule: {tk},
      ),
      expectEffective: 1,
      expectFull: 4,
      expectTileKeys: [tk],
    ),
    _snap(
      label: 'town development cap yields effective < full',
      specs: [const TileImprovementSpec(tk, 4, 4)],
      connectivity: connectivityFor({tk}, connectedByRoadRule: {tk}),
      townDevelopmentLevel: 1,
      expectEffective: 1,
      expectFull: 4,
    ),
    _snap(
      label: 'disconnected improved tile contributes 0 (N)',
      specs: [const TileImprovementSpec(tk, 3, 1)],
      connectivity: connectivityFor(const {}),
      expectEffective: 0,
      expectFull: 3,
      expectTileKeys: [tk],
    ),
    _snap(
      label: 'road-rule path with no binding constraints has no brackets',
      specs: [const TileImprovementSpec(tk, 2, 4)],
      connectivity: connectivityFor({tk}, connectedByRoadRule: {tk}),
      expectEffective: 2,
      expectFull: 2,
    ),
    _snap(
      label: 'combined limits aggregate to a single effective (full) pair',
      specs: [
        const TileImprovementSpec(t0, 4, 4),
        const TileImprovementSpec(t1, 4, 4),
      ],
      connectivity: connectivityFor(
        {t0, t1},
        pathTransportCap: const {t0: 1, t1: 2},
        connectedByRoadRule: {t0, t1},
      ),
      map: twoTileMap,
      expectEffective: 3,
      expectFull: 8,
      expectTileKeys: [t0, t1],
    ),
    _snap(
      label: 'capital grain bonus adds equal effective and full',
      specs: [const TileImprovementSpec(tk, 1, 1)],
      connectivity: connectivityFor({tk}, connectedByRoadRule: {tk}),
      capitalBonus: 5,
      expectEffective: 6,
      expectFull: 6,
    ),
  ];
}

List<_AvailableScenario> _availableScenarios() => [
  (
    label: 'counts improvable tiles including partially improved below cap',
    run: () {
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
        ownerTechUnlocked: const {
          kTechIdMoldboardPlow: true,
          kTechIdCircularSaw: true,
        },
      );
      expect(counts['grain']?.count, 3);
      expect(counts['timber']?.count, 2);
      expect(counts.keys.toList(), ['grain', 'timber']);
    },
  ),
  (
    label: 'excludes unprospected mineral tiles',
    run: () {
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
    },
  ),
  (
    label: 'empty when no improvable tiles',
    run: () {
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
      expect(counts, isEmpty);
    },
  ),
];
