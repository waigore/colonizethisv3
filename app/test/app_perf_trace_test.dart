// Log suppression first (SPEC/program/test-logging.md); then Flutter test API.
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';

void main() {
  suppressLogsForTests();

  test('ctAppPerfSync returns value from action', () {
    final v = ctAppPerfSync('test.block', () => 42);
    expect(v, 42);
  });

  test('ctAppPerfInstant does not throw', () {
    expect(() => ctAppPerfInstant('test.instant'), returnsNormally);
  });

  test(
    'Development panel CtAppPerf marker names are DevTools-filterable (Refs #4175 Slice E AC2)',
    () {
      // SPEC/program/flutter-performance-tracing.md § Development panel open path.
      const markers = <String>[
        'development.readModelReady',
        'developmentPanel.connectivity',
        'developmentPanel.staticContext',
        'developmentPanel.sharedContext',
        'developmentPanel.regionScopes.oldWorld',
        'developmentPanel.regionModel.oldWorld',
        'developmentPanel.assignRowCache.oldWorld',
      ];
      for (final name in markers) {
        expect(name, startsWith('development'));
        expect(() => ctAppPerfInstant(name), returnsNormally);
        expect(ctAppPerfSync(name, () => name.length), name.length);
      }
    },
  );

  test(
    'Province overlay CtAppPerf marker names are DevTools-filterable (Refs #4690)',
    () {
      const markers = <String>['provinceOverlay.interactiveReady'];
      for (final name in markers) {
        expect(name, startsWith('provinceOverlay'));
        expect(() => ctAppPerfInstant(name), returnsNormally);
        expect(ctAppPerfSync(name, () => name.length), name.length);
      }
    },
  );
}
