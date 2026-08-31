// Pin the 320 dp minimum-viewport contract for QuickBattleResultDialog,
// SplitArmy/SplitFleet/TransferToHomeFleet, and PauseMenuPanel
// (Refs #2870 S8/S10, #4352).
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).

import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/panels/pause_menu_panel.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/transfer_to_home_fleet_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show AppEventBus;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();
  group('SPEC/ui/mobile-adaptation.md § 7 — PauseMenuPanel @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    const pauseTitle = 'Game Paused';
    const resumeLabel = 'Resume';
    const saveGameLabel = 'Save Game';
    const loadGameLabel = 'Load Game';
    const settingsLabel = 'Settings';
    const exitToMainMenuLabel = 'Exit to Main Menu';

    Future<void> pumpPause(WidgetTester tester, Size size) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      await pumpDialogs320At(tester, PauseMenuPanel(bus: bus), size: size);
    }

    testWidgets(
      'AC (positive) PauseMenuPanel @ 320×640: no RenderFlex overflow '
      'exception, "Game Paused" title + five action labels render in '
      'declared order (Resume / Save Game / Load Game / Settings / Exit '
      'to Main Menu) — the SPEC/ui/pause-menu-panel.md "vertical stack '
      'of exactly five CtNinePatchButton actions" must wrap within the '
      '~288 dp CtDialogShell content column at kMinViewportWidth',
      (WidgetTester tester) async {
        await pumpPause(tester, kDialogs320MinViewport);
        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: PauseMenuPanel must not '
              'emit a RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). The "Game Paused" title + CtBrassDivider + five '
              'CtNinePatchButton rows from SPEC/ui/pause-menu-panel.md '
              '§ Layout / wireframe must wrap within the ~288 dp '
              'CtDialogShell content column — CtDialogShell `maxWidth: '
              '360` is dominated by `Dialog.insetPadding` (16 dp each '
              'side) at this viewport, leaving the same ~288 dp budget '
              'as the simpler shells pinned above this group.',
        );
        for (final label in [
          pauseTitle,
          resumeLabel,
          saveGameLabel,
          loadGameLabel,
          settingsLabel,
          exitToMainMenuLabel,
        ]) {
          expect(find.text(label), findsOneWidget);
        }
      },
    );

    testWidgets(
      'AC (positive) PauseMenuPanel @ 320×640: declared button order is '
      'preserved (Resume top, Exit to Main Menu bottom) so the narrow '
      'pin guards against a row-shuffle regression layered onto the '
      'overflow-only contract — mirrors the order assertion in '
      '`pause_menu_panel_test.dart` while exercising the 320 dp budget',
      (WidgetTester tester) async {
        await pumpPause(tester, kDialogs320MinViewport);
        expect(tester.takeException(), isNull);
        const expectedKeys = <Key>[
          PauseMenuPanel.resumeButtonKey,
          PauseMenuPanel.saveGameButtonKey,
          PauseMenuPanel.loadGameButtonKey,
          PauseMenuPanel.settingsButtonKey,
          PauseMenuPanel.exitToMainMenuButtonKey,
        ];
        for (final key in expectedKeys) {
          expect(find.byKey(key), findsOneWidget);
        }
        final resumeTopLeft = tester.getTopLeft(
          find.byKey(PauseMenuPanel.resumeButtonKey),
        );
        final exitTopLeft = tester.getTopLeft(
          find.byKey(PauseMenuPanel.exitToMainMenuButtonKey),
        );
        expect(
          resumeTopLeft.dy,
          lessThan(exitTopLeft.dy),
          reason:
              'SPEC/ui/pause-menu-panel.md § Layout / wireframe pins '
              'Resume above Exit to Main Menu in the vertical stack; '
              'the 320 dp viewport must not invert this order.',
        );
      },
    );

    testWidgets(
      'Negative control: PauseMenuPanel @ 1024×768 also pumps without '
      'exception (regression sentinel for the overflow contract — '
      'keeps the 320 dp positive pins meaningful)',
      (WidgetTester tester) async {
        await pumpPause(tester, kDialogs320WideRegressionViewport);
        expect(tester.takeException(), isNull);
        expect(find.text(pauseTitle), findsOneWidget);
        expect(find.text(resumeLabel), findsOneWidget);
        expect(find.text(exitToMainMenuLabel), findsOneWidget);
      },
    );
  });
}
