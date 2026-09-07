import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'per_player_work_target_selection_cache_perf_cases.dart';

void main() {
  suppressLogsForTests();

  group('PerPlayerWorkTargetSelectionCache perf (Refs #2394)', () {
    test(
      'default-strategies refresh stays within a generous smoke ceiling',
      () {
        final game = workTargetCachePerfExplorerStressGame(4);
        final cache = PerPlayerWorkTargetSelectionCache();
        const ceilingMicros = 8 * 1000 * 1000;
        final median = workTargetCachePerfMedianRefreshMicros(
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
        final game = workTargetCachePerfExplorerStressGame(6);
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(
          game,
          topology,
          workTargetCachePerfPlayerId,
        );
        final base = WorkTargetSelectionSnapshot(
          game: game,
          playerId: workTargetCachePerfPlayerId,
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
        expectWorkTargetCachesEqualForAllTargets(implicitCache, explicitCache);
      },
    );

    test(
      'default-strategies refresh cost scales roughly linearly with explorer count',
      () {
        final cache = PerPlayerWorkTargetSelectionCache();
        const warmup = 2;
        const samples = 5;
        final small = workTargetCachePerfMedianRefreshMicros(
          cache: cache,
          game: workTargetCachePerfExplorerStressGame(2),
          warmup: warmup,
          samples: samples,
        );
        final large = workTargetCachePerfMedianRefreshMicros(
          cache: cache,
          game: workTargetCachePerfExplorerStressGame(12),
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
