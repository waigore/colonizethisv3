// Pin the 320 dp minimum-viewport contract for in-game modal dialogs
// that share the [CtDialogShell] chrome (Refs #2870 S8/S10).
// Split into part files under `repo.app_test_file_size` (Refs #4013).
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).

import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/game/turn_resolution/civilians_missing_work_orders.dart';
import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/panels/pause_menu_panel.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/transfer_to_home_fleet_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';

const _gp1 = 'gp1';

const _attackerWinsFlips = QuickBattleResult(
  winner: QuickBattleWinner.attacker,
  attackerCasualties: ['a3'],
  defenderCasualties: ['d1', 'd2'],
  provinceFlips: true,
);

const _oneLevyArmy = Army(
  id: 'army_1',
  ownerId: _gp1,
  regionId: 'oldWorld',
  stationedProvinceId: 'oldWorld|cap',
  regimentUnitIds: ['levy_1'],
);

final _oneCarrackAtSea = Fleet(
  id: 'f_split',
  ownerId: _gp1,
  regionId: 'oldWorld',
  seaZoneId: 's1',
  shipTypeIds: const ['carrack'],
);

final _sourceFleetAtSea = Fleet(
  id: 'f_src',
  ownerId: _gp1,
  regionId: 'oldWorld',
  seaZoneId: 's1',
  shipTypeIds: const ['carrack'],
);

final _homeFleetInPort = Fleet(
  id: 'home_fleet',
  ownerId: _gp1,
  regionId: 'oldWorld',
  inPortAtProvinceId: 'oldWorld|cap',
  shipTypeIds: const ['carrack'],
);

Game _ordersGame({
  List<Province> oldWorldProvinces = const [],
  List<Unit> oldWorldUnits = const [],
  Map<String, String> seaZoneDisplayNameById = const {},
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(provinces: oldWorldProvinces, units: oldWorldUnits),
      newWorld: const RegionData(),
      seaZoneDisplayNameById: seaZoneDisplayNameById,
    ),
    players: const [
      Player(id: _gp1, displayName: 'Human', isHuman: true, treasury: 0),
    ],
  );
}

Game _gameWithOneRegimentArmy() => _ordersGame(
      oldWorldProvinces: const [
        Province(id: 'cap', regionId: 'oldWorld', displayName: 'Lisbon'),
      ],
      oldWorldUnits: [
        Unit(
          id: 'levy_1',
          type: 'peasant_levy',
          ownerId: _gp1,
          locationProvinceId: 'oldWorld|cap',
        ),
      ],
    );

Game _minimalSeaZoneGame() => _ordersGame(
      seaZoneDisplayNameById: const {'oldWorld|s1': 'Adriatic Display'},
    );

Game _gameWithCapitalAndSeaZone() => _ordersGame(
      oldWorldProvinces: const [
        Province(id: 'cap', regionId: 'oldWorld', displayName: 'Lisbon'),
      ],
      seaZoneDisplayNameById: const {'oldWorld|s1': 'Adriatic'},
    );

