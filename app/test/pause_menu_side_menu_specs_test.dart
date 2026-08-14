// Pins SPEC/ui/pause-menu-panel.md (Refs #4352).

import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:colonizethis_app/features/game/widgets/panels/pause_menu_panel.dart';
import 'package:colonizethis_app/providers/turn_resolution_blocking_provider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  group('PauseMenuPanel (SPEC/ui/pause-menu-panel.md)', () {
    Widget pauseHost(AppEventBus bus, {bool blocking = false}) {
      // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
      return buildAppShell(
        overrides: [
          turnResolutionBlockingProvider.overrideWith(
            () => StateToggleNotifier(blocking),
          ),
        ],
        child: Scaffold(body: PauseMenuPanel(bus: bus)),
      );
    }

    testWidgets(
      'AC: renders title + brass divider + five action buttons in declared order',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(pauseHost(bus));
        await tester.pumpAndSettle();

        expect(find.byKey(PauseMenuPanel.titleKey), findsOneWidget);
        expect(find.byKey(PauseMenuPanel.brassDividerKey), findsOneWidget);

        final buttons = tester
            .widgetList<CtNinePatchButton>(find.byType(CtNinePatchButton))
            .toList();
        expect(buttons, hasLength(5));
        expect(buttons.map((b) => b.key).toList(), const <Key>[
          PauseMenuPanel.resumeButtonKey,
          PauseMenuPanel.saveGameButtonKey,
          PauseMenuPanel.loadGameButtonKey,
          PauseMenuPanel.settingsButtonKey,
          PauseMenuPanel.exitToMainMenuButtonKey,
        ]);
      },
    );

    testWidgets(
      'AC: Resume emits exactly one ClosePanelEvent and no other events',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <AppEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        await tester.pumpWidget(pauseHost(bus));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(PauseMenuPanel.resumeButtonKey));
        await tester.pumpAndSettle();

        expect(events, hasLength(1));
        expect(events.single, isA<ClosePanelEvent>());
        expect(
          events.whereType<NavigateToRouteEvent>(),
          isEmpty,
          reason: 'Resume must not emit NavigateToRouteEvent.',
        );
        expect(
          events.whereType<RequestExitToMainMenuFlowEvent>(),
          isEmpty,
          reason: 'Resume must not emit RequestExitToMainMenuFlowEvent.',
        );
      },
    );

    testWidgets('AC: Exit to Main Menu emits ClosePanelEvent before '
        'RequestExitToMainMenuFlowEvent', (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <AppEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(pauseHost(bus));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(PauseMenuPanel.exitToMainMenuButtonKey));
      await tester.pumpAndSettle();

      final closeIndex = events.indexWhere((e) => e is ClosePanelEvent);
      final flowIndex = events.indexWhere(
        (e) => e is RequestExitToMainMenuFlowEvent,
      );
      expect(closeIndex, isNonNegative);
      expect(flowIndex, isNonNegative);
      expect(
        closeIndex,
        lessThan(flowIndex),
        reason: 'ClosePanelEvent must precede RequestExitToMainMenuFlowEvent.',
      );
    });

    testWidgets(
      'AC: when not blocking, Save/Load/Settings are enabled and emit dialogs',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <AppEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        await tester.pumpWidget(pauseHost(bus));
        await tester.pumpAndSettle();

        final save = tester.widget<CtNinePatchButton>(
          find.byKey(PauseMenuPanel.saveGameButtonKey),
        );
        final load = tester.widget<CtNinePatchButton>(
          find.byKey(PauseMenuPanel.loadGameButtonKey),
        );
        final settings = tester.widget<CtNinePatchButton>(
          find.byKey(PauseMenuPanel.settingsButtonKey),
        );
        expect(save.enabled, isTrue);
        expect(load.enabled, isTrue);
        expect(settings.enabled, isTrue);
        expect(settings.onPressed, isNotNull);

        await tester.tap(find.byKey(PauseMenuPanel.saveGameButtonKey));
        await tester.pumpAndSettle();
        expect(
          events.whereType<OpenDialogEvent>().single.dialogId,
          'save_game_name',
        );

        events.clear();
        await tester.tap(find.byKey(PauseMenuPanel.loadGameButtonKey));
        await tester.pumpAndSettle();
        final loadEvent = events.whereType<OpenDialogEvent>().single;
        expect(loadEvent.dialogId, 'load_game_list');
        expect(loadEvent.params?['fromPause'], isTrue);

        events.clear();
        await tester.tap(find.byKey(PauseMenuPanel.settingsButtonKey));
        await tester.pumpAndSettle();
        expect(events.whereType<OpenDialogEvent>().single.dialogId, 'settings');
      },
    );

    testWidgets(
      'Negative AC: panel does not render Debug log or Material chrome',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(pauseHost(bus));
        await tester.pumpAndSettle();

        // Debug log moved to GameSideMenu per the new SPEC.
        expect(find.text('Debug log'), findsNothing);
        // Material chrome is banned by SPEC/ui/pixel-art-ui-catalog.md.
        expect(find.byType(ListTile), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(Divider), findsNothing);
        expect(find.byType(AppBar), findsNothing);
      },
    );
  });
}
