// Tests for AppEventHandler. SPEC/program/app-event-bus.md (architecture).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler.dart';
import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_result_dialog.dart';
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

      // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
      // RoutePaths.shell is '/' — MaterialApp.home is the shell route name.
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

    testWidgets(
      'CombatModeChoiceDialog opened via OpenDialog emits CombatModeChosenEvent',
      (tester) async {
        handler = AppEventHandler(
          bus: bus,
          navigatorKey: navKey,
          dialogBuilders: {
            'combat_mode_choice': (ctx, params) => CombatModeChoiceDialog(
              bus: bus,
              provinceName: params?['provinceName'] as String? ?? '',
              isCapitalSiege: params?['isCapitalSiege'] as bool? ?? false,
            ),
          },
        );
        handler.bind();
        CombatModeChosenEvent? chosen;
        bus.on<CombatModeChosenEvent>().listen((e) => chosen = e);
        await pumpAppEventHandlerEmitButton(
          tester,
          navigatorKey: navKey,
          label: 'open',
          onPressed: () => bus.emit(
            const OpenDialogEvent('combat_mode_choice', {
              'provinceName': 'TestProv',
              'isCapitalSiege': false,
            }),
          ),
        );
        await tapAppEventHandlerLabel(tester, 'open');
        await tapAppEventHandlerLabel(tester, 'Quick Battle');
        expect(chosen?.mode, CombatMode.quickBattle);
        expect(find.text('Combat at TestProv'), findsNothing);
      },
    );

    testWidgets('OpenDialogEvent quick_battle_result shows dialog', (
      tester,
    ) async {
      handler = AppEventHandler(
        bus: bus,
        navigatorKey: navKey,
        dialogBuilders: {
          'quick_battle_result': (ctx, params) => QuickBattleResultDialog(
            result: params!['result'] as QuickBattleResult,
            attackerName: 'A',
            defenderName: 'D',
          ),
        },
      );
      handler.bind();
      final qb = QuickBattleResult(
        winner: QuickBattleWinner.attacker,
        attackerCasualties: const [],
        defenderCasualties: const [],
        provinceFlips: false,
      );
      await pumpAppEventHandlerEmitButton(
        tester,
        navigatorKey: navKey,
        label: 'open',
        onPressed: () =>
            bus.emit(OpenDialogEvent('quick_battle_result', {'result': qb})),
      );
      await tapAppEventHandlerLabel(tester, 'open');
      expect(find.textContaining('Battle Result'), findsOneWidget);
      expect(find.textContaining('A wins'), findsOneWidget);
    });
  });
}
