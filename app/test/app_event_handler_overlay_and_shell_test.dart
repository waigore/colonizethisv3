// Remaining AppEventHandler overlay/shell ACs (Refs #4606 Slice D).
// SPEC/program/app-event-bus.md.

import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_event_handler_test_support.dart';
import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  group('AppEventHandler overlay and shell navigation', () {
    late AppEventBus bus;
    late GlobalKey<NavigatorState> navKey;
    late AppEventHandler handler;

    setUp(() {
      AppEventBus.reset();
      bus = AppEventBus.create();
      navKey = GlobalKey<NavigatorState>();
      handler = buildTestAppEventHandler(bus: bus, navigatorKey: navKey);
    });

    tearDown(() {
      handler.unbind();
      AppEventBus.reset();
    });

    testWidgets('DismissOverlayEvent calls onDismissOverlay callback', (
      tester,
    ) async {
      DismissOverlayEvent? received;
      handler = AppEventHandler(
        bus: bus,
        navigatorKey: navKey,
        onDismissOverlay: (e) => received = e,
      );
      handler.bind();
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'home',
        home: const Text('home'),
        onPressed: () {},
      );
      bus.emit(const DismissOverlayEvent('loading_spinner'));
      await tester.pumpAndSettle();
      expect(received?.overlayId, 'loading_spinner');
    });

    testWidgets('NavigateToShellEvent pops until shell route', (tester) async {
      handler.bind();

      await tester.pumpWidget(
        buildAppShell(
          navigatorKey: navKey,
          onGenerateRoute: (settings) {
            if (settings.name == RoutePaths.game) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Text('game_layer'),
              );
            }
            if (settings.name == RoutePaths.shell) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Text('shell_layer'),
              );
            }
            return null;
          },
          child: const Text('shell_layer'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('shell_layer'), findsOneWidget);

      navKey.currentState!.pushNamed(RoutePaths.game);
      await tester.pumpAndSettle();
      expect(find.text('game_layer'), findsOneWidget);

      bus.emit(const NavigateToShellEvent());
      await tester.pumpAndSettle();

      expect(find.text('game_layer'), findsNothing);
      expect(find.text('shell_layer'), findsOneWidget);
    });

    testWidgets(
      'ClosePanelEvent then OpenDialogEvent opens dialog (handler ordering)',
      (tester) async {
        handler.bind();
        await pumpAppEventHandlerEmitButton(
          tester,
          navigatorKey: navKey,
          label: 'home',
          home: const Scaffold(body: Text('home')),
          onPressed: () {},
        );
        bus.emit(const ClosePanelEvent());
        bus.emit(const OpenDialogEvent('test_dialog', {'id': 'after_close'}));
        await tester.pumpAndSettle();
        expect(find.text('dialog:after_close'), findsOneWidget);
      },
    );
  });
}
