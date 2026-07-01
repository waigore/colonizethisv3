import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

const _playerId = 'gp1';
const _ow = 'oldWorld';

Map<String, String> _foggedVisibilityForTiles(Iterable<String> tileKeys) => {
  for (final tk in tileKeys) tk: 'fogged',
};

List<String> _tileKeysForProvince(String provinceId) => [
  '$provinceId|0|0',
  '$provinceId|0|1',
  '$provinceId|0|2',
];

Game _explorerStressGame(int explorerCount) {
  assert(explorerCount >= 1 && explorerCount <= 24);
  const p1 = '$_ow|p1';
  const p2 = '$_ow|p2';
  final provinces = const [
    Province(id: p1, regionId: _ow, ownerId: _playerId),
    Province(id: p2, regionId: _ow, ownerId: _playerId),
  ];
  final units = <Unit>[];
  for (var i = 0; i < explorerCount; i++) {
    final provinceId = i.isEven ? p1 : p2;
    final tiles = _tileKeysForProvince(provinceId);
    final tileKey = tiles[i % tiles.length];
    units.add(
      Unit(
        id: 'explorer-$i',
        type: kUnitTypeExplorer,
        ownerId: _playerId,
        locationProvinceId: provinceId,
        tileKey: tileKey,
      ),
    );
  }
  final allTileKeys = [..._tileKeysForProvince(p1), ..._tileKeysForProvince(p2)];
  return TestFixtures.minimalGame(
    id: 'g-perf-explorers-$explorerCount',
    players: const [
      Player(id: _playerId, displayName: 'GP', isHuman: true),
    ],
    oldWorld: RegionData(provinces: provinces, units: units),
    tileKeysByRegionAndProvince: {
      _ow: {
        p1: _tileKeysForProvince(p1),
        p2: _tileKeysForProvince(p2),
      },
    },
    playerVisibilityByTile: {
      _playerId: _foggedVisibilityForTiles(allTileKeys),
    },
  );
}

int _medianMicros(List<int> samples) {
  final sorted = [...samples]..sort();
  return sorted[sorted.length ~/ 2];
}

WorkTargetSelectionSnapshot _snapshot(Game game) {
  const topology = MapTopology(nodes: [], edges: []);
  final view = buildPlayerView(game, topology, _playerId);
  return WorkTargetSelectionSnapshot(
    game: game,
    playerId: _playerId,
    playerView: view,
    topology: topology,
    currentOrders: const Orders(),
    tileMapByRegion: null,
  );
}

/// Mirrors default-strategy keys in [PerPlayerWorkTargetSelectionCache].
const _defaultWorkTargets = <String>[
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

void _expectCachesEqualForAllTargets(
  PerPlayerWorkTargetSelectionCache a,
  PerPlayerWorkTargetSelectionCache b,
) {
  for (final target in _defaultWorkTargets) {
    expect(
      a.sorted(_playerId, target),
      b.sorted(_playerId, target),
      reason: 'workTarget=$target',
    );
  }
}

int _medianRefreshMicros({
  required PerPlayerWorkTargetSelectionCache cache,
  required Game game,
  required int warmup,
  required int samples,
}) {
  final snapshot = _snapshot(game);
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
  return _medianMicros(timings);
}

void main() {
  suppressLogsForTests();

  group('PerPlayerWorkTargetSelectionCache perf (Refs #2394)', () {
    test(
      'default-strategies refresh stays within a generous smoke ceiling',
      () {
        final game = _explorerStressGame(4);
        final cache = PerPlayerWorkTargetSelectionCache();
        const ceilingMicros = 8 * 1000 * 1000;
        final median = _medianRefreshMicros(
          cache: cache,
          game: game,
          warmup: 2,
          samples: 5,
        );
        expect(
          median,
          lessThan(ceilingMicros),
          reason:
              'median refresh=$medianµs should stay below ${ceilingMicros}µs '
              '(smoke guard for catastrophic regression; Refs #2394)',
        );
      },
    );

    test(
      'refresh with snapshot.sharedCandidateValidator matches implicit build',
      () {
        final game = _explorerStressGame(6);
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _playerId);
        final base = WorkTargetSelectionSnapshot(
          game: game,
          playerId: _playerId,
          playerView: view,
          topology: topology,
          currentOrders: const Orders(),
          tileMapByRegion: null,
        );
        final explicitShared = buildIncrementalCandidateValidator(
          game: base.game,
          topology: base.topology,
          playerId: base.playerId,
          baseOrders: base.currentOrders,
          tileMapByRegion: base.tileMapByRegion,
          resolution: orderResolutionContextFromView(
            base.playerView,
            base.game,
          ),
        );
        final withShared = WorkTargetSelectionSnapshot(
          game: base.game,
          playerId: base.playerId,
          playerView: base.playerView,
          topology: base.topology,
          currentOrders: base.currentOrders,
          tileMapByRegion: base.tileMapByRegion,
          sharedCandidateValidator: explicitShared,
        );

        final implicitCache = PerPlayerWorkTargetSelectionCache();
        final explicitCache = PerPlayerWorkTargetSelectionCache();
        implicitCache.refresh(base);
        explicitCache.refresh(withShared);
        _expectCachesEqualForAllTargets(implicitCache, explicitCache);
      },
    );

    test(
      'default-strategies refresh cost scales roughly linearly with explorer count',
      () {
        final cache = PerPlayerWorkTargetSelectionCache();
        const warmup = 2;
        const samples = 5;
        final small = _medianRefreshMicros(
          cache: cache,
          game: _explorerStressGame(2),
          warmup: warmup,
          samples: samples,
        );
        final large = _medianRefreshMicros(
          cache: cache,
          game: _explorerStressGame(12),
          samples: samples,
          warmup: warmup,
        );
        final baseline = small < 50_000 ? 50_000 : small;
        expect(
          large,
          lessThan(baseline * 25),
          reason:
              'median small=$smallµs large=$largeµs — 6× explorers should not '
              'inflate median refresh by more than ~25× on CI-class hardware '
              '(Refs #2394 shared-validator / hot-loop guard)',
        );
      },
    );
  });
}
