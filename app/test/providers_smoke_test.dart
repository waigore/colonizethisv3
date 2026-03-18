import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/providers/settings_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';

void main() {
  suppressLogsForTests();

  group('core providers', () {
    test('settingsProvider has default empty map state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings, isEmpty);
    });

    test('currentGameProvider and currentOrdersProvider have sensible defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final currentGame = container.read(currentGameProvider);
      final orders = container.read(currentOrdersProvider);

      expect(currentGame, isNull);
      expect(orders, isNotNull);
    });
  });
}

