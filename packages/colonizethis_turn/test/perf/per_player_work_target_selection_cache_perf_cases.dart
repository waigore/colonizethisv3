// Fixtures for per_player_work_target_selection_cache_perf_test
// (Refs #4740 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

const workTargetCachePerfPlayerId = 'gp1';
const workTargetCachePerfOw = 'oldWorld';

Map<String, String> workTargetCachePerfFoggedVisibility(
  Iterable<String> tileKeys,
) => {
  for (final tk in tileKeys) tk: 'fogged',
};

List<String> workTargetCachePerfTileKeys(String provinceId) => [
  '$provinceId|0|0',
  '$provinceId|0|1',
  '$provinceId|0|2',
];

Game workTargetCachePerfExplorerStressGame(int explorerCount) {
  assert(explorerCount >= 1 && explorerCount <= 24);
  const p1 = '$workTargetCachePerfOw|p1';
  const p2 = '$workTargetCachePerfOw|p2';
  final provinces = const [
    Province(
      id: p1,
      regionId: workTargetCachePerfOw,
      ownerId: workTargetCachePerfPlayerId,
    ),
    Province(
      id: p2,
      regionId: workTargetCachePerfOw,
      ownerId: workTargetCachePerfPlayerId,
    ),
  ];
  final units = <Unit>[];
  for (var i = 0; i < explorerCount; i++) {
    final provinceId = i.isEven ? p1 : p2;
    final tiles = workTargetCachePerfTileKeys(provinceId);
    final tileKey = tiles[i % tiles.length];
    units.add(
      Unit(
        id: 'explorer-$i',
        type: kUnitTypeExplorer,
        ownerId: workTargetCachePerfPlayerId,
        locationProvinceId: provinceId,
        tileKey: tileKey,
      ),
    );
  }
  final allTileKeys = [
    ...workTargetCachePerfTileKeys(p1),
    ...workTargetCachePerfTileKeys(p2),
  ];
  return TestFixtures.minimalGame(
    id: 'g-perf-explorers-$explorerCount',
    players: const [
      Player(
        id: workTargetCachePerfPlayerId,
        displayName: 'GP',
        isHuman: true,
      ),
    ],
    oldWorld: RegionData(provinces: provinces, units: units),
    tileKeysByRegionAndProvince: {
      workTargetCachePerfOw: {
        p1: workTargetCachePerfTileKeys(p1),
        p2: workTargetCachePerfTileKeys(p2),
      },
    },
    playerVisibilityByTile: {
      workTargetCachePerfPlayerId: workTargetCachePerfFoggedVisibility(
        allTileKeys,
      ),
    },
  );
}

int workTargetCachePerfMedianMicros(List<int> samples) {
  final sorted = [...samples]..sort();
  return sorted[sorted.length ~/ 2];
}

WorkTargetSelectionSnapshot workTargetCachePerfSnapshot(Game game) {
  const topology = MapTopology(nodes: [], edges: []);
  final view = buildPlayerView(game, topology, workTargetCachePerfPlayerId);
  return WorkTargetSelectionSnapshot(
    game: game,
    playerId: workTargetCachePerfPlayerId,
    playerView: view,
    topology: topology,
    currentOrders: const Orders(),
    tileMapByRegion: null,
  );
}

/// Mirrors default-strategy keys in [PerPlayerWorkTargetSelectionCache].
const workTargetCachePerfDefaultTargets = <String>[
  kWorkTargetExplore,
  kWorkTargetCounterSpy,
  kWorkTargetPurchaseLand,
  kWorkTargetProspect,
  kWorkTargetBuildImprovement,
  kWorkTargetUpgradeTown,
  kWorkTargetBuildRoad,
  kWorkTargetBuildPort,
  kWorkTargetBuildFort,
  kWorkTargetBuildRail,
];

void expectWorkTargetCachesEqualForAllTargets(
  PerPlayerWorkTargetSelectionCache a,
  PerPlayerWorkTargetSelectionCache b,
) {
  for (final target in workTargetCachePerfDefaultTargets) {
    expect(
      a.sorted(workTargetCachePerfPlayerId, target),
      b.sorted(workTargetCachePerfPlayerId, target),
      reason: 'workTarget=$target',
    );
  }
}

int workTargetCachePerfMedianRefreshMicros({
  required PerPlayerWorkTargetSelectionCache cache,
  required Game game,
  required int warmup,
  required int samples,
}) {
  final snapshot = workTargetCachePerfSnapshot(game);
  for (var i = 0; i < warmup; i++) {
    cache.refresh(snapshot);
  }
  final timings = <int>[];
  for (var i = 0; i < samples; i++) {
    final sw = Stopwatch()..start();
    cache.refresh(snapshot);
    sw.stop();
    timings.add(sw.elapsedMicroseconds);
  }
  return workTargetCachePerfMedianMicros(timings);
}
