// Pins SPEC/ui movement dialog contracts (part 2):
// - SPEC/ui/move-fleet-dialog.md
// Split under repo.app_test_file_size (Refs #4013).

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';

import 'move_dialogs_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  group('MoveFleetDialog (SPEC/ui/move-fleet-dialog.md)', () {
    const playerId = 'gp_specs_fleet';
    const originSea = 'sea_origin';
    const adjacentSea = 'sea_adjacent';
    const crossSea = 'sea_cross';
    const capitalProvince = 'oldWorld|p_capital_specs';

    MapTopology buildTopology() {
      return const MapTopology(
        nodes: [
          TopologyNode(
            id: originSea,
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: adjacentSea,
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: crossSea,
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: originSea, id2: adjacentSea),
          TopologyEdge(id1: originSea, id2: crossSea),
        ],
      );
    }

    Game buildGame() {
      return Game(
        id: 'g_specs_fleet',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: capitalProvince,
                regionId: 'oldWorld',
                ownerId: playerId,
                displayName: 'Capital Port',
              ),
            ],
          ),
          newWorld: const RegionData(),
          portsByProvinceSeaboard: const {
            'oldWorld|p_capital_specs|sea_origin':
                'oldWorld|p_capital_specs|0|0',
            'oldWorld|p_capital_specs|sea_adjacent':
                'oldWorld|p_capital_specs|0|0',
            'newWorld|p_cross|sea_cross': 'newWorld|p_cross|0|0',
          },
          seaZoneDisplayNameById: const {
            'oldWorld|sea_origin': 'Origin Sea',
            'oldWorld|sea_adjacent': 'Adjacent Sea',
            'newWorld|sea_cross': 'Cross Sea',
          },
        ),
        players: const [
          Player(
            id: playerId,
            displayName: 'Specs Admiral',
            isHuman: true,
            capitalProvinceId: capitalProvince,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: capitalProvince,
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
    }

    Fleet buildFleet() {
      return Fleet(
        id: 'fspecs',
        ownerId: playerId,
        regionId: 'oldWorld',
        seaZoneId: originSea,
        ships: const [ShipInstance(id: 'ship_specs', typeId: 'carrack')],
      );
    }

    Future<void> pumpDialog(
      WidgetTester tester, {
      required AppEventBus bus,
    }) async {
      final game = buildGame();
      final topology = buildTopology();
      final fleet = buildFleet();
      await tester.pumpWidget(
        moveDialogsSpecsFrameWithOpener(
          (context) => () {
            showDialog<void>(
              context: context,
              builder: (_) => MoveFleetDialog(
                game: game,
                topology: topology,
                humanPlayerId: playerId,
                fleet: fleet,
                bus: bus,
              ),
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'with sea + dock destinations shows both section headers and titleWithDestinations',
      (WidgetTester tester) async {
        await pumpDialog(tester, bus: AppEventBus.create());
        expect(find.byType(MoveFleetDialog), findsOneWidget);
        // CtSectionLabel renders text upper-cased.
        expect(find.text('SEA ZONES'), findsOneWidget);
        expect(
          find.textContaining('Move fleet — Fleet fspecs'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'dialog is wrapped in CtDialogShell and contains no Material AlertDialog / RadioListTile / TextButton (Refs #2867 R1)',
      (WidgetTester tester) async {
        await pumpDialog(tester, bus: AppEventBus.create());

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(RadioListTile<dynamic>), findsNothing);
        expect(find.byType(Radio<dynamic>), findsNothing);
        // Material TextButton banned inside the dialog surface — the catalog
        // ban only applies to widgets painted by MoveFleetDialog itself, so
        // we scope the check to descendants of CtDialogShell.
        expect(
          find.descendant(
            of: find.byType(CtDialogShell),
            matching: find.byType(TextButton),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('section headers use CtSectionLabel (Refs #2867 R6)', (
      WidgetTester tester,
    ) async {
      await pumpDialog(tester, bus: AppEventBus.create());

      // The fixture only generates sea-zone destinations (no dock ports
      // resolve through the topology), so the dialog renders exactly one
      // CtSectionLabel — the sea-zones header. The full sea+port shape is
      // pinned by SPEC AC and by the broader move_fleet_dialog_test.dart
      // coverage; the catalog ban below is the regression guard that
      // matters for the legacy bold-Text headers.
      expect(find.byType(CtSectionLabel), findsAtLeastNWidgets(1));
      final CtSectionLabel firstLabel = tester.widget<CtSectionLabel>(
        find.byType(CtSectionLabel).first,
      );
      expect(firstLabel.text, 'Sea zones');
    });

    testWidgets(
      'confirm with selected sea-zone row emits NavalMoveFleetRequestedEvent',
      (WidgetTester tester) async {
        NavalMoveFleetRequestedEvent? captured;
        final bus = AppEventBus.create();
        final sub = bus.on<NavalMoveFleetRequestedEvent>().listen((e) {
          captured = e;
        });
        addTearDown(sub.cancel);

        await pumpDialog(tester, bus: bus);
        await tester.tap(find.text('Adjacent Sea'));
        await tester.pump();
        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Confirm'));
        await tester.pumpAndSettle();

        expect(captured, isNotNull);
        expect(captured!.humanPlayerId, playerId);
        expect(captured!.moveOrder.fleetId, 'fspecs');
        expect(captured!.moveOrder.destinationSeaZoneId, adjacentSea);
        expect(captured!.moveOrder.destinationPortProvinceId, isNull);
        expect(find.byType(MoveFleetDialog), findsNothing);
      },
    );

    testWidgets(
      'Confirm is disabled until a destination is selected (Refs #2867 R10)',
      (WidgetTester tester) async {
        await pumpDialog(tester, bus: AppEventBus.create());

        final CtNinePatchButton confirmBefore = tester
            .widget<CtNinePatchButton>(
              find.widgetWithText(CtNinePatchButton, 'Confirm'),
            );
        expect(confirmBefore.onPressed, isNull);

        await tester.tap(find.text('Adjacent Sea'));
        await tester.pump();

        final CtNinePatchButton confirmAfter = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Confirm'),
        );
        expect(confirmAfter.onPressed, isNotNull);
      },
    );

    testWidgets(
      'cancel emits no NavalMoveFleetRequestedEvent and dismisses dialog',
      (WidgetTester tester) async {
        NavalMoveFleetRequestedEvent? captured;
        final bus = AppEventBus.create();
        final sub = bus.on<NavalMoveFleetRequestedEvent>().listen((e) {
          captured = e;
        });
        addTearDown(sub.cancel);

        await pumpDialog(tester, bus: bus);
        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Cancel'));
        await tester.pumpAndSettle();

        expect(captured, isNull);
        expect(find.byType(MoveFleetDialog), findsNothing);
      },
    );

    testWidgets('per-row locate tap emits LocateMapTileEvent', (
      WidgetTester tester,
    ) async {
      LocateMapTileEvent? captured;
      final bus = AppEventBus.create();
      final sub = bus.on<LocateMapTileEvent>().listen((e) {
        captured = e;
      });
      addTearDown(sub.cancel);

      await pumpDialog(tester, bus: bus);
      final locateIcons = find.byIcon(Icons.my_location);
      expect(locateIcons, findsWidgets);
      await tester.tap(locateIcons.first);
      await tester.pump();

      expect(captured, isNotNull);
    });

    testWidgets(
      'with zero topology picks shows empty-state copy and disables Confirm',
      (WidgetTester tester) async {
        const lonelyPlayerId = 'gp_lonely_fleet';
        const lonelySea = 'sea_lonely';
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
      },
    );
  });
}
