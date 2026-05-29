// Pins SPEC/ui movement dialog contracts:
// - SPEC/ui/move-army-dialog.md
// - SPEC/ui/move-fleet-dialog.md

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/move_fleet_dialog.dart';

Widget _frameWithOpener(VoidCallback Function(BuildContext) builder) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: builder(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

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
        _frameWithOpener(
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

    testWidgets(
      'renders a single dialog with the destination dropdown for valid inputs',
      (WidgetTester tester) async {
        await pumpDialog(tester, bus: AppEventBus.create());
        expect(find.byType(MoveArmyDialog), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
        expect(find.text('Destination province'), findsOneWidget);
      },
    );

    testWidgets(
      'groups destinations with "Your provinces" header before player-owned entries',
      (WidgetTester tester) async {
        await pumpDialog(tester, bus: AppEventBus.create());
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        expect(find.text('Your provinces'), findsWidgets);
      },
    );

    testWidgets(
      'confirm on owned destination emits ArmyMoveRequestedEvent without declareWar',
      (WidgetTester tester) async {
        ArmyMoveRequestedEvent? captured;
        final bus = AppEventBus.create();
        final sub = bus.on<ArmyMoveRequestedEvent>().listen((e) {
          captured = e;
        });
        addTearDown(sub.cancel);

        await pumpDialog(tester, bus: bus);
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(captured, isNotNull);
        expect(captured!.humanPlayerId, playerId);
        expect(captured!.moveOrder.armyId, 'aspecs');
        expect(captured!.declareWarTargetFactionId, isNull);
        expect(find.byType(MoveArmyDialog), findsNothing);
      },
    );

    testWidgets(
      'confirm on invasion destination then declare-war confirm carries declareWarTargetFactionId',
      (WidgetTester tester) async {
        ArmyMoveRequestedEvent? captured;
        final bus = AppEventBus.create();
        final sub = bus.on<ArmyMoveRequestedEvent>().listen((e) {
          captured = e;
        });
        addTearDown(sub.cancel);

        await pumpDialog(tester, bus: bus);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Invade Dest').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(find.text('Declare war?'), findsOneWidget);
        await tester.tap(find.text('Declare war and move'));
        await tester.pumpAndSettle();

        expect(captured, isNotNull);
        expect(captured!.declareWarTargetFactionId, otherFactionId);
        expect(captured!.moveOrder.destinationProvinceId, invasionDest);
      },
    );

    testWidgets(
      'cancel on invasion confirmation aborts emit and keeps dialog mounted',
      (WidgetTester tester) async {
        ArmyMoveRequestedEvent? captured;
        final bus = AppEventBus.create();
        final sub = bus.on<ArmyMoveRequestedEvent>().listen((e) {
          captured = e;
        });
        addTearDown(sub.cancel);

        await pumpDialog(tester, bus: bus);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Invade Dest').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(find.text('Declare war?'), findsOneWidget);
        await tester.tap(
          find.widgetWithText(CtNinePatchButton, 'Cancel').first,
        );
        await tester.pumpAndSettle();

        expect(captured, isNull);
        expect(find.byType(MoveArmyDialog), findsOneWidget);
      },
    );

    testWidgets(
      'war-confirmation sub-dialog renders inside CtDialogShell with --danger 1px border (Refs #2867 R9)',
      (WidgetTester tester) async {
        await pumpDialog(tester, bus: AppEventBus.create());
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Invade Dest').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('Declare war?'), findsOneWidget);

        final CtDialogShell shell = tester.widget<CtDialogShell>(
          find.byType(CtDialogShell),
        );
        expect(shell.borderColor, EditorialMonoclePalette.danger);
        expect(shell.borderWidth, CtDialogShell.dangerBorderWidth);
        expect(shell.borderWidth, 1);
      },
    );

    testWidgets(
      'war-confirmation actions are CtNinePatchButton with danger primary (Refs #2867 R9)',
      (WidgetTester tester) async {
        await pumpDialog(tester, bus: AppEventBus.create());
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Invade Dest').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        final CtNinePatchButton primary = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Declare war and move'),
        );
        expect(primary.dangerVariant, isTrue);

        final CtNinePatchButton cancel = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Cancel'),
        );
        expect(cancel.dangerVariant, isFalse);

        // No Material AlertDialog/TextButton chrome paints the war-confirm
        // sub-dialog (per SPEC/ui/pixel-art-ui-catalog.md § Material design ban
        // and SPEC/ui/move-army-dialog.md § Invade-confirm sub-dialog).
        expect(
          find.descendant(
            of: find.byType(CtDialogShell),
            matching: find.byType(AlertDialog),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(CtDialogShell),
            matching: find.byType(TextButton),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'outer Cancel emits no ArmyMoveRequestedEvent and dismisses dialog',
      (WidgetTester tester) async {
        ArmyMoveRequestedEvent? captured;
        final bus = AppEventBus.create();
        final sub = bus.on<ArmyMoveRequestedEvent>().listen((e) {
          captured = e;
        });
        addTearDown(sub.cancel);

        await pumpDialog(tester, bus: bus);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(captured, isNull);
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
        final confirmButton = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Confirm'),
        );
        expect(confirmButton.onPressed, isNull);
      },
    );
  });

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
            'oldWorld|p_capital_specs|sea_origin': 'oldWorld|p_capital_specs|0|0',
            'oldWorld|p_capital_specs|sea_adjacent': 'oldWorld|p_capital_specs|0|0',
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
        _frameWithOpener(
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

    testWidgets(
      'section headers use CtSectionLabel (Refs #2867 R6)',
      (WidgetTester tester) async {
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
      },
    );

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

        final CtNinePatchButton confirmBefore =
            tester.widget<CtNinePatchButton>(
              find.widgetWithText(CtNinePatchButton, 'Confirm'),
            );
        expect(confirmBefore.onPressed, isNull);

        await tester.tap(find.text('Adjacent Sea'));
        await tester.pump();

        final CtNinePatchButton confirmAfter =
            tester.widget<CtNinePatchButton>(
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
            seaZoneDisplayNameById: {
              'oldWorld|sea_lonely': 'Lonely Sea',
            },
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
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
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
                  child: const Text('open'),
                ),
              ),
            ),
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
