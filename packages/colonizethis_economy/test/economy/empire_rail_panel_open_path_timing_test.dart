// Empire-rail panel open-path profiling anchors (Refs #4688 Slice 1).
//
// Documents synchronous prep cost for Production first paint and the counsel
// ranking slice that Slice 2 will defer. Not a debug wall-clock 1s assertion.

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

import 'development_panel_open_path_timing_fixture.dart';

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
}
