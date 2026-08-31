// Pins SPEC/ui/move-fleet-dialog.md (Refs #4013, #4352).

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';

import 'move_dialogs_specs_fleet_support.dart';
import 'move_dialogs_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  group('MoveFleetDialog (SPEC/ui/move-fleet-dialog.md)', () {
    testWidgets('shows origin sea zone and adjacent destinations', (
      WidgetTester tester,
    ) async {
      final bus = AppEventBus.create();
      await pumpMoveFleetSpecsDialog(tester, bus: bus);

      expect(find.text('Move fleet — Fleet fspecs'), findsOneWidget);
      expect(find.text('Origin Sea'), findsOneWidget);
      expect(find.text('Adjacent Sea'), findsOneWidget);
      expect(find.text('Cross Sea'), findsNothing);
    });

    testWidgets('Confirm emits MoveFleetOrder on destination tap', (
      WidgetTester tester,
    ) async {
      final bus = AppEventBus.create();
      final orders = <MoveFleetOrder>[];
      final sub = bus.on<MoveFleetOrder>().listen(orders.add);
      addTearDown(sub.cancel);

      await pumpMoveFleetSpecsDialog(tester, bus: bus);
      await tester.tap(find.text('Adjacent Sea'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CtNinePatchButton, 'Confirm'));
      await tester.pumpAndSettle();

      expect(orders, hasLength(1));
      expect(orders.single.fleetId, 'fspecs');
      expect(orders.single.destinationSeaZoneId, moveFleetSpecsAdjacentSea);
    });

    testWidgets('CtDialogShell + CtSectionLabel chrome present', (
      WidgetTester tester,
    ) async {
      await pumpMoveFleetSpecsDialog(tester, bus: AppEventBus.create());
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byType(CtSectionLabel), findsWidgets);
    });

    testWidgets('no adjacent sea zones disables Confirm', (
      WidgetTester tester,
    ) async {
      const lonelyPlayerId = 'gp_lonely';
      const lonelySea = 'oldWorld|sea_lonely';
      final game = Game(
        id: 'g_lonely_fleet',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
          seaZoneDisplayNameById: {'oldWorld|sea_lonely': 'Lonely Sea'},
        ),
        players: const [
          Player(
            id: lonelyPlayerId,
            displayName: 'Lonely Admiral',
            isHuman: true,
            capitalProvinceId: 'oldWorld|p_void',
          ),
        ],
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: lonelySea,
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [],
      );
      final fleet = Fleet(
        id: 'flonely',
        ownerId: lonelyPlayerId,
        regionId: 'oldWorld',
        seaZoneId: lonelySea,
        ships: const [ShipInstance(id: 'ship_lonely', typeId: 'carrack')],
      );

      await tester.pumpWidget(
        moveDialogsSpecsFrameWithOpener(
          (context) => () {
            showDialog<void>(
              context: context,
              builder: (_) => MoveFleetDialog(
                game: game,
                topology: topology,
                humanPlayerId: lonelyPlayerId,
                fleet: fleet,
                bus: AppEventBus.create(),
              ),
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text('No adjacent sea zones (check map topology).'),
        findsOneWidget,
      );
      expect(find.text('Move fleet — Fleet flonely'), findsOneWidget);
      final confirmButton = tester.widget<CtNinePatchButton>(
        find.widgetWithText(CtNinePatchButton, 'Confirm'),
      );
      expect(confirmButton.onPressed, isNull);
    });
  });
}
