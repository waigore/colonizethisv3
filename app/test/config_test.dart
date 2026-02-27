// Log suppression first (SPEC/program/test-logging.md); then Flutter test API.
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';

void main() {
  // Suppress logs for test run.
  suppressLogsForTests();
  group('HiveBoxNames', () {
    test('has expected box names', () {
      expect(HiveBoxNames.settings, 'settings');
      expect(HiveBoxNames.games, 'games');
      expect(HiveBoxNames.offlineQueue, 'offline_queue');
    });
  });

  group('Routes', () {
    test('shell and game route names', () {
      expect(Routes.shell, '/');
      expect(Routes.game, '/game');
    });
    test('generate returns route for shell', () {
      final route = Routes.generate(const RouteSettings(name: '/'));
      expect(route, isNotNull);
    });
    test('generate returns route for game', () {
      final route = Routes.generate(const RouteSettings(name: '/game'));
      expect(route, isNotNull);
    });
    test('generate returns null for unknown route', () {
      final route = Routes.generate(const RouteSettings(name: '/unknown'));
      expect(route, isNull);
    });
  });
}
