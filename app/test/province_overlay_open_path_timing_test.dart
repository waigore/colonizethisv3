// Open-path timing guard for MAP20001 session-cache reopen (Refs #4690 Slice C).
//
// Profiling surrogate for profile/release DevTools sessions: documents that
// cached province-wide read-model resolve is measurably cheaper than a cold
// build on the seed-42 campaign fixture. Not a debug wall-clock 1s assertion.

import 'package:colonizethis_app/providers/province_overlay_read_model_cache_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_open_path_timing_fixture.dart';

void main() {
  suppressLogsForTests();

  late ProvinceOverlayOpenPathTimingFixture fixture;

  setUp(() => fixture = ProvinceOverlayOpenPathTimingFixture.build());

  test(
    'cached province read-model resolve is faster than cold build (Refs #4690 Slice C)',
    () {
      const iterations = 30;
      final coldMicros = provinceOverlayOpenPathTimeMicrosMedian(
        () => buildProvinceOverlayProvinceReadModel(
          game: fixture.game,
          displayId: fixture.displayId,
          mapData: fixture.mapData,
        ),
        iterations: iterations,
      );

      final cache = ProvinceOverlaySessionCache();
      resolveProvinceOverlayProvinceReadModel(
        cache: cache,
        game: fixture.game,
        displayId: fixture.displayId,
        mapData: fixture.mapData,
      );

      final warmMicros = provinceOverlayOpenPathTimeMicrosMedian(
        () => resolveProvinceOverlayProvinceReadModel(
          cache: cache,
          game: fixture.game,
          displayId: fixture.displayId,
          mapData: fixture.mapData,
        ),
        iterations: iterations,
      );

      final improvementRatio = (coldMicros - warmMicros) / coldMicros;
      expect(
        warmMicros,
        lessThan(coldMicros),
        reason:
            'cold=$coldMicrosµs warm=$warmMicrosµs '
            '(${ (improvementRatio * 100).toStringAsFixed(1)}% faster) '
            'over $iterations iterations',
      );
      expect(
        improvementRatio,
        greaterThanOrEqualTo(0.5),
        reason:
            'expected at least 50% read-model win on seed-42 fixture; '
            'cold=$coldMicrosµs warm=$warmMicrosµs',
      );
    },
  );

  test(
    'cached human connectivity resolve is faster than cold resolve (Refs #4690 Slice C)',
    () {
      const iterations = 30;
      final humanPlayerId = fixture.game.players.first.id;
      final coldMicros = provinceOverlayOpenPathTimeMicrosMedian(
        () => resolveProvinceOverlayHumanConnectivity(
          cache: ProvinceOverlaySessionCache(),
          game: fixture.game,
          humanPlayerId: humanPlayerId,
          mapData: fixture.mapData,
        ),
        iterations: iterations,
      );

      final cache = ProvinceOverlaySessionCache();
      resolveProvinceOverlayHumanConnectivity(
        cache: cache,
        game: fixture.game,
        humanPlayerId: humanPlayerId,
        mapData: fixture.mapData,
      );

      final warmMicros = provinceOverlayOpenPathTimeMicrosMedian(
        () => resolveProvinceOverlayHumanConnectivity(
          cache: cache,
          game: fixture.game,
          humanPlayerId: humanPlayerId,
          mapData: fixture.mapData,
        ),
        iterations: iterations,
      );

      expect(warmMicros, lessThan(coldMicros));
    },
  );
}
