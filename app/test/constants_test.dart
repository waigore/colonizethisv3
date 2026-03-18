import 'package:colonizethis_app/config/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HiveBoxNames constants are stable', () {
    expect(HiveBoxNames.settings, 'settings');
    expect(HiveBoxNames.games, 'games');
    expect(HiveBoxNames.offlineQueue, 'offline_queue');
  });
}