Future<void> _pinDialog(
  WidgetTester tester,
  Widget dialog, {
  required Size size,
  String? overflowReason,
  required List<Finder> expectFinders,
}) async {
  await pumpDialogs320At(tester, dialog, size: size);
  expect(tester.takeException(), isNull, reason: overflowReason);
  for (final finder in expectFinders) {
    expect(finder, findsOneWidget);
  }
}

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — NextTurnConfirmationDialog '
      '@ 320 dp (Refs #2870 S8/S10)', () {
    const currentTurn = 7;
    const dialog = NextTurnConfirmationDialog(currentTurn: currentTurn);
    final content = [
      find.text('End turn?'),
      find.text('No'),
      find.text('Yes'),
    ];

    testWidgets('AC (positive) NextTurnConfirmationDialog @ 320×640: no '
        'RenderFlex overflow exception, title + body + No + Yes render '
        '(the end-aligned No + 8 dp gap + Yes row must fit within the '
        '~288 dp CtDialogShell content column)', (WidgetTester tester) async {
      await _pinDialog(
        tester,
        dialog,
        size: kDialogs320MinViewport,
        overflowReason:
            'SPEC/ui/mobile-adaptation.md § 7: NextTurnConfirmationDialog '
            'must not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The title + body + end-aligned '
            'No / Yes CtNinePatchButton row from '
            'SPEC/ui/next-turn-confirmation.md must wrap within the '
            '~288 dp CtDialogShell content column.',
        expectFinders: [...content, find.textContaining('Turn 7 will end')],
      );
    });

    testWidgets('Negative control: NextTurnConfirmationDialog @ 1024×768 '
        'also pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await _pinDialog(
        tester,
        dialog,
        size: kDialogs320WideRegressionViewport,
        expectFinders: content,
      );
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — NextTurnConfirmationDialog '
      'warning variant @ 320 dp (Refs #4140)', () {
    const severalCivilians = [
      CivilianMissingWorkOrderEntry(
        unitId: 'e1',
        type: 'explorer',
        tileKey: 'oldWorld|p1|0|0',
        regionId: 'oldWorld',
        locationLabel: 'Old World — Alpha Province',
      ),
      CivilianMissingWorkOrderEntry(
        unitId: 'b1',
        type: 'builder',
        tileKey: 'oldWorld|p2|1|0',
        regionId: 'oldWorld',
        locationLabel: 'Old World — Beta Province',
      ),
      CivilianMissingWorkOrderEntry(
        unitId: 's1',
        type: 'spy',
        tileKey: 'newWorld|p3|2|1',
        regionId: 'newWorld',
        locationLabel: 'New World — Gamma Province',
      ),
    ];

    const warningDialog = NextTurnConfirmationDialog(
      currentTurn: 12,
      civiliansMissingWork: severalCivilians,
    );

    testWidgets('AC (positive) warning variant with several civilians @ '
        '320×640: no RenderFlex overflow; Yes/No remain visible', (
      WidgetTester tester,
    ) async {
      await _pinDialog(
        tester,
        warningDialog,
        size: kDialogs320MinViewport,
        overflowReason:
            'SPEC/ui/next-turn-confirmation.md + mobile-adaptation § 7: '
            'the idle-civilian warning variant must not overflow horizontally '
            'at kMinViewportWidth (320 dp) when several rows are listed.',
        expectFinders: [
          find.text('End turn?'),
          find.text('No'),
          find.text('Yes'),
          find.text(
            'These civilians have no work order for the next turn:',
          ),
        ],
      );
      expect(find.text('explorer'), findsOneWidget);
      expect(find.text('builder'), findsOneWidget);
      expect(find.text('spy'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — QuickBattleResultDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    const dialog = QuickBattleResultDialog(
      result: _attackerWinsFlips,
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
        await pumpDialogs320At(
          tester,
          dialog,
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
          army: _oneLevyArmy,
          game: _gameWithOneRegimentArmy(),
          humanPlayerId: _gp1,
          bus: AppEventBus.create(),
          isHomeArmy: false,
        );

    testWidgets(
      'AC (positive) SplitArmyDialog (non-home) @ 320×640: no RenderFlex '
      'overflow exception, "Split Army" title + "Confirm Split" action + '
      'transfer-list left/right column titles render',
      (WidgetTester tester) async {
        await _pinDialog(
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
      await _pinDialog(
        tester,
        splitArmy(),
        size: kDialogs320WideRegressionViewport,
        expectFinders: [
          find.text('Split Army'),
          find.text('Confirm Split'),
        ],
      );
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — SplitFleetDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    Widget splitFleet() => SplitFleetDialog(
          originalFleet: _oneCarrackAtSea,
          game: _minimalSeaZoneGame(),
          humanPlayerId: _gp1,
          bus: AppEventBus.create(),
          isHomeFleet: false,
        );

    testWidgets(
      'AC (positive) SplitFleetDialog (non-home) @ 320×640: no RenderFlex '
      'overflow exception, "Split Fleet" title + "Confirm Split" action + '
      'New Fleet right-column title render',
      (WidgetTester tester) async {
        await _pinDialog(
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
      await _pinDialog(
        tester,
        splitFleet(),
        size: kDialogs320WideRegressionViewport,
        expectFinders: [
          find.text('Split Fleet'),
          find.text('Confirm Split'),
        ],
      );
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — TransferToHomeFleetDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    Widget transferHome() => TransferToHomeFleetDialog(
          sourceFleet: _sourceFleetAtSea,
          homeFleet: _homeFleetInPort,
          game: _gameWithCapitalAndSeaZone(),
          humanPlayerId: _gp1,
          bus: AppEventBus.create(),
        );

    testWidgets(
      'AC (positive) TransferToHomeFleetDialog @ 320×640: no RenderFlex '
      'overflow exception, dialog title + "Home Fleet" right column + '
      '"Transfer" action render',
      (WidgetTester tester) async {
        await _pinDialog(
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
      await _pinDialog(
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
