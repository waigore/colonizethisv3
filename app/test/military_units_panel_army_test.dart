// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_circular_locate_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'support/military_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('Army management (bus events)', () {
    testWidgets('Home Army expansion does not show Move action', (
      WidgetTester tester,
    ) async {
      const playerId = 'gp_home_no_move';
      final game = buildMilitaryHomeArmyAtCapitalGame(
        id: 'ghm',
        playerId: playerId,
        regimentIds: const ['u_home'],
        townTileKey: 'tk',
        playerDisplayName: 'Home',
      );

      await pumpMilitaryPanel(tester, game: game, humanPlayerId: playerId);

      final homeTile = find.widgetWithText(ExpansionTile, 'Home Army');
      expect(homeTile, findsOneWidget);
      await tester.tap(homeTile);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: homeTile,
          matching: find.widgetWithText(ElevatedButton, 'Move'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: homeTile, matching: find.text('Move')),
        findsNothing,
      );
    });

    testWidgets(
      'Combine emits ArmyCombineRequestedEvent when two armies selected',
      (WidgetTester tester) async {
        ArmyCombineRequestedEvent? captured;
        final bus = AppEventBus.create();
        bus.on<ArmyCombineRequestedEvent>().listen((e) => captured = e);

        const playerId = 'gp_combine';
        final game = buildMilitaryTwoFieldArmiesAtProvinceGame(
          id: 'gc',
          playerId: playerId,
        );

        await pumpMilitaryPanel(
          tester,
          game: game,
          humanPlayerId: playerId,
          bus: bus,
        );

        final checks = find.byType(Checkbox);
        expect(checks, findsNWidgets(3));
        await tester.tap(checks.at(1));
        await tester.tap(checks.at(2));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Combine'));
        await tester.pumpAndSettle();

        expect(captured, isNotNull);
        expect(captured!.armyIds.length, 2);
      },
    );

    testWidgets('Move confirms ArmyMoveRequestedEvent', (
      WidgetTester tester,
    ) async {
      ArmyMoveRequestedEvent? captured;
      final bus = AppEventBus.create();
      bus.on<ArmyMoveRequestedEvent>().listen((e) => captured = e);

      const playerId = 'gp_move';
      const p3 = 'oldWorld|p3';
      final topology = buildMilitaryAdjacentOwProvincesTopology();
      final game = buildMilitaryFieldArmyWithAdjacentOwnedGame(
        id: 'gm',
        playerId: playerId,
        armyId: 'amove',
        regimentUnitIds: const ['um1'],
      );

      await pumpMilitaryPanel(
        tester,
        game: game,
        humanPlayerId: playerId,
        bus: bus,
        topology: topology,
      );

      await tester.tap(find.text('Army amove'));
      await tester.pumpAndSettle();
      final armyTile = find.widgetWithText(ExpansionTile, 'Army amove');
      expect(armyTile, findsOneWidget);
      final moveButton = find.descendant(
        of: armyTile,
        matching: find.widgetWithText(CtActionTextButton, 'Move'),
      );
      await tester.tap(moveButton.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.moveOrder.armyId, 'amove');
      expect(captured!.moveOrder.destinationProvinceId, p3);
    });

    testWidgets(
      'AC #3514: army row Locate is a rightmost circular pill in the actions '
      'cluster and emits LocateMapTileEvent',
      (WidgetTester tester) async {
        LocateMapTileEvent? locate;
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        bus.on<LocateMapTileEvent>().listen((e) => locate = e);

        const playerId = 'gp_locate_cluster';
        final topology = buildMilitaryAdjacentOwProvincesTopology();
        final game = buildMilitaryFieldArmyWithAdjacentOwnedGame(
          id: 'g_locate_cluster',
          playerId: playerId,
          armyId: 'acluster',
          regimentUnitIds: const ['um1', 'um2'],
        );

        await pumpMilitaryPanel(
          tester,
          game: game,
          humanPlayerId: playerId,
          bus: bus,
          topology: topology,
        );

        final armyTile = find.widgetWithText(ExpansionTile, 'Army acluster');
        expect(armyTile, findsOneWidget);

        // Move + Split render as compact pills; Locate as a circular pill.
        final moveBtn = find.descendant(
          of: armyTile,
          matching: find.widgetWithText(CtActionTextButton, 'Move'),
        );
        final splitBtn = find.descendant(
          of: armyTile,
          matching: find.widgetWithText(CtActionTextButton, 'Split'),
        );
        final locateBtn = find.descendant(
          of: armyTile,
          matching: find.byType(CtCircularLocateButton),
        );
        expect(moveBtn, findsOneWidget);
        expect(splitBtn, findsOneWidget);
        expect(locateBtn, findsOneWidget);
        // Locate must NOT use the legacy title-row CtIconAction chrome and must
        // be the rightmost control in the actions cluster.
        final locateDx = tester.getCenter(locateBtn).dx;
        expect(locateDx, greaterThan(tester.getCenter(moveBtn).dx));
        expect(locateDx, greaterThan(tester.getCenter(splitBtn).dx));

        await tester.tap(locateBtn);
        await tester.pump();
        await tester.pumpAndSettle();
        expect(locate, isNotNull);
        expect(locate!.tileKey, 'tk');
        expect(locate!.regionId, 'oldWorld');
      },
    );

    testWidgets(
      'Move dialog groups by owning faction and cross-region owned move',
      (WidgetTester tester) async {
        ArmyMoveRequestedEvent? captured;
        final bus = AppEventBus.create();
        bus.on<ArmyMoveRequestedEvent>().listen((e) => captured = e);

        const playerId = 'gp_move_grouped';
        const newDest = 'newWorld|n2';
        final topology = buildMilitaryAdjacentOwProvincesTopology();
        final game = buildMilitaryCrossRegionOwnedMoveGame(
          id: 'g_move_grouped',
          playerId: playerId,
        );

        await pumpMilitaryPanel(
          tester,
          game: game,
          humanPlayerId: playerId,
          bus: bus,
          topology: topology,
        );

        await tester.tap(find.text('Army amove'));
        await tester.pumpAndSettle();
        final armyTile = find.widgetWithText(ExpansionTile, 'Army amove');
        expect(armyTile, findsOneWidget);
        final moveButton = find.descendant(
          of: armyTile,
          matching: find.widgetWithText(CtActionTextButton, 'Move'),
        );
        await tester.tap(moveButton.first);
        await tester.pumpAndSettle();

        expect(find.byType(MoveArmyDialog), findsOneWidget);
        expect(find.text('YOUR PROVINCES'), findsOneWidget);

        await tester.tap(find.text('New Port'));
        await tester.pump();
        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Confirm'));
        await tester.pumpAndSettle();

        expect(captured, isNotNull);
        expect(captured!.moveOrder.armyId, 'amove');
        expect(captured!.moveOrder.destinationProvinceId, newDest);
      },
    );

    testWidgets('Army row shows Moving to when draft has army move', (
      WidgetTester tester,
    ) async {
      const playerId = 'gp_draft_mv';
      const dest = 'oldWorld|p3';
      final game = buildMilitaryFieldArmyWithAdjacentOwnedGame(
        id: 'g_draft',
        playerId: playerId,
        armyId: 'amove',
        regimentUnitIds: const ['ux'],
        stationTownTileKey: null,
        stationDisplayName: 'Here',
        adjacentDisplayName: 'There',
        playerDisplayName: 'D',
        includeTileKeysAndVisibility: false,
      );
      final draft = Orders(
        armyMoveOrdersByPlayerId: {
          playerId: [
            ArmyMoveOrder(armyId: 'amove', destinationProvinceId: dest),
          ],
        },
      );
      await pumpMilitaryPanel(
        tester,
        game: game,
        humanPlayerId: playerId,
        draftOrders: draft,
      );

      expect(find.textContaining('Moving to: There'), findsOneWidget);
    });

    testWidgets('Invasion move emits declareWarTargetFactionId after confirm', (
      WidgetTester tester,
    ) async {
      ArmyMoveRequestedEvent? captured;
      final bus = AppEventBus.create();
      bus.on<ArmyMoveRequestedEvent>().listen((e) => captured = e);

      const playerId = 'gp_inv';
      const enemyId = 'gp_enemy';
      const loc2 = 'oldWorld|p3';
      final topology = buildMilitaryAdjacentOwProvincesTopology();
      final game = buildMilitaryInvasionAdjacentHostileGame(
        id: 'g_inv',
        playerId: playerId,
        enemyId: enemyId,
      );

      await pumpMilitaryPanel(
        tester,
        game: game,
        humanPlayerId: playerId,
        bus: bus,
        topology: topology,
      );

      await tester.tap(find.text('Army ainv'));
      await tester.pumpAndSettle();
      final armyTile = find.widgetWithText(ExpansionTile, 'Army ainv');
      expect(armyTile, findsOneWidget);
      final moveButton = find.descendant(
        of: armyTile,
        matching: find.widgetWithText(CtActionTextButton, 'Move'),
      );
      await tester.tap(moveButton.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hostile'));
      await tester.pump();
      await tester.tap(find.widgetWithText(CtNinePatchButton, 'Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Declare war and move'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(CtNinePatchButton, 'Declare war and move'),
      );
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.declareWarTargetFactionId, enemyId);
      expect(captured!.moveOrder.destinationProvinceId, loc2);
    });
  });
}
