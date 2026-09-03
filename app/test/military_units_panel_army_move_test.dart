// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'military_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('Army management (bus events)', () {
    testWidgets(
      'Move dialog groups by owning faction and cross-region owned move',
      (WidgetTester tester) async {
        ArmyMoveRequestedEvent? captured;
        final bus = AppEventBus.create();
        bus.on<ArmyMoveRequestedEvent>().listen((e) => captured = e);

        const playerId = 'gp_move_grouped';
        const newDest = 'newWorld|n2';
        final topology = buildUnitsPanelAdjacentOwProvincesTopology();
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
      final topology = buildUnitsPanelAdjacentOwProvincesTopology();
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
