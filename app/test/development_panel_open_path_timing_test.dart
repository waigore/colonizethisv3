// Session-cache reopen profiling anchors for GAME80001 (Refs #4687 Slice E).
//
// CI surrogate for profile/release DevTools sessions: documents that cached
// connectivity and map-snapshot resolve are measurably cheaper than cold builds
// on the golden campaign fixture. Not a debug wall-clock 1s assertion.

import 'package:colonizethis_app/features/game/screens/development/development_panel_map_snapshot.dart';
import 'package:colonizethis_app/providers/development_panel_projection_provider.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart'
    show ConnectivityResult, kRegionOldWorld;
import 'package:flutter_test/flutter_test.dart';

import 'development_panel_open_path_timing_fixture.dart';

Map<String, ConnectivityResult> _resolveConnectivityCold(
  DevelopmentPanelOpenPathTimingFixture fixture,
) {
  return resolveDevelopmentPanelConnectivity(
    game: fixture.game,
    tileMapByRegion: fixture.mapData.tileMapByRegion,
    topology: fixture.mapData.combinedTopology,
    humanPlayerId: fixture.humanPlayerId,
  );
}

Map<String, ConnectivityResult> _resolveConnectivityWarm(
  DevelopmentPanelSessionCache cache,
  DevelopmentPanelOpenPathTimingFixture fixture,
) {
  final revision = developmentPanelStaticSessionRevision(game: fixture.game);
  final session = cache.state;
  if (session.staticRevision == revision && session.connectivity != null) {
    return session.connectivity!;
  }
  final connectivity = _resolveConnectivityCold(fixture);
  cache.storeConnectivity(revision: revision, connectivity: connectivity);
  return connectivity;
}

DevelopmentPanelMapSnapshot _resolveMapSnapshotCold(
  DevelopmentPanelOpenPathTimingFixture fixture,
) {
  return buildDevelopmentPanelMapSnapshot(
    game: fixture.game,
    humanPlayerId: fixture.humanPlayerId,
    regionId: kRegionOldWorld,
    playerView: fixture.playerView,
    tileMapByRegion: fixture.mapData.tileMapByRegion,
    topologyByRegion: fixture.mapData.topologyByRegion,
  );
}

DevelopmentPanelMapSnapshot _resolveMapSnapshotWarm(
  DevelopmentPanelSessionCache cache,
  DevelopmentPanelOpenPathTimingFixture fixture,
) {
  final revision = developmentPanelStaticSessionRevision(game: fixture.game);
  final session = cache.state;
  final cached = session.mapSnapshotsByRegion[kRegionOldWorld];
  if (session.staticRevision == revision && cached != null) {
    return cached;
  }
  final snapshot = _resolveMapSnapshotCold(fixture);
  cache.storeMapSnapshot(
    revision: revision,
    regionId: kRegionOldWorld,
    snapshot: snapshot,
  );
  return snapshot;
}

void main() {
  suppressLogsForTests();

  late DevelopmentPanelOpenPathTimingFixture fixture;

  setUp(() => fixture = DevelopmentPanelOpenPathTimingFixture.build());

  test(
    'cached connectivity resolve is faster than cold build (Refs #4687 Slice C)',
    () {
      const iterations = 30;
      final coldMicros = developmentPanelOpenPathTimeMicrosMedian(
        () => _resolveConnectivityCold(fixture),
        iterations: iterations,
      );

      final cache = DevelopmentPanelSessionCache();
      _resolveConnectivityWarm(cache, fixture);

      final warmMicros = developmentPanelOpenPathTimeMicrosMedian(
        () => _resolveConnectivityWarm(cache, fixture),
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
            'expected at least 50% connectivity cache win on golden fixture; '
            'cold=$coldMicrosµs warm=$warmMicrosµs',
      );
    },
  );

  test(
    'cached map snapshot resolve is faster than cold build (Refs #4687 Slice D)',
    () {
      const iterations = 20;
      final coldMicros = developmentPanelOpenPathTimeMicrosMedian(
        () => _resolveMapSnapshotCold(fixture),
        iterations: iterations,
      );

      final cache = DevelopmentPanelSessionCache();
      _resolveMapSnapshotWarm(cache, fixture);

      final warmMicros = developmentPanelOpenPathTimeMicrosMedian(
        () => _resolveMapSnapshotWarm(cache, fixture),
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
            'expected at least 50% map snapshot cache win on golden fixture; '
            'cold=$coldMicrosµs warm=$warmMicrosµs',
      );
    },
  );
}
