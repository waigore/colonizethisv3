import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/route_paths.dart';

void main() {
  suppressLogsForTests();

  test('HiveBoxNames constants are stable', () {
    expect(HiveBoxNames.settings, 'settings');
    expect(HiveBoxNames.games, 'games');
    expect(HiveBoxNames.offlineQueue, 'offline_queue');
  });

  test('desktop window constants are stable', () {
    expect(kDesktopWindowMinWidth, 800);
    expect(kDesktopWindowMinHeight, 600);
    expect(kDesktopWindowDefaultWidth, 1280);
    expect(kDesktopWindowDefaultHeight, 720);
  });

  test('RoutePaths strings are stable (no heavy routes.dart import)', () {
    expect(RoutePaths.shell, '/');
    expect(RoutePaths.game, '/game');
    expect(RoutePaths.debugLog, '/debug-log');
    expect(RoutePaths.production, '/game/production');
    expect(RoutePaths.diplomacy, '/game/diplomacy');
    expect(RoutePaths.diplomacyDetail, '/game/diplomacy/detail');
    expect(RoutePaths.technology, '/game/technology');
  });
}
