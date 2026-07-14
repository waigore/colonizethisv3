// Pin the 320 dp minimum-viewport contract for in-game modal dialogs
// that share the [CtDialogShell] chrome (Refs #2870 S8/S10).
// Split into part files under `repo.app_test_file_size` (Refs #4013).
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).

import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/panels/pause_menu_panel.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/transfer_to_home_fleet_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dialogs_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — NextTurnConfirmationDialog '
      '@ 320 dp (Refs #2870 S8/S10)', () {
    const int currentTurn = 7;

    testWidgets('AC (positive) NextTurnConfirmationDialog @ 320×640: no '
        'RenderFlex overflow exception, title + body + No + Yes render '
        '(the end-aligned No + 8 dp gap + Yes row must fit within the '
        '~288 dp CtDialogShell content column)', (WidgetTester tester) async {
      await pumpDialogs320At(
        tester,
        const NextTurnConfirmationDialog(currentTurn: currentTurn),
        size: kDialogs320MinViewport,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: NextTurnConfirmationDialog '
            'must not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The title + body + end-aligned '
            'No / Yes CtNinePatchButton row from '
            'SPEC/ui/next-turn-confirmation.md must wrap within the '
            '~288 dp CtDialogShell content column.',
      );
      expect(find.text('End turn?'), findsOneWidget);
      expect(find.textContaining('Turn 7 will end'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
    });

    testWidgets('Negative control: NextTurnConfirmationDialog @ 1024×768 '
        'also pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        const NextTurnConfirmationDialog(currentTurn: currentTurn),
        size: kDialogs320WideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('End turn?'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — QuickBattleResultDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    const QuickBattleResult attackerWinsFlips = QuickBattleResult(
      winner: QuickBattleWinner.attacker,
      attackerCasualties: ['a3'],
      defenderCasualties: ['d1', 'd2'],
      provinceFlips: true,
    );

    testWidgets(
      'AC (positive) QuickBattleResultDialog (attacker wins, provinceFlips) '
      '@ 320×640: no RenderFlex overflow exception, winner + captured banner '
      '+ casualty rows + OK render (the title + optional captured line + two '
      'casualty bodySmall rows + trailing OK must fit within the ~288 dp '
      'CtDialogShell content column)',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          const QuickBattleResultDialog(
            result: attackerWinsFlips,
            attackerName: 'Castile',
            defenderName: 'England',
          ),
          size: kDialogs320MinViewport,
        );

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
        const QuickBattleResultDialog(
          result: attackerWinsFlips,
          attackerName: 'Castile',
          defenderName: 'England',
        ),
        size: kDialogs320WideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Castile'), findsWidgets);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — SplitArmyDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    // Minimal Game fixture: one human GP, one province in oldWorld owned by
    // the human, one in-province levy regiment. Mirrors the fixture shape
    // used by `split_army_dialog_test.dart` so the narrow pin exercises the
    // same `CtTransferList` layout path that ships in production.
    Game gameWithOneRegimentArmy() {
      const province = Province(
        id: 'cap',
        regionId: 'oldWorld',
        displayName: 'Lisbon',
      );
      final unit = Unit(
        id: 'levy_1',
        type: 'peasant_levy',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|cap',
      );
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: const [province], units: [unit]),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
    }

    final Army oneLevyArmy = Army(
      id: 'army_1',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      stationedProvinceId: 'oldWorld|cap',
      regimentUnitIds: const ['levy_1'],
    );

    testWidgets(
      'AC (positive) SplitArmyDialog (non-home) @ 320×640: no RenderFlex '
      'overflow exception, "Split Army" title + "Confirm Split" action + '
      'transfer-list left/right column titles render',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          SplitArmyDialog(
            army: oneLevyArmy,
            game: gameWithOneRegimentArmy(),
            humanPlayerId: 'gp1',
            bus: AppEventBus.create(),
            isHomeArmy: false,
          ),
          size: kDialogs320MinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
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
        );
        expect(find.text('Split Army'), findsOneWidget);
        expect(find.text('Confirm Split'), findsOneWidget);
        // CtTransferList column titles surface so the dialog body is
        // actually exercised at the narrow size (vs an empty no-op).
        expect(find.text('Army army_1'), findsOneWidget);
        expect(find.text('New Army'), findsOneWidget);
      },
    );

    testWidgets('Negative control: SplitArmyDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow contract — '
        'keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        SplitArmyDialog(
          army: oneLevyArmy,
          game: gameWithOneRegimentArmy(),
          humanPlayerId: 'gp1',
          bus: AppEventBus.create(),
          isHomeArmy: false,
        ),
        size: kDialogs320WideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Split Army'), findsOneWidget);
      expect(find.text('Confirm Split'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — SplitFleetDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    // Minimal Game fixture: one human GP, one sea-zone display name so the
    // dialog's `_fleetLocationLabel()` resolves to a non-"Unknown" string,
    // and no provinces (the at-sea fleet does not need one). Mirrors the
    // at-sea fixture used by `split_fleet_dialog_test.dart`.
    Game minimalSeaZoneGame() {
      return Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(),
          newWorld: RegionData(),
          seaZoneDisplayNameById: {'oldWorld|s1': 'Adriatic Display'},
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
    }

    final Fleet oneCarrackAtSea = Fleet(
      id: 'f_split',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 's1',
      shipTypeIds: const ['carrack'],
    );

    testWidgets(
      'AC (positive) SplitFleetDialog (non-home) @ 320×640: no RenderFlex '
      'overflow exception, "Split Fleet" title + "Confirm Split" action + '
      'New Fleet right-column title render',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          SplitFleetDialog(
            originalFleet: oneCarrackAtSea,
            game: minimalSeaZoneGame(),
            humanPlayerId: 'gp1',
            bus: AppEventBus.create(),
            isHomeFleet: false,
          ),
          size: kDialogs320MinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: SplitFleetDialog must not '
              'emit a RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). The "Split Fleet" title + side-by-side '
              'CtTransferList columns ("Fleet <id>" + "New Fleet") with '
              'shared 220 dp list height, the +/- move controls, and the '
              'trailing Cancel / Confirm Split row must all fit within '
              'the ~288 dp CtDialogShell content column at 320 dp — '
              'CtDialogShell `maxWidth: 520` is dominated by '
              '`Dialog.insetPadding` at this viewport.',
        );
        expect(find.text('Split Fleet'), findsOneWidget);
        expect(find.text('Confirm Split'), findsOneWidget);
        // CtTransferList "New Fleet" right-column title surfaces so the
        // dialog body is actually exercised at the narrow size.
        expect(find.text('New Fleet'), findsOneWidget);
      },
    );

    testWidgets('Negative control: SplitFleetDialog @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow contract — '
        'keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        SplitFleetDialog(
          originalFleet: oneCarrackAtSea,
          game: minimalSeaZoneGame(),
          humanPlayerId: 'gp1',
          bus: AppEventBus.create(),
          isHomeFleet: false,
        ),
        size: kDialogs320WideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Split Fleet'), findsOneWidget);
      expect(find.text('Confirm Split'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — TransferToHomeFleetDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    // Minimal Game fixture: one human GP, one capital province (Lisbon) for
    // the in-port home fleet, and one sea-zone display name so the source
    // fleet's at-sea location label resolves to a non-"Unknown" string.
    Game gameWithCapitalAndSeaZone() {
      const capital = Province(
        id: 'cap',
        regionId: 'oldWorld',
        displayName: 'Lisbon',
      );
      return Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [capital]),
          newWorld: RegionData(),
          seaZoneDisplayNameById: {'oldWorld|s1': 'Adriatic'},
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
      );
    }

    final Fleet sourceFleetAtSea = Fleet(
      id: 'f_src',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 's1',
      shipTypeIds: const ['carrack'],
    );

    final Fleet homeFleetInPort = Fleet(
      id: 'home_fleet',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      inPortAtProvinceId: 'oldWorld|cap',
      shipTypeIds: const ['carrack'],
    );

    testWidgets(
      'AC (positive) TransferToHomeFleetDialog @ 320×640: no RenderFlex '
      'overflow exception, dialog title + "Home Fleet" right column + '
      '"Transfer" action render',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          TransferToHomeFleetDialog(
            sourceFleet: sourceFleetAtSea,
            homeFleet: homeFleetInPort,
            game: gameWithCapitalAndSeaZone(),
            humanPlayerId: 'gp1',
            bus: AppEventBus.create(),
          ),
          size: kDialogs320MinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: TransferToHomeFleetDialog '
              'must not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The title row + side-by-side '
              'CtTransferList columns ("Fleet <id>" + "Home Fleet") with '
              'shared 240 dp list height, the +/- move controls, and the '
              'trailing Cancel / Transfer action row must all fit within '
              'the ~288 dp CtDialogShell content column at 320 dp — '
              'CtDialogShell `maxWidth: 560` is dominated by '
              '`Dialog.insetPadding` at this viewport.',
        );
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
        expect(find.text('Transfer'), findsOneWidget);
        // Home Fleet right-column title surfaces so the dialog body is
        // actually exercised at the narrow size.
        expect(find.text('Home Fleet'), findsOneWidget);
      },
    );

    testWidgets('Negative control: TransferToHomeFleetDialog @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        TransferToHomeFleetDialog(
          sourceFleet: sourceFleetAtSea,
          homeFleet: homeFleetInPort,
          game: gameWithCapitalAndSeaZone(),
          humanPlayerId: 'gp1',
          bus: AppEventBus.create(),
        ),
        size: kDialogs320WideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — PauseMenuPanel @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    // Localized label sentinels mirror the canonical English values from
    // `app/lib/l10n/arb/app_en.arb` (`game_pauseMenu_*` keys) so the pin
    // breaks if those strings change without the SPEC + this contract
    // being refreshed in lockstep. The l10n-resolved order is the same
    // five rows declared by `pause_menu_panel.dart` (Resume → Save Game
    // → Load Game → Settings → Exit to Main Menu).
    const String pauseTitle = 'Game Paused';
    const String resumeLabel = 'Resume';
    const String saveGameLabel = 'Save Game';
    const String loadGameLabel = 'Load Game';
    const String settingsLabel = 'Settings';
    const String exitToMainMenuLabel = 'Exit to Main Menu';

    testWidgets(
      'AC (positive) PauseMenuPanel @ 320×640: no RenderFlex overflow '
      'exception, "Game Paused" title + five action labels render in '
      'declared order (Resume / Save Game / Load Game / Settings / Exit '
      'to Main Menu) — the SPEC/ui/pause-menu-panel.md "vertical stack '
      'of exactly five CtNinePatchButton actions" must wrap within the '
      '~288 dp CtDialogShell content column at kMinViewportWidth',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await pumpDialogs320At(
          tester,
          PauseMenuPanel(bus: bus),
          size: kDialogs320MinViewport,
        );

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
        expect(find.text(pauseTitle), findsOneWidget);
        expect(find.text(resumeLabel), findsOneWidget);
        expect(find.text(saveGameLabel), findsOneWidget);
        expect(find.text(loadGameLabel), findsOneWidget);
        expect(find.text(settingsLabel), findsOneWidget);
        expect(find.text(exitToMainMenuLabel), findsOneWidget);
      },
    );

    testWidgets(
      'AC (positive) PauseMenuPanel @ 320×640: declared button order is '
      'preserved (Resume top, Exit to Main Menu bottom) so the narrow '
      'pin guards against a row-shuffle regression layered onto the '
      'overflow-only contract — mirrors the order assertion in '
      '`pause_menu_panel_test.dart` while exercising the 320 dp budget',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await pumpDialogs320At(
          tester,
          PauseMenuPanel(bus: bus),
          size: kDialogs320MinViewport,
        );

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
        // Top-to-bottom ordering: Resume's top edge is strictly above
        // Exit to Main Menu's top edge after the narrow layout resolves.
        final Offset resumeTopLeft = tester.getTopLeft(
          find.byKey(PauseMenuPanel.resumeButtonKey),
        );
        final Offset exitTopLeft = tester.getTopLeft(
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
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await pumpDialogs320At(
          tester,
          PauseMenuPanel(bus: bus),
          size: kDialogs320WideRegressionViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(pauseTitle), findsOneWidget);
        expect(find.text(resumeLabel), findsOneWidget);
        expect(find.text(exitToMainMenuLabel), findsOneWidget);
      },
    );
  });
}
