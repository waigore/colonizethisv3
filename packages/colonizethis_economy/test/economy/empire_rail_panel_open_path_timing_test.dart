// Empire-rail panel open-path profiling anchors (Refs #4688).
//
// Documents synchronous prep cost for Production first paint, counsel deferral,
// and consolidated representative-fixture µs ratchets tied to
// [kUiSurfaceOpenBudgetMs]. Not a debug wall-clock 1s assertion.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

import 'development_panel_open_path_timing_fixture.dart';

/// CI µs ratchet ceilings on [DevelopmentPanelOpenPathTimingFixture].
/// Product wall-clock ceiling is [kUiSurfaceOpenBudgetMs]; these shrink-only
/// profiling anchors are not debug 1s wall-clock gates.
const _kProductionDeferredOpenPathMicrosRatchet = 500000;
const _kDevelopmentLazyOwOpenPathMicrosRatchet = 100000;

void main() {
  suppressLogsForTests();

  late DevelopmentPanelOpenPathTimingFixture fixture;

  setUp(() => fixture = DevelopmentPanelOpenPathTimingFixture.build());

  test(
    'production open-path surrogate without counsel is faster than full first paint (Refs #4688 Slice 1)',
    () {
      const iterations = 50;
      final withCounselMicros = timeMicrosMedian(
        fixture.runProductionPanelOpenPathSurrogate,
        iterations: iterations,
      );
      final withoutCounselMicros = timeMicrosMedian(
        fixture.runProductionPanelOpenPathSurrogateWithoutCounsel,
        iterations: iterations,
      );

      expect(
        withoutCounselMicros,
        lessThan(withCounselMicros),
        reason:
            'withCounsel=$withCounselMicrosµs withoutCounsel=$withoutCounselMicrosµs '
            'over $iterations iterations',
      );
      final improvementRatio =
          (withCounselMicros - withoutCounselMicros) / withCounselMicros;
      expect(
        improvementRatio,
        greaterThanOrEqualTo(0.05),
        reason:
            'expected measurable counsel-ranking cost on production open path; '
            'withCounsel=$withCounselMicrosµs withoutCounsel=$withoutCounselMicrosµs',
      );
    },
  );

  test(
    'production deferred open-path surrogate stays under representative-fixture µs ratchet (Refs #4688 Slice 9)',
    () {
      const iterations = 50;
      final deferredMicros = timeMicrosMedian(
        fixture.runProductionPanelOpenPathSurrogateWithoutCounsel,
        iterations: iterations,
      );

      expect(
        deferredMicros,
        lessThanOrEqualTo(_kProductionDeferredOpenPathMicrosRatchet),
        reason:
            'deferred=$deferredMicrosµs ratchet=$_kProductionDeferredOpenPathMicrosRatchetµs '
            'over $iterations iterations',
      );
    },
  );

  test(
    'development lazy OW open-path surrogate stays under representative-fixture µs ratchet (Refs #4688 Slice 9)',
    () {
      const iterations = 50;
      final lazyOwMicros = timeMicrosMedian(
        fixture.runDevelopmentLazyOldWorldOpenPath,
        iterations: iterations,
      );

      expect(
        lazyOwMicros,
        lessThanOrEqualTo(_kDevelopmentLazyOwOpenPathMicrosRatchet),
        reason:
            'lazyOW=$lazyOwMicrosµs ratchet=$_kDevelopmentLazyOwOpenPathMicrosRatchetµs '
            'over $iterations iterations',
      );
    },
  );

  test(
    'consolidated empire-rail deferred surrogates stay under kUiSurfaceOpenBudgetMs µs ceiling on representative fixture (Refs #4688 Slice 9)',
    () {
      const iterations = 50;
      final consolidatedMicros = timeMicrosMedian(
        () {
          fixture.runProductionPanelOpenPathSurrogateWithoutCounsel();
          fixture.runDevelopmentLazyOldWorldOpenPath();
        },
        iterations: iterations,
      );
      final consolidatedRatchetMicros = kUiSurfaceOpenBudgetMs * 1000;

      expect(
        consolidatedMicros,
        lessThanOrEqualTo(consolidatedRatchetMicros),
        reason:
            'consolidated=$consolidatedMicrosµs '
            'ratchet=${consolidatedRatchetMicros}µs '
            '(kUiSurfaceOpenBudgetMs=$kUiSurfaceOpenBudgetMs) '
            'over $iterations iterations',
      );
    },
  );
}
