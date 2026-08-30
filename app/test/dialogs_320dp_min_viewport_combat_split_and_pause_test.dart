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

  group('SPEC/ui/mobile-adaptation.md § 7 — QuickBattleResultDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    const dialog = QuickBattleResultDialog(
      result: dialogs320AttackerWinsFlips,
      attackerName: 'Castile',
      defenderName: 'England',
    );

    testWidgets(
      'AC (positive) QuickBattleResultDialog (attacker wins, provinceFlips) '
      '@ 320×640: no RenderFlex overflow exception, winner + captured banner '
      '+ casualty rows + OK render (the title + optional captured line + two '
      'casualty bodySmall rows + trailing OK must fit within the ~288 dp '
      'CtDialogShell content column)',
      (WidgetTester tester) async {
        await pumpDialogs320At(tester, dialog, size: kDialogs320MinViewport);
        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: QuickBattleResultDialog '
              '(attacker wins + provinceFlips) must not emit a RenderFlex '
              'overflow exception at kMinViewportWidth (320 dp). The winner '
              'title, captured banner, casualty rows, and trailing OK action '
              'from SPEC/ui/quick-battle-result-dialog.md must wrap within '
              'the ~288 dp CtDialogShell content column.',
        );
        expect(find.textContaining('Castile'), findsWidgets);
        expect(find.textContaining('England'), findsWidgets);
        expect(find.textContaining('captured'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
      },
    );

    testWidgets('Negative control: QuickBattleResultDialog @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        dialog,
        size: kDialogs320WideRegressionViewport,
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Castile'), findsWidgets);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — SplitArmyDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    Widget splitArmy() => SplitArmyDialog(
      army: dialogs320OneLevyArmy,
      game: dialogs320GameWithOneRegimentArmy(),
      humanPlayerId: dialogs320Gp1,
      bus: AppEventBus.create(),
      isHomeArmy: false,
    );

    testWidgets(
      'AC (positive) SplitArmyDialog (non-home) @ 320×640: no RenderFlex '
      'overflow exception, "Split Army" title + "Confirm Split" action + '
      'transfer-list left/right column titles render',
      (WidgetTester tester) async {
        await pinDialogs320At(
          tester,
          splitArmy(),
          size: kDialogs320MinViewport,
          overflowReason:
              'SPEC/ui/mobile-adaptation.md § 7: SplitArmyDialog must not '
              'emit a RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). The "Split Army" title + side-by-side '
              'CtTransferList columns ("Army <id>" + "New Army") with '
              'shared 220 dp list height, the +/- move controls, and the '
              'trailing Cancel / Confirm Split row must all fit within '
              'the ~288 dp CtDialogShell content column at 320 dp — '
              'CtDialogShell `maxWidth: 520` does not take effect at this '
              'viewport because `Dialog.insetPadding` (16 dp each side) '
              'dominates, leaving the same ~288 dp budget as the simpler '
              'shells pinned above this group.',
          expectFinders: [
            find.text('Split Army'),
            find.text('Confirm Split'),
            find.text('Army army_1'),
            find.text('New Army'),
          ],
        );
      },
    );

    testWidgets('Negative control: SplitArmyDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow contract — '
        'keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pinDialogs320At(
        tester,
        splitArmy(),
        size: kDialogs320WideRegressionViewport,
        expectFinders: [find.text('Split Army'), find.text('Confirm Split')],
      );
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — SplitFleetDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    Widget splitFleet() => SplitFleetDialog(
      originalFleet: dialogs320OneCarrackAtSea,
      game: dialogs320MinimalSeaZoneGame(),
      humanPlayerId: dialogs320Gp1,
      bus: AppEventBus.create(),
      isHomeFleet: false,
    );

    testWidgets(
      'AC (positive) SplitFleetDialog (non-home) @ 320×640: no RenderFlex '
      'overflow exception, "Split Fleet" title + "Confirm Split" action + '
      'New Fleet right-column title render',
      (WidgetTester tester) async {
        await pinDialogs320At(
          tester,
          splitFleet(),
          size: kDialogs320MinViewport,
          overflowReason:
              'SPEC/ui/mobile-adaptation.md § 7: SplitFleetDialog must not '
              'emit a RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). The "Split Fleet" title + side-by-side '
              'CtTransferList columns ("Fleet <id>" + "New Fleet") with '
              'shared 220 dp list height, the +/- move controls, and the '
              'trailing Cancel / Confirm Split row must all fit within '
              'the ~288 dp CtDialogShell content column at 320 dp — '
              'CtDialogShell `maxWidth: 520` is dominated by '
              '`Dialog.insetPadding` at this viewport.',
          expectFinders: [
            find.text('Split Fleet'),
            find.text('Confirm Split'),
            find.text('New Fleet'),
          ],
        );
      },
    );

    testWidgets('Negative control: SplitFleetDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow contract — '
        'keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pinDialogs320At(
        tester,
        splitFleet(),
        size: kDialogs320WideRegressionViewport,
        expectFinders: [find.text('Split Fleet'), find.text('Confirm Split')],
      );
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — TransferToHomeFleetDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    Widget transferHome() => TransferToHomeFleetDialog(
      sourceFleet: dialogs320SourceFleetAtSea,
      homeFleet: dialogs320HomeFleetInPort,
      game: dialogs320GameWithCapitalAndSeaZone(),
      humanPlayerId: dialogs320Gp1,
      bus: AppEventBus.create(),
    );

    testWidgets(
      'AC (positive) TransferToHomeFleetDialog @ 320×640: no RenderFlex '
      'overflow exception, dialog title + "Home Fleet" right column + '
      '"Transfer" action render',
      (WidgetTester tester) async {
        await pinDialogs320At(
          tester,
          transferHome(),
          size: kDialogs320MinViewport,
          overflowReason:
              'SPEC/ui/mobile-adaptation.md § 7: TransferToHomeFleetDialog '
              'must not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The title row + side-by-side '
              'CtTransferList columns ("Fleet <id>" + "Home Fleet") with '
              'shared 240 dp list height, the +/- move controls, and the '
              'trailing Cancel / Transfer action row must all fit within '
              'the ~288 dp CtDialogShell content column at 320 dp — '
              'CtDialogShell `maxWidth: 560` is dominated by '
              '`Dialog.insetPadding` at this viewport.',
          expectFinders: [
            find.text('Transfer Ships to Home Fleet'),
            find.text('Transfer'),
            find.text('Home Fleet'),
          ],
        );
      },
    );

    testWidgets('Negative control: TransferToHomeFleetDialog @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pinDialogs320At(
        tester,
        transferHome(),
        size: kDialogs320WideRegressionViewport,
        expectFinders: [
          find.text('Transfer Ships to Home Fleet'),
          find.text('Transfer'),
        ],
      );
    });
  });

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
