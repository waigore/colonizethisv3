import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'dart:async';

import 'package:colonizethis_app/core/services/subscription_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  test(
    'Given two tracked subscriptions When cancelAll Then further events are ignored',
    () async {
      final tracker = SubscriptionTracker();
      final c1 = StreamController<int>();
      final c2 = StreamController<int>();
      var count = 0;
      tracker.track(c1.stream.listen((_) => count++));
      tracker.track(c2.stream.listen((_) => count++));
      c1.add(1);
      c2.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(count, 2);

      tracker.cancelAll();
      c1.add(1);
      c2.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(count, 2);

      await c1.close();
      await c2.close();
    },
  );
}
