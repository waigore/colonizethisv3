// AppEventHandler confirm-dialog, extra-action, and snackbar ACs
// (Refs #4720 Slice G). SPEC/program/app-event-bus.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler.dart';

import 'app_event_handler_test_support.dart';

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

    testWidgets('ConfirmDialogEvent shows dialog with title and message', (
      tester,
    ) async {
      handler.bind();
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'trigger',
        onPressed: () => bus.emit(
          const ConfirmDialogEvent(title: 'Confirm', message: 'Proceed?'),
        ),
      );
      await tapAppEventHandlerLabel(tester, 'trigger');
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Proceed?'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets(
      'ConfirmDialogEvent from widget inside modal bottom sheet shows dialog',
      (tester) async {
        handler.bind();
        bool? dialogResult;
        await pumpAppEventHandlerEmitButton(
          tester,
          navigatorKey: navKey,
          label: 'open sheet',
          onPressed: () {},
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: ctx,
                  builder: (sheetCtx) => TextButton(
                    onPressed: () {
                      bus.emit(
                        ConfirmDialogEvent(
                          title: 'Sheet confirm',
                          message: 'From bottom sheet',
                          onResult: (b) => dialogResult = b,
                        ),
                      );
                    },
                    child: const Text('emit from sheet'),
                  ),
                );
              },
              child: const Text('open sheet'),
            ),
          ),
        );
        await tapAppEventHandlerLabel(tester, 'open sheet');
        await tapAppEventHandlerLabel(tester, 'emit from sheet');
        expect(find.text('Sheet confirm'), findsOneWidget);
        expect(find.text('From bottom sheet'), findsOneWidget);
        await tapAppEventHandlerLabel(tester, 'OK');
        expect(dialogResult, isTrue);
      },
    );

    testWidgets('QuickStartNewGameEvent invokes extraActionHandlers', (
      tester,
    ) async {
      var called = false;
      GlobalKey<NavigatorState>? receivedKey;
      handler.unbind();
      handler = buildTestAppEventHandler(
        bus: bus,
        navigatorKey: navKey,
        extraActionHandlers: {
          QuickStartNewGameEvent: (key) {
            called = true;
            receivedKey = key;
          },
        },
      );
      handler.bind();
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'home',
        home: const Text('home'),
        onPressed: () {},
      );
      bus.emit(const QuickStartNewGameEvent());
      await tester.pumpAndSettle();
      expect(called, isTrue);
      expect(receivedKey, navKey);
      expect(find.text('home'), findsOneWidget);
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
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'home',
        home: const Text('home'),
        onPressed: () {},
      );
      bus.emit(
        const ShowSnackBarEvent(message: 'hello snack', actionLabel: 'undo'),
      );
      await tester.pumpAndSettle();
      expect(received?.message, 'hello snack');
      expect(received?.actionLabel, 'undo');
    });
  });
}
