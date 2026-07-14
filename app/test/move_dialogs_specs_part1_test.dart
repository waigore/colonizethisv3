// Pins SPEC/ui movement dialog contracts (part 1):
// - SPEC/ui/move-army-dialog.md
// Split under repo.app_test_file_size (Refs #4013).

import 'dart:async';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart'
    show editorialMonocleDisplayFontFamily;
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';

import 'support/move_dialogs_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  group('MoveArmyDialog (SPEC/ui/move-army-dialog.md)', () {
    const playerId = 'gp_specs_army';
    const otherFactionId = 'gp_specs_rival';
    const from = 'oldWorld|p_from';
    const playerDest = 'oldWorld|p_owned';
    const invasionDest = 'oldWorld|p_invade';

    MapTopology buildTopology() {
      return const MapTopology(
        nodes: [
          TopologyNode(
            id: from,
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: playerDest,
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: invasionDest,
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [
          TopologyEdge(id1: from, id2: playerDest),
          TopologyEdge(id1: from, id2: invasionDest),
        ],
      );
    }

    Game buildGame() {
      return Game(
        id: 'g_specs_army',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: from,
                regionId: 'oldWorld',
                ownerId: playerId,
                displayName: 'Origin',
              ),
              Province(
                id: playerDest,
                regionId: 'oldWorld',
                ownerId: playerId,
                displayName: 'Owned Dest',
              ),
              Province(
                id: invasionDest,
                regionId: 'oldWorld',
                ownerId: otherFactionId,
                displayName: 'Invade Dest',
              ),
            ],
            units: [
              Unit(
                id: 'u_specs',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: from,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: const [
            Army(
              id: 'aspecs',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: from,
              regimentUnitIds: ['u_specs'],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              from: ['oldWorld|p_from|0|0'],
              playerDest: ['oldWorld|p_owned|0|0'],
              invasionDest: ['oldWorld|p_invade|0|0'],
            },
          },
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|p_from|0|0': 'fullyVisible',
              'oldWorld|p_owned|0|0': 'fullyVisible',
              'oldWorld|p_invade|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(
            id: playerId,
            displayName: 'Specs Player',
            isHuman: true,
            capitalProvinceId: from,
          ),
          Player(
            id: otherFactionId,
            displayName: 'Specs Rival',
            isHuman: false,
            capitalProvinceId: invasionDest,
          ),
        ],
      );
    }

    Future<void> pumpDialog(
      WidgetTester tester, {
      required AppEventBus bus,
    }) async {
      final game = buildGame();
      final topology = buildTopology();
      final army = game.worldState.armies.first;
      await tester.pumpWidget(
        moveDialogsSpecsFrameWithOpener(
          (context) => () {
            showDialog<void>(
              context: context,
              builder: (_) => MoveArmyDialog(
                army: army,
                game: game,
                humanPlayerId: playerId,
                bus: bus,
                topology: topology,
                draftOrders: const Orders(),
              ),
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    (
      AppEventBus bus,
      ArmyMoveRequestedEvent? Function() getCaptured,
      StreamSubscription<ArmyMoveRequestedEvent> sub,
    )
    subscribeArmyMoveRequested() {
      ArmyMoveRequestedEvent? captured;
      final bus = AppEventBus.create();
      final sub = bus.on<ArmyMoveRequestedEvent>().listen((e) {
        captured = e;
      });
      return (bus, () => captured, sub);
    }

    Future<void> openInvasionWarConfirm(
      WidgetTester tester,
      AppEventBus bus,
    ) async {
      await pumpDialog(tester, bus: bus);
      await tester.tap(find.text('Invade Dest'));
      await tester.pump();
      await tester.tap(find.widgetWithText(CtNinePatchButton, 'Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Declare war?'), findsOneWidget);
    }

    Future<TextStyle?> invasionDeclareWarTriggerStyle(
      WidgetTester tester,
    ) async {
      await pumpDialog(tester, bus: AppEventBus.create());
      final triggerFinder = find.text('declare war on Specs Rival');
      expect(triggerFinder, findsOneWidget);
      return tester.widget<Text>(triggerFinder).style;
    }

    Finder warConfirmSubShell() {
      return find.ancestor(
        of: find.text('Declare war?'),
        matching: find.byType(CtDialogShell),
      );
    }

    testWidgets(
      'renders CtDialogShell with section labels and no Material dropdown (Refs #2867 S1)',
      (WidgetTester tester) async {
        await pumpDialog(tester, bus: AppEventBus.create());
        expect(find.byType(MoveArmyDialog), findsOneWidget);
        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.byType(CtSectionLabel), findsAtLeastNWidgets(2));
        expect(find.text('YOUR PROVINCES'), findsOneWidget);
        expect(find.text('INVASION TARGETS'), findsOneWidget);
        expect(find.textContaining('Move army — Army aspecs'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        expect(
          find.descendant(
            of: find.byType(CtDialogShell),
            matching: find.byType(AlertDialog),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'confirm on owned destination emits ArmyMoveRequestedEvent without declareWar',
      (WidgetTester tester) async {
        final (bus, getCaptured, sub) = subscribeArmyMoveRequested();
        addTearDown(sub.cancel);

        await pumpDialog(tester, bus: bus);
        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Confirm'));
        await tester.pumpAndSettle();

        final captured = getCaptured();
        expect(captured, isNotNull);
        expect(captured!.humanPlayerId, playerId);
        expect(captured.moveOrder.armyId, 'aspecs');
        expect(captured.declareWarTargetFactionId, isNull);
        expect(find.byType(MoveArmyDialog), findsNothing);
      },
    );

    testWidgets(
      'invasion row shows declare-war trigger in danger italic (Refs #2867 R8)',
      (WidgetTester tester) async {
        final style = await invasionDeclareWarTriggerStyle(tester);
        expect(
          style?.color,
          equals(EditorialMonoclePalette.danger),
          reason:
              'R8 requires the trigger label color to resolve to '
              '--danger (EditorialMonoclePalette.danger).',
        );
        expect(
          style?.fontStyle,
          equals(FontStyle.italic),
          reason:
              'R8 requires the trigger label to render in italic body '
              'style so a serif italic glyph fires.',
        );
        expect(
          style?.fontWeight,
          equals(FontWeight.w600),
          reason:
              'R8 requires the trigger label to render at semi-bold '
              'weight (w600) so the danger emphasis reads against a busy row.',
        );
      },
    );

    testWidgets(
      'invasion row trigger label does NOT pin the editorial-monocle display font (Refs #2867 R8 negative)',
      (WidgetTester tester) async {
        final style = await invasionDeclareWarTriggerStyle(tester);
        // R8: Cinzel has no italic variant; pinning display font regresses emphasis.
        expect(
          style?.fontFamily,
          isNot(equals(editorialMonocleDisplayFontFamily)),
          reason:
              'R8 forbids the trigger label from being pinned to the '
              'editorial-monocle display font ($editorialMonocleDisplayFontFamily) '
              'because that family has no italic variant; the label must '
              'inherit the body font stack so italic glyphs render.',
        );
      },
    );

    testWidgets(
      'confirm on invasion destination then declare-war confirm carries declareWarTargetFactionId',
      (WidgetTester tester) async {
        final (bus, getCaptured, sub) = subscribeArmyMoveRequested();
        addTearDown(sub.cancel);

        await openInvasionWarConfirm(tester, bus);
        await tester.tap(find.text('Declare war and move'));
        await tester.pumpAndSettle();

        final captured = getCaptured();
        expect(captured, isNotNull);
        expect(captured!.declareWarTargetFactionId, otherFactionId);
        expect(captured.moveOrder.destinationProvinceId, invasionDest);
      },
    );

    testWidgets(
      'cancel on invasion confirmation aborts emit and keeps dialog mounted',
      (WidgetTester tester) async {
        final (bus, getCaptured, sub) = subscribeArmyMoveRequested();
        addTearDown(sub.cancel);

        await openInvasionWarConfirm(tester, bus);
        await tester.tap(
          find.descendant(
            of: warConfirmSubShell(),
            matching: find.widgetWithText(CtNinePatchButton, 'Cancel'),
          ),
        );
        await tester.pumpAndSettle();

        expect(getCaptured(), isNull);
        expect(find.byType(MoveArmyDialog), findsOneWidget);
      },
    );

    testWidgets(
      'war-confirmation sub-dialog renders inside CtDialogShell with --danger 1px border (Refs #2867 R9)',
      (WidgetTester tester) async {
        await openInvasionWarConfirm(tester, AppEventBus.create());

        expect(find.byType(CtDialogShell), findsWidgets);
        final CtDialogShell shell = tester.widget<CtDialogShell>(
          find.byType(CtDialogShell).last,
        );
        expect(shell.borderColor, EditorialMonoclePalette.danger);
        expect(shell.borderWidth, CtDialogShell.dangerBorderWidth);
        expect(shell.borderWidth, 1);
      },
    );

    testWidgets(
      'war-confirmation actions are CtNinePatchButton with danger primary (Refs #2867 R9)',
      (WidgetTester tester) async {
        await openInvasionWarConfirm(tester, AppEventBus.create());

        final subShell = warConfirmSubShell();
        final CtNinePatchButton primary = tester.widget<CtNinePatchButton>(
          find.descendant(
            of: subShell,
            matching: find.widgetWithText(
              CtNinePatchButton,
              'Declare war and move',
            ),
          ),
        );
        expect(primary.dangerVariant, isTrue);

        final CtNinePatchButton cancel = tester.widget<CtNinePatchButton>(
          find.descendant(
            of: subShell,
            matching: find.widgetWithText(CtNinePatchButton, 'Cancel'),
          ),
        );
        expect(cancel.dangerVariant, isFalse);

        // No Material AlertDialog/TextButton chrome (SPEC pixel-art catalog ban).
        expect(
          find.descendant(of: subShell, matching: find.byType(AlertDialog)),
          findsNothing,
        );
        expect(
          find.descendant(of: subShell, matching: find.byType(TextButton)),
          findsNothing,
        );
      },
    );

    testWidgets(
      'outer Cancel emits no ArmyMoveRequestedEvent and dismisses dialog',
      (WidgetTester tester) async {
        final (bus, getCaptured, sub) = subscribeArmyMoveRequested();
        addTearDown(sub.cancel);

        await pumpDialog(tester, bus: bus);
        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Cancel'));
        await tester.pumpAndSettle();

        expect(getCaptured(), isNull);
        expect(find.byType(MoveArmyDialog), findsNothing);
      },
    );

    testWidgets(
      'with zero offered destinations renders the empty-state copy and disables Confirm',
      (WidgetTester tester) async {
        const isolatedPlayerId = 'gp_isolated';
        const isolatedFrom = 'oldWorld|p_isolated';
        final isolatedGame = Game(
          id: 'g_isolated_army',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: isolatedFrom,
                  regionId: 'oldWorld',
                  ownerId: isolatedPlayerId,
                  displayName: 'Lonely',
                ),
              ],
              units: [
                Unit(
                  id: 'u_isolated',
                  type: 'musketeers',
                  ownerId: isolatedPlayerId,
                  locationProvinceId: isolatedFrom,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: const [
              Army(
                id: 'aisolated',
                ownerId: isolatedPlayerId,
                regionId: 'oldWorld',
                stationedProvinceId: isolatedFrom,
                regimentUnitIds: ['u_isolated'],
                isHomeArmy: false,
              ),
            ],
            tileKeysByRegionAndProvince: const {
              'oldWorld': {
                isolatedFrom: ['oldWorld|p_isolated|0|0'],
              },
            },
          ),
          players: const [
            Player(
              id: isolatedPlayerId,
              displayName: 'Isolated',
              isHuman: true,
              capitalProvinceId: isolatedFrom,
            ),
          ],
        );
        const isolatedTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: isolatedFrom,
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => MoveArmyDialog(
                        army: isolatedGame.worldState.armies.first,
                        game: isolatedGame,
                        humanPlayerId: isolatedPlayerId,
                        bus: AppEventBus.create(),
                        topology: isolatedTopology,
                        draftOrders: const Orders(),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('No valid destinations.'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        final confirmButton = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Confirm'),
        );
        expect(confirmButton.onPressed, isNull);
      },
    );
  });
}
