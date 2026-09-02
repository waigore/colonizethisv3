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

  test('ctAppPerfSurfaceOpen segment tracks elapsed ms for provinceOverlay (Refs #4690)', () {
    ctAppPerfSurfaceOpenBegin('provinceOverlay');
    expect(ctAppPerfSurfaceOpenElapsedMs('provinceOverlay'), isNotNull);
    final elapsed = ctAppPerfSurfaceOpenInteractiveReady('provinceOverlay');
    expect(elapsed, isNotNull);
    expect(elapsed, greaterThanOrEqualTo(0));
    expect(() => ctAppPerfInstant('provinceOverlay.interactiveReady'), returnsNormally);
  });

  test('ctAppPerfSurfaceOpen segment tracks production surface (Refs #4688)', () {
    ctAppPerfSurfaceOpenBegin('production');
    expect(ctAppPerfSurfaceOpenElapsedMs('production'), isNotNull);
    final elapsed = ctAppPerfSurfaceOpenInteractiveReady('production');
    expect(elapsed, isNotNull);
    expect(elapsed, greaterThanOrEqualTo(0));
    expect(() => ctAppPerfInstant('production.interactiveReady'), returnsNormally);
  });

  test('ctAppPerfSurfaceOpen segment tracks trade surface (Refs #4688)', () {
    ctAppPerfSurfaceOpenBegin('trade');
    expect(ctAppPerfSurfaceOpenElapsedMs('trade'), isNotNull);
    final elapsed = ctAppPerfSurfaceOpenInteractiveReady('trade');
    expect(elapsed, isNotNull);
    expect(elapsed, greaterThanOrEqualTo(0));
    expect(() => ctAppPerfInstant('trade.interactiveReady'), returnsNormally);
  });

  test('ctAppPerfSurfaceOpen segment tracks technology surface (Refs #4688)', () {
    ctAppPerfSurfaceOpenBegin('technology');
    expect(ctAppPerfSurfaceOpenElapsedMs('technology'), isNotNull);
    final elapsed = ctAppPerfSurfaceOpenInteractiveReady('technology');
    expect(elapsed, isNotNull);
    expect(elapsed, greaterThanOrEqualTo(0));
    expect(() => ctAppPerfInstant('technology.interactiveReady'), returnsNormally);
  });

  test('ctAppPerfSurfaceOpen segment tracks diplomacy surface (Refs #4688)', () {
    ctAppPerfSurfaceOpenBegin('diplomacy');
    expect(ctAppPerfSurfaceOpenElapsedMs('diplomacy'), isNotNull);
    final elapsed = ctAppPerfSurfaceOpenInteractiveReady('diplomacy');
    expect(elapsed, isNotNull);
    expect(elapsed, greaterThanOrEqualTo(0));
    expect(() => ctAppPerfInstant('diplomacy.interactiveReady'), returnsNormally);
  });

  test('ctAppPerfSurfaceOpen segment tracks victory surface (Refs #4688)', () {
    ctAppPerfSurfaceOpenBegin('victory');
    expect(ctAppPerfSurfaceOpenElapsedMs('victory'), isNotNull);
    final elapsed = ctAppPerfSurfaceOpenInteractiveReady('victory');
    expect(elapsed, isNotNull);
    expect(elapsed, greaterThanOrEqualTo(0));
    expect(() => ctAppPerfInstant('victory.interactiveReady'), returnsNormally);
  });

  test('ctAppPerfSurfaceOpen segment tracks counsel surface (Refs #4688)', () {
    ctAppPerfSurfaceOpenBegin('counsel');
    expect(ctAppPerfSurfaceOpenElapsedMs('counsel'), isNotNull);
    final elapsed = ctAppPerfSurfaceOpenInteractiveReady('counsel');
    expect(elapsed, isNotNull);
    expect(elapsed, greaterThanOrEqualTo(0));
    expect(() => ctAppPerfInstant('counsel.interactiveReady'), returnsNormally);
  });

  test('ctAppPerfSurfaceOpen segment tracks militaryUnits surface (Refs #4688)', () {
    ctAppPerfSurfaceOpenBegin('militaryUnits');
    expect(ctAppPerfSurfaceOpenElapsedMs('militaryUnits'), isNotNull);
    final elapsed = ctAppPerfSurfaceOpenInteractiveReady('militaryUnits');
    expect(elapsed, isNotNull);
    expect(elapsed, greaterThanOrEqualTo(0));
    expect(
      () => ctAppPerfInstant('militaryUnits.interactiveReady'),
      returnsNormally,
    );
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

  test(
    'Turn-shell CtAppPerf marker names are DevTools-filterable (Refs #4715)',
    () {
      const markers = <String>[
        'nextTurnConfirm.interactiveReady',
        'turnNews.interactiveReady',
        'playerTurnEventFeed.interactiveReady',
      ];
      for (final name in markers) {
        expect(() => ctAppPerfInstant(name), returnsNormally);
        expect(ctAppPerfSync(name, () => name.length), name.length);
      }
      for (final surfaceId in ['nextTurnConfirm', 'turnNews', 'playerTurnEventFeed']) {
        ctAppPerfSurfaceOpenBegin(surfaceId);
        final elapsed = ctAppPerfSurfaceOpenInteractiveReady(surfaceId);
        expect(elapsed, isNotNull);
        expect(elapsed, greaterThanOrEqualTo(0));
      }
    },
  );
}
