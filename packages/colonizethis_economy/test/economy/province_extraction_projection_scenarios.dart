// dart format off
// Table-driven projectProvinceExtraction leftover cases (Refs #4064, #4550).
// Lives in the economy test tree so colonizethis_economy_test_support stays
// under repo.economy_test_support_loc (≤6590).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

typedef ProvinceExtractionProjectionScenario = ({
  String label,
  ProvinceExtractionProjectionPin pin,
  String? refs,
});

enum ProvinceExtractionProjectionPin {
  draftImproveIgnored,
  ownershipChangeRefreshesDisplay,
}

List<ProvinceExtractionProjectionScenario>
provinceExtractionProjectionScenarios() => [
  (
    label:
        'negative: mid-turn draft improve intent is not applied — only Game '
        'tile state drives projection',
    pin: ProvinceExtractionProjectionPin.draftImproveIgnored,
    refs: '#4064',
  ),
  (
    label:
        'ownership change: new owner projection appears without Extraction write',
    pin: ProvinceExtractionProjectionPin.ownershipChangeRefreshesDisplay,
    refs: '#4064',
  ),
];

void runProvinceExtractionProjectionScenario(
  ProvinceExtractionProjectionScenario scenario,
) {
  switch (scenario.pin) {
    case ProvinceExtractionProjectionPin.draftImproveIgnored:
      _assertDraftImproveIgnoredProjection();
    case ProvinceExtractionProjectionPin.ownershipChangeRefreshesDisplay:
      _assertOwnershipChangeProjection();
  }
}

TileMapResult _grainStripMap() => TileMapResult(
  width: 2,
  height: 1,
  grid: const [['p1', 'p1']],
  resourceGrid: const [[Resource.grain, Resource.grain]],
);

MapTopology _topology(List<String> localIds) => MapTopology(
  nodes: [
    for (final id in localIds)
      TopologyNode(id: id, regionId: 'oldWorld', type: TopologyNodeType.province),
  ],
  edges: const [],
);

void _assertDraftImproveIgnoredProjection() {
  const tk = 'oldWorld|p1|0|0';
  const provinceId = 'oldWorld|p1';
  final map = _grainStripMap();
  final topology = _topology(const ['p1']);

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

Player _gp({required String id, required String capitalId}) => Player(
  id: id,
  displayName: id,
  isHuman: id == 'pl1',
  capitalProvinceId: capitalId,
  capitalTile: CapitalTile(regionId: 'oldWorld', provinceId: capitalId, x: 0, y: 0),
  techUnlocked: const {kTechIdMoldboardPlow: true},
);

void _assertOwnershipChangeProjection() {
  const tk = 'oldWorld|p1|0|0';
  const provinceId = 'oldWorld|p1';
  const otherProvinceId = 'oldWorld|p2';
  final map = _grainStripMap();
  final topology = _topology(const ['p1', 'p2']);
  final tileState = tileStateFromSpecs([const TileImprovementSpec(tk, 2, 4)]);

  Game gameForOwner(String p1OwnerId) {
    final p2OwnerId = p1OwnerId == 'pl1' ? 'pl2' : 'pl1';
    return gameForNonGpExtractionTest(
      id: 'g_ownership_projection',
      capitalTileGrainBonusPerTurn: 3,
      tileState: tileState,
      provinces: [
        Province(id: provinceId, regionId: 'oldWorld', ownerId: p1OwnerId, townDevelopmentLevel: 4),
        Province(id: otherProvinceId, regionId: 'oldWorld', ownerId: p2OwnerId, townDevelopmentLevel: 4),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {provinceId: [tk], otherProvinceId: <String>[]},
      },
      players: [
        _gp(id: 'pl1', capitalId: p1OwnerId == 'pl1' ? provinceId : otherProvinceId),
        _gp(id: 'pl2', capitalId: p1OwnerId == 'pl2' ? provinceId : otherProvinceId),
      ],
    );
  }

  final before = projectProvinceExtraction(
    game: gameForOwner('pl1'),
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
    game: gameForOwner('pl2'),
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
