import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';

void main() {
  suppressLogsForTests();

  test('HiveBoxNames constants are stable', () {
    expect(HiveBoxNames.settings, 'settings');
    expect(HiveBoxNames.games, 'games');
    expect(HiveBoxNames.offlineQueue, 'offline_queue');
  });
}

