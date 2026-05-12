// Anchors the documented `e2eAdaptivePollRampAfterIdle` ramp contract used by
// the New World fleet helpers' adaptive poll loops (Refs #2336 AC5). Adaptive
// loops in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` rely on
// this ramp for civilian panel open, Explore-row assign sweep, split-fleet
// dialog dismissal, and next-turn label advance polls.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

  group('e2eAdaptivePollRampAfterIdle', () {
    test('ramps 25 -> 50 -> 75 -> 100 and saturates at 100', () {
      var stepMs = 25;
      final observed = <int>[stepMs];
      for (var i = 0; i < 6; i++) {
        stepMs = e2eAdaptivePollRampAfterIdle(stepMs);
        observed.add(stepMs);
      }
      expect(observed, <int>[25, 50, 75, 100, 100, 100, 100]);
    });

    test('returns 100 once the input is at the cap', () {
      expect(e2eAdaptivePollRampAfterIdle(100), 100);
      expect(e2eAdaptivePollRampAfterIdle(200), 100);
    });

    test('keeps every produced step <= 500ms (#2336 AC5 cap)', () {
      var stepMs = 25;
      for (var i = 0; i < 100; i++) {
        stepMs = e2eAdaptivePollRampAfterIdle(stepMs);
        expect(stepMs, lessThanOrEqualTo(500));
      }
    });
  });
}
