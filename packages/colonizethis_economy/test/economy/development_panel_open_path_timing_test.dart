// Open-path timing guard for Development panel (Refs #4175 Slice E AC2).
//
// Profiling surrogate for Flutter DevTools timeline captures: documents that the
// lazy per-region read model is measurably cheaper than the monolithic dual-region
// build used before Slice E, and that shared connectivity is reused across regions.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

import 'development_panel_open_path_timing_fixture.dart';

void main() {
  suppressLogsForTests();

  late DevelopmentPanelOpenPathTimingFixture fixture;

  setUp(() => fixture = DevelopmentPanelOpenPathTimingFixture.build());

  test(
    'lazy Old World-only read model is faster than monolithic dual-region build (Refs #4175 Slice E AC2)',
    () {
      const iterations = 50;
      final monolithicMicros = timeMicrosMedian(
        () => buildDevelopmentPanelModel(
          game: fixture.game,
          playerId: DevelopmentPanelOpenPathTimingFixture.playerId,
          tileMapByRegion: fixture.tileMapByRegion,
          topology: fixture.topology,
          currentOrders: DevelopmentPanelOpenPathTimingFixture.orders,
          provinceDisplayNamesById: fixture.provinceDisplayNamesById,
          playerDisplayNamesById: fixture.playerDisplayNamesById,
        ),
        iterations: iterations,
      );
      final lazyOwMicros = timeMicrosMedian(
        fixture.runDevelopmentLazyOldWorldOpenPath,
        iterations: iterations,
      );

      // Slice E open path builds one visited region; expect a measurable win vs
      // eager dual-region projection (typically ~35–60% on this fixture).
      final improvementRatio =
          (monolithicMicros - lazyOwMicros) / monolithicMicros;
      expect(
        lazyOwMicros,
        lessThan(monolithicMicros),
        reason:
            'monolithic=$monolithicMicrosµs lazyOW=$lazyOwMicrosµs '
            '(${ (improvementRatio * 100).toStringAsFixed(1)}% faster) '
            'over $iterations iterations',
      );
      expect(
        improvementRatio,
        greaterThanOrEqualTo(0.25),
        reason:
            'expected at least 25% read-model win on timing fixture; '
            'monolithic=$monolithicMicrosµs lazyOW=$lazyOwMicrosµs',
      );
    },
  );

  test(
    'lazy Old World open path is within Production panel peer budget (Refs #4175 Slice E AC1)',
    () {
      const iterations = 50;
      // Production peer surrogate is heavier (stockpile preview + counsel ranking);
      // Development lazy OW path must stay within 2× on the same fixture.
      const peerFactor = 2.0;
      final productionPeerMicros = timeMicros(
        fixture.runProductionPanelOpenPathSurrogate,
        iterations: iterations,
      );
      final lazyOwMicros = timeMicros(
        fixture.runDevelopmentLazyOldWorldOpenPath,
        iterations: iterations,
      );

      expect(
        lazyOwMicros,
        lessThanOrEqualTo((productionPeerMicros * peerFactor).round()),
        reason:
            'development lazyOW=$lazyOwMicrosµs productionPeer=$productionPeerMicrosµs '
            '(${peerFactor}x budget=${(productionPeerMicros * peerFactor).round()}µs) '
            'over $iterations iterations',
      );
    },
  );
}
