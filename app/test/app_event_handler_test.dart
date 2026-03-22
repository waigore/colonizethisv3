// Tests for AppEventHandler. SPEC/program/app-event-bus.md (architecture).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler.dart';

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
      handler = AppEventHandler(
        bus: bus,
        navigatorKey: navKey,
        dialogBuilders: {
          'test_dialog': (ctx, params) =>
              Material(child: Text('dialog:${params?['id'] ?? 'default'}')),
        },
        panelBuilders: {
          'test_panel': (ctx, params) =>
              Material(child: Text('panel:${params?['id'] ?? 'default'}')),
        },
      );
    });

    tearDown(() {
      handler.unbind();
      AppEventBus.reset();
    });

    testWidgets('OpenDialogEvent opens registered dialog', (tester) async {
      handler.bind();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () =>
                  bus.emit(const OpenDialogEvent('test_dialog', {'id': '42'})),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('dialog:42'), findsOneWidget);
    });

    testWidgets('OpenDialogEvent with unknown id shows nothing', (
      tester,
    ) async {
      handler.bind();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () =>
                  bus.emit(const OpenDialogEvent('unknown_dialog')),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('NavigateToRouteEvent calls pushNamed', (tester) async {
      handler.bind();
      final pushed = <RouteSettings?>[];

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          onGenerateRoute: (settings) {
            pushed.add(settings);
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const Text('target'),
            );
          },
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () =>
                  bus.emit(const NavigateToRouteEvent('/target', {'x': 1})),
              child: const Text('navigate'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('navigate'));
      await tester.pumpAndSettle();

      expect(pushed, hasLength(1));
      expect(pushed[0]?.name, '/target');
      expect(pushed[0]?.arguments, {'x': 1});
    });

    testWidgets('PopNavigationEvent calls nav.pop', (tester) async {
      handler.bind();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          navigatorObservers: [],
          initialRoute: '/base',
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

    testWidgets('OpenPauseMenuPanelEvent opens pause bottom sheet', (
      tester,
    ) async {
      handler.bind();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => bus.emit(
                  const OpenPauseMenuPanelEvent(
                    onDebugLog: null,
                    onResume: null,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Debug log'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
    });

    testWidgets('OpenPanelEvent opens registered bottom sheet panel', (
      tester,
    ) async {
      handler.bind();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => bus.emit(
                const OpenPanelEvent('test_panel', {'id': 'panel42'}),
              ),
              child: const Text('open panel'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open panel'));
      await tester.pumpAndSettle();

      expect(find.text('panel:panel42'), findsOneWidget);
    });

    testWidgets('OpenPanelEvent with unknown id shows nothing', (tester) async {
      handler.bind();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => bus.emit(const OpenPanelEvent('unknown_panel')),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('ConfirmDialogEvent shows dialog with title and message', (
      tester,
    ) async {
      handler.bind();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => bus.emit(
                const ConfirmDialogEvent(title: 'Confirm', message: 'Proceed?'),
              ),
              child: const Text('trigger'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Proceed?'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('ShowSnackBarEvent calls onShowSnackBar callback', (
      tester,
    ) async {
      ShowSnackBarEvent? received;
      handler = AppEventHandler(
        bus: bus,
        navigatorKey: navKey,
        onShowSnackBar: (e) => received = e,
      );
      handler.bind();

      await tester.pumpWidget(
        MaterialApp(navigatorKey: navKey, home: const Text('home')),
      );
      await tester.pumpAndSettle();

      bus.emit(
        const ShowSnackBarEvent(message: 'hello snack', actionLabel: 'undo'),
      );
      await tester.pumpAndSettle();

      expect(received?.message, 'hello snack');
      expect(received?.actionLabel, 'undo');
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

      await tester.pumpWidget(
        MaterialApp(navigatorKey: navKey, home: const Text('home')),
      );
      await tester.pumpAndSettle();

      bus.emit(const DismissOverlayEvent('loading_spinner'));
      await tester.pumpAndSettle();

      expect(received?.overlayId, 'loading_spinner');
    });
  });
}
