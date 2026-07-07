import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';

void main() {
  suppressLogsForTests();

  group('Routes.generate', () {
    test('shell and game route names match RoutePaths', () {
      expect(Routes.shell, RoutePaths.shell);
      expect(Routes.game, RoutePaths.game);
    });

    test('generate returns route for shell', () {
      final route = Routes.generate(RouteSettings(name: RoutePaths.shell));
      expect(route, isNotNull);
    });

    test('generate returns route for game', () {
      final route = Routes.generate(RouteSettings(name: RoutePaths.game));
      expect(route, isNotNull);
    });

    test('generate returns null for unknown route', () {
      final route = Routes.generate(const RouteSettings(name: '/unknown'));
      expect(route, isNull);
    });
  });

  group('App shell and routes', () {
    testWidgets('App uses Routes.shell as initial route', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: AppEventHandlerScope(child: App())),
      );
      await tester.pumpAndSettle();

      // Shell route should be active; CtMainMenu buttons should be visible.
      expect(find.text('New Game'), findsOneWidget);
      expect(find.text('Load Game'), findsOneWidget);
    });

    testWidgets('Debug log menu item pushes debug route', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: AppEventHandlerScope(child: App())),
      );
      await tester.pumpAndSettle();

      // Simulate menu selection using the exported navigator key.
      appNavigatorKey.currentState?.pushNamed(Routes.debugLog);
      await tester.pumpAndSettle();

      expect(find.text('Debug log'), findsOneWidget);
    });
  });
}
