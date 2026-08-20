// dart format off
// Table-driven province Extraction/Available snapshot scenarios (Refs #4002, #4014).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'extraction_fixture_support.dart';
import 'province_extraction_snapshot_pins.dart';

/// One row for `computeProvinceExtractionSnapshots` scenario tables.
typedef ProvinceExtractionSnapshotScenario = ({
  String label,
  List<TileImprovementSpec> specs,
  Map<String, ConnectivityResult> connectivity,
  int townDevelopmentLevel,
  int capitalBonus,
  TileMapResult? map,
  int expectEffective,
  int expectFull,
  List<String>? expectTileKeys,
  String? refs,
});

ProvinceExtractionSnapshotScenario provinceSnapScenario({
  required String label,
  required List<TileImprovementSpec> specs,
  required Map<String, ConnectivityResult> connectivity,
  required int expectEffective,
  required int expectFull,
  int townDevelopmentLevel = 4,
  int capitalBonus = 0,
  TileMapResult? map,
  List<String>? expectTileKeys,
  String? refs = '#4002',
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
  refs: refs,
);

/// Canonical GP Extraction snapshot pins (transport / town / disconnect / capital).
List<ProvinceExtractionSnapshotScenario> provinceExtractionSnapshotScenarios() {
  const tk = kOwP1Tile00;
  const t0 = 'oldWorld|p1|0|0';
  const t1 = 'oldWorld|p1|1|0';
  final twoTileMap = tileMapFromGrids(
    grid: const [['p1', 'p1']],
    resourceGrid: const [[Resource.grain, Resource.grain]],
  );
  return [
    provinceSnapScenario(
      label: 'transport limit yields effective < full with brackets',
      specs: [const TileImprovementSpec(tk, 5, 4)],
      connectivity: connectivityFor({tk}, pathTransportCap: const {tk: 1}, connectedByRoadRule: {tk}),
      expectEffective: 1,
      expectFull: 4,
      expectTileKeys: [tk],
    ),
    provinceSnapScenario(
      label: 'town development cap yields effective < full',
      specs: [const TileImprovementSpec(tk, 4, 4)],
      connectivity: connectivityFor({tk}, connectedByRoadRule: {tk}),
      townDevelopmentLevel: 1,
      expectEffective: 1,
      expectFull: 4,
    ),
    provinceSnapScenario(
      label: 'disconnected improved tile contributes 0 (N)',
      specs: [const TileImprovementSpec(tk, 3, 1)],
      connectivity: connectivityFor(const {}),
      expectEffective: 0,
      expectFull: 3,
      expectTileKeys: [tk],
    ),
    provinceSnapScenario(
      label: 'road-rule path with no binding constraints has no brackets',
      specs: [const TileImprovementSpec(tk, 2, 4)],
      connectivity: connectivityFor({tk}, connectedByRoadRule: {tk}),
      expectEffective: 2,
      expectFull: 2,
    ),
    provinceSnapScenario(
      label: 'combined limits aggregate to a single effective (full) pair',
      specs: [const TileImprovementSpec(t0, 4, 4), const TileImprovementSpec(t1, 4, 4)],
      connectivity: connectivityFor({t0, t1}, pathTransportCap: const {t0: 1, t1: 2}, connectedByRoadRule: {t0, t1}),
      map: twoTileMap,
      expectEffective: 3,
      expectFull: 8,
      expectTileKeys: [t0, t1],
    ),
    provinceSnapScenario(
      label: 'capital grain bonus adds equal effective and full',
      specs: [const TileImprovementSpec(tk, 1, 1)],
      connectivity: connectivityFor({tk}, connectedByRoadRule: {tk}),
      capitalBonus: 5,
      expectEffective: 6,
      expectFull: 6,
    ),
    provinceSnapScenario(
      label:
          'negative: out-of-bounds improvement keys do not throw during snapshot build',
      specs: [
        const TileImprovementSpec('oldWorld|p1|0|0', 2, 1),
        const TileImprovementSpec('oldWorld|p1|0|1', 2, 1),
      ],
      connectivity: connectivityFor(
        {'oldWorld|p1|0|0'},
        pathTransportCap: const {'oldWorld|p1|0|0': 4},
      ),
      map: tileMapFromGrids(
        grid: const [['p1', 'p1']],
        resourceGrid: const [[Resource.grain, Resource.grain]],
      ),
      expectEffective: 2,
      expectFull: 2,
      expectTileKeys: ['oldWorld|p1|0|0'],
      refs: '#4550',
    ),
  ];
}

/// One row for `provinceImprovableResourceTileCounts` scenario tables.
typedef ProvinceImprovableCountsScenario = ({
  String label,
  ProvinceImprovableCountsPin pin,
  String? refs,
});

ProvinceImprovableCountsScenario provinceImprovableCountsScenario({
  required String label,
  required ProvinceImprovableCountsPin pin,
  String? refs = '#4002',
}) => (label: label, pin: pin, refs: refs);

List<ProvinceImprovableCountsScenario> provinceImprovableCountsScenarios() => [
  provinceImprovableCountsScenario(
    label: 'counts improvable tiles including partially improved below cap',
    pin: ProvinceImprovableCountsPin.partiallyImprovedBelowCap,
  ),
  provinceImprovableCountsScenario(
    label: 'excludes unprospected mineral tiles',
    pin: ProvinceImprovableCountsPin.excludesUnprospectedMineral,
  ),
  provinceImprovableCountsScenario(
    label: 'empty when no improvable tiles',
    pin: ProvinceImprovableCountsPin.emptyWhenFullyImproved,
  ),
];
// dart format on
