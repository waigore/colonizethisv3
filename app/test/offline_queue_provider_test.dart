import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/providers/offline_queue_provider.dart';

void main() {
  suppressLogsForTests();

  group('offlineQueueProvider', () {
    test('has default empty list and can enqueue/dequeue', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(offlineQueueProvider.notifier);

      expect(container.read(offlineQueueProvider), isEmpty);

      notifier.state = [...notifier.state, 'action-1', 'action-2'];
      expect(container.read(offlineQueueProvider), ['action-1', 'action-2']);

      // Dequeue first element.
      notifier.state = notifier.state.skip(1).toList();
      expect(container.read(offlineQueueProvider), ['action-2']);
    });
  });
}

