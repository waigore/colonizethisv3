// Tests for AppEventHandler. SPEC/program/app-event-bus.md (architecture).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler.dart';
import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:colonizethis_app/features/game/widgets/panels/pause_menu_panel.dart';
import 'package:colonizethis_app/providers/turn_resolution_blocking_provider.dart';

import 'app_event_handler_test_support.dart';
import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  group('AppEventHandler', () {
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

    testWidgets('OpenDialogEvent opens registered dialog', (tester) async {
      handler.bind();
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'open',
        onPressed: () =>
            bus.emit(const OpenDialogEvent('test_dialog', {'id': '42'})),
      );
      await tapAppEventHandlerLabel(tester, 'open');
      expect(find.text('dialog:42'), findsOneWidget);
    });

    testWidgets('OpenDialogEvent with unknown id shows nothing', (
      tester,
    ) async {
      handler.bind();
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'open',
        onPressed: () => bus.emit(const OpenDialogEvent('unknown_dialog')),
      );
      await tapAppEventHandlerLabel(tester, 'open');
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('NavigateToRouteEvent calls pushNamed', (tester) async {
      handler.bind();
      final pushed = <RouteSettings?>[];
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'navigate',
        onGenerateRoute: (settings) {
          pushed.add(settings);
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Text('target'),
          );
        },
        onPressed: () =>
            bus.emit(const NavigateToRouteEvent('/target', {'x': 1})),
      );
      await tapAppEventHandlerLabel(tester, 'navigate');
      expect(pushed, hasLength(1));
      expect(pushed[0]?.name, '/target');
      expect(pushed[0]?.arguments, {'x': 1});
    });

    testWidgets('PopNavigationEvent calls nav.pop', (tester) async {
      handler.bind();

      // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
      await tester.pumpWidget(
        buildAppShell(
          navigatorKey: navKey,
          onGenerateRoute: (settings) {
            if (settings.name == '/overlay') {
              return MaterialPageRoute(
                settings: settings,
                builder: (ctx) => const Text('overlay_route'),
              );
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (ctx) => const Text('base_route'),
            );
          },
          child: const Text('base_route'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('base_route'), findsOneWidget);

      navKey.currentState?.pushNamed('/overlay');
      await tester.pumpAndSettle();

      expect(find.text('overlay_route'), findsOneWidget);

      bus.emit(const PopNavigationEvent());
      await tester.pumpAndSettle();

      expect(find.text('overlay_route'), findsNothing);
      expect(find.text('base_route'), findsOneWidget);
    });

    testWidgets('OpenPauseMenuPanelEvent opens centered PauseMenuPanel modal '
        'with five action buttons', (tester) async {
      handler.bind();
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'open',
        overrides: [
          turnResolutionBlockingProvider.overrideWith(
            () => StateToggleNotifier(false),
          ),
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => bus.emit(const OpenPauseMenuPanelEvent()),
              child: const Text('open'),
            ),
          ),
        ),
        onPressed: () {},
      );
      await tapAppEventHandlerLabel(tester, 'open');
      expect(find.byType(PauseMenuPanel), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Save Game'), findsOneWidget);
      expect(find.text('Load Game'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Exit to Main Menu'), findsOneWidget);
      // Debug log was moved to GameSideMenu in the redesign.
      expect(find.text('Debug log'), findsNothing);
    });

    testWidgets('OpenPanelEvent opens registered bottom sheet panel', (
      tester,
    ) async {
      handler.bind();
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'open panel',
        onPressed: () =>
            bus.emit(const OpenPanelEvent('test_panel', {'id': 'panel42'})),
      );
      await tapAppEventHandlerLabel(tester, 'open panel');
      expect(find.text('panel:panel42'), findsOneWidget);
    });

    testWidgets('OpenPanelEvent with unknown id shows nothing', (tester) async {
      handler.bind();
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'open',
        onPressed: () => bus.emit(const OpenPanelEvent('unknown_panel')),
      );
      await tapAppEventHandlerLabel(tester, 'open');
      expect(find.text('open'), findsOneWidget);
    });
  });
}
