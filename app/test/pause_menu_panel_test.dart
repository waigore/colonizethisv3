import 'package:colonizethis_app/features/game/widgets/pause_menu_panel.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Widget host(AppEventBus bus) {
    return MaterialApp(
      home: Scaffold(body: PauseMenuPanel(bus: bus)),
    );
  }

  testWidgets(
    'Resume tap emits exactly one ClosePanelEvent',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <AppEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(host(bus));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(PauseMenuPanel.resumeButtonKey));
      await tester.pumpAndSettle();

      expect(events, hasLength(1));
      expect(events.single, isA<ClosePanelEvent>());
    },
  );

  testWidgets(
    'Exit to Main Menu tap emits ClosePanelEvent before '
    'RequestExitToMainMenuFlowEvent',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <AppEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(host(bus));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(PauseMenuPanel.exitToMainMenuButtonKey));
      await tester.pumpAndSettle();

      expect(events.length, greaterThanOrEqualTo(2));
      final closeIndex = events.indexWhere((e) => e is ClosePanelEvent);
      final flowIndex = events.indexWhere(
        (e) => e is RequestExitToMainMenuFlowEvent,
      );
      expect(closeIndex, isNonNegative);
      expect(flowIndex, isNonNegative);
      expect(
        closeIndex,
        lessThan(flowIndex),
        reason:
            'ClosePanelEvent must precede RequestExitToMainMenuFlowEvent.',
      );
    },
  );

  testWidgets(
    'Renders CtDialogShell + CtBrassDivider + exactly five CtNinePatchButtons '
    'in declared order',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      await tester.pumpWidget(host(bus));
      await tester.pumpAndSettle();

      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byKey(PauseMenuPanel.brassDividerKey), findsOneWidget);
      expect(find.descendant(
        of: find.byKey(PauseMenuPanel.brassDividerKey),
        matching: find.byType(CtBrassDivider),
      ), findsOneWidget);

      final buttons = tester
          .widgetList<CtNinePatchButton>(find.byType(CtNinePatchButton))
          .toList();
      expect(buttons, hasLength(5));

      const expectedOrder = <Key>[
        PauseMenuPanel.resumeButtonKey,
        PauseMenuPanel.saveGameButtonKey,
        PauseMenuPanel.loadGameButtonKey,
        PauseMenuPanel.settingsButtonKey,
        PauseMenuPanel.exitToMainMenuButtonKey,
      ];
      final actualOrder = buttons.map((b) => b.key).toList();
      expect(actualOrder, expectedOrder);
    },
  );

  testWidgets(
    'Save Game / Load Game / Settings render as disabled placeholders',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <AppEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(host(bus));
      await tester.pumpAndSettle();

      for (final key in const <Key>[
        PauseMenuPanel.saveGameButtonKey,
        PauseMenuPanel.loadGameButtonKey,
        PauseMenuPanel.settingsButtonKey,
      ]) {
        final widget = tester.widget<CtNinePatchButton>(find.byKey(key));
        expect(
          widget.enabled,
          isFalse,
          reason: '$key must render as disabled per SPEC',
        );
        expect(
          widget.onPressed,
          isNull,
          reason: '$key must have null onPressed per SPEC',
        );
      }

      // Tapping disabled placeholders is a no-op on the bus.
      await tester.tap(
        find.byKey(PauseMenuPanel.saveGameButtonKey),
        warnIfMissed: false,
      );
      await tester.tap(
        find.byKey(PauseMenuPanel.loadGameButtonKey),
        warnIfMissed: false,
      );
      await tester.tap(
        find.byKey(PauseMenuPanel.settingsButtonKey),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(events, isEmpty);
    },
  );

  testWidgets(
    'Exit to Main Menu button uses danger variant',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      await tester.pumpWidget(host(bus));
      await tester.pumpAndSettle();

      final exitButton = tester.widget<CtNinePatchButton>(
        find.byKey(PauseMenuPanel.exitToMainMenuButtonKey),
      );
      expect(exitButton.dangerVariant, isTrue);
      expect(exitButton.enabled, isTrue);
    },
  );

  testWidgets(
    'Negative AC: contains no Material ListTile / Card / AlertDialog / AppBar',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      await tester.pumpWidget(host(bus));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);
      expect(find.byType(Card), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(Divider), findsNothing);
    },
  );
}
