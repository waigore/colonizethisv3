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

  test('ctAppPerfSurfaceOpen segment tracks elapsed ms (Refs #4687)', () {
    ctAppPerfSurfaceOpenBegin('development');
    expect(ctAppPerfSurfaceOpenElapsedMs('development'), isNotNull);
    final elapsed = ctAppPerfSurfaceOpenInteractiveReady('development');
    expect(elapsed, isNotNull);
    expect(elapsed, greaterThanOrEqualTo(0));
    expect(() => ctAppPerfInstant('development.interactiveReady'), returnsNormally);
  });

  test('ctAppPerfSurfaceOpenBindingHost returns a non-empty label (Refs #4687)', () {
    final host = ctAppPerfSurfaceOpenBindingHost();
    expect(host, isNotEmpty);
    expect(host, endsWith('_profile'));
  });

  test(
    'ctAppPerfSurfaceOpenBindingHost returns a known profile label (Refs #4687)',
    () {
      final host = ctAppPerfSurfaceOpenBindingHost();
      expect(
        host,
        isIn(<String>[
          'linux_desktop_profile',
          'android_emulator_profile',
          'ios_simulator_profile',
          'macos_desktop_profile',
          'windows_desktop_profile',
          'web_profile',
          'fuchsia_profile',
        ]),
      );
    },
  );

  test(
    'Development panel CtAppPerf marker names are DevTools-filterable (Refs #4175 Slice E AC2)',
    () {
      // SPEC/program/flutter-performance-tracing.md § Development panel open path.
      const markers = <String>[
        'development.readModelReady',
        'development.interactiveReady',
        'developmentPanel.connectivity',
        'developmentPanel.staticContext',
        'developmentPanel.sharedContext',
        'developmentPanel.regionScopes.oldWorld',
        'developmentPanel.regionModel.oldWorld',
        'developmentPanel.assignRowCache.oldWorld',
        'developmentPanel.mapSnapshot.oldWorld',
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
      const markers = <String>[
        'provinceOverlay.interactiveReady',
        'provinceOverlay.humanConnectivity',
        'provinceOverlay.provinceReadModel.oldWorld|p1',
      ];
      for (final name in markers) {
        expect(name, startsWith('provinceOverlay'));
        expect(() => ctAppPerfInstant(name), returnsNormally);
        expect(ctAppPerfSync(name, () => name.length), name.length);
      }
    },
  );

  test(
    'Empire-rail panel CtAppPerf marker names are DevTools-filterable (Refs #4688)',
    () {
      const markers = <String>[
        'production.interactiveReady',
        'production.openPath',
        'production.industryCounsel',
        'trade.interactiveReady',
        'diplomacy.interactiveReady',
        'diplomacy.rowsBuild',
        'technology.interactiveReady',
        'technology.slotsOpenPath',
        'victory.interactiveReady',
        'victory.openPath',
        'civilianUnits.interactiveReady',
        'militaryUnits.interactiveReady',
        'militaryUnits.treeBuild',
        'navalUnits.interactiveReady',
        'navalUnits.treeBuild',
        'counsel.interactiveReady',
        'counsel.industryBuild',
        'counsel.tradeBuild',
        'counsel.militaryBuild',
        'counsel.developmentBuild',
      ];
      for (final name in markers) {
        expect(() => ctAppPerfInstant(name), returnsNormally);
        expect(ctAppPerfSync(name, () => name.length), name.length);
      }
    },
  );
}
