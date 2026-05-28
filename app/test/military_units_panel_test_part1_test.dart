// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/utils/map_location_resolver.dart';
import 'package:colonizethis_app/features/game/widgets/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

/// Applies [ArmySplitRequestedEvent] like [AppEventHandlerScope] and rebuilds
/// the panel with updated [Game] (widget tests do not mount full shell).
class _ArmySplitTestHarness extends StatefulWidget {
  const _ArmySplitTestHarness({
    required this.initialGame,
    required this.humanPlayerId,
    required this.bus,
  });

  final Game initialGame;
  final String humanPlayerId;
  final AppEventBus bus;

  @override
  State<_ArmySplitTestHarness> createState() => _ArmySplitTestHarnessState();
}

class _ArmySplitTestHarnessState extends State<_ArmySplitTestHarness> {
  late Game _game;
  StreamSubscription<ArmySplitRequestedEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGame;
    _sub = widget.bus.on<ArmySplitRequestedEvent>().listen((e) {
      final next = applyArmySplit(
        game: _game,
        playerId: e.humanPlayerId,
        sourceArmyId: e.sourceArmyId,
        unitIdsToMove: e.unitIdsToMove,
      );
      setState(() => _game = next);
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MilitaryUnitsPanel(
      game: _game,
      humanPlayerId: widget.humanPlayerId,
      bus: widget.bus,
      topology: const MapTopology(),
      draftOrders: const Orders(),
    );
  }
}

Future<void> expandFirstArmyExpansion(WidgetTester tester) async {
  final tiles = find.byType(ExpansionTile);
  if (tiles.evaluate().isEmpty) {
    return;
  }
  await tester.tap(tiles.first);
  await tester.pumpAndSettle();
}

Future<void> expandAllArmyExpansions(WidgetTester tester) async {
  final finder = find.byType(ExpansionTile);
  final n = finder.evaluate().length;
  for (var i = 0; i < n; i++) {
    await tester.tap(finder.at(i));
    await tester.pumpAndSettle();
  }
}

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;
  const String humanPlayerIdWithNoUnits = 'no-such-player';

  setUpAll(() {
    game = getDebugInitGameResult().game;
    humanPlayerIdWithUnits = game.players.isNotEmpty
        ? game.players.first.id
        : 'gp1';
  });

  Widget buildPanel({
    required Game game,
    required String humanPlayerId,
    AppEventBus? bus,
    MapTopology? topology,
    Orders draftOrders = const Orders(),
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MilitaryUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          bus: bus ?? AppEventBus.create(),
          topology: topology ?? const MapTopology(),
          draftOrders: draftOrders,
        ),
      ),
    );
  }

  group('MilitaryUnitsPanel', () {
    testWidgets('AC: Panel shows title Military Units', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.text('Military Units'), findsOneWidget);
    });

    testWidgets(
      'AC: Empty state when human player has zero regiments and no fleets',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithNoUnits),
        );
        await tester.pumpAndSettle();

        expect(find.text('No military units'), findsOneWidget);
        expect(find.byType(ListTile), findsNothing);
      },
    );

    testWidgets('naval location header uses sea-zone display name', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_mil_sea_label';
      const cap = 'oldWorld|c1';
      final miniGame = Game(
        id: 'g_mil_sea_label',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: 'c1',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Cap',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f_at_sea',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 'zone_x',
              ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
            ),
          ],
          seaZoneDisplayNameById: const {'oldWorld|zone_x': 'Mil Named Sea'},
        ),
        players: const [
          Player(
            id: humanId,
            displayName: 'Mil Sea Tester',
            isHuman: true,
            capitalProvinceId: cap,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: cap,
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        buildPanel(game: miniGame, humanPlayerId: humanId),
      );
      await tester.pump();
      expect(find.textContaining('Mil Named Sea'), findsWidgets);
    });

    testWidgets(
      'AC: When player has military units, tree shows regions and type rows',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
        );
        await tester.pumpAndSettle();

        final militaryCount =
            game.worldState.oldWorld.units
                .where(
                  (u) =>
                      u.ownerId == humanPlayerIdWithUnits &&
                      isMilitaryUnit(u.type),
                )
                .length +
            game.worldState.newWorld.units
                .where(
                  (u) =>
                      u.ownerId == humanPlayerIdWithUnits &&
                      isMilitaryUnit(u.type),
                )
                .length;
        final fleetCount = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanPlayerIdWithUnits &&
                  f.shipTypeIds.isNotEmpty,
            )
            .length;
        if (militaryCount > 0 || fleetCount > 0) {
          expect(find.byType(ListTile), findsAtLeastNWidgets(1));
          expect(find.byType(UnitsEntityActionRow), findsAtLeastNWidgets(1));
          expect(
            find.text('OLD WORLD').evaluate().isNotEmpty ||
                find.text('NEW WORLD').evaluate().isNotEmpty,
            isTrue,
          );
        }
      },
    );

    testWidgets(
      'AC: Army subtitle uses province display name; regiment titles use roster names',
      (WidgetTester tester) async {
        const playerId = 'gp_display_names';
        const provinceLocal = 'lisbon';
        const fullProvince = 'oldWorld|$provinceLocal';
        final miniGame = Game(
          id: 'g_display_mil',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              units: [
                Unit(
                  id: 'levy1',
                  type: 'peasant_levies',
                  ownerId: playerId,
                  locationProvinceId: fullProvince,
                  medals: 0,
                  status: UnitStatus.idle,
                ),
              ],
              provinces: [
                Province(
                  id: fullProvince,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Lisbon Harbor',
                  townTileKey: 'oldWorld|lisbon|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [],
            armies: [
              Army(
                id: 'army_field',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: fullProvince,
                regimentUnitIds: const ['levy1'],
                isHomeArmy: false,
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                fullProvince: ['oldWorld|lisbon|0|0'],
              },
            },
          ),
          players: const [
            Player(
              id: playerId,
              displayName: 'Tester',
              isHuman: true,
              capitalProvinceId: fullProvince,
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: miniGame, humanPlayerId: playerId),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('regiments · Lisbon Harbor'), findsWidgets);
        await expandFirstArmyExpansion(tester);
        expect(find.textContaining('Peasant Levies: 1'), findsOneWidget);
        expect(find.textContaining('peasant_levies:'), findsNothing);
      },
    );

    testWidgets('AC: Regiment rows show type, count, medals, status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      final militaryCount =
          game.worldState.oldWorld.units
              .where(
                (u) =>
                    u.ownerId == humanPlayerIdWithUnits &&
                    isMilitaryUnit(u.type),
              )
              .length +
          game.worldState.newWorld.units
              .where(
                (u) =>
                    u.ownerId == humanPlayerIdWithUnits &&
                    isMilitaryUnit(u.type),
              )
              .length;
      if (militaryCount == 0) return;

      // Army entries use ExpansionTile; subtitle includes "regiments ·".
      expect(find.textContaining('regiments ·'), findsAtLeastNWidgets(1));
      await expandAllArmyExpansions(tester);
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'AC: When tree has content, location headers show region (name — region)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
        );
        await tester.pumpAndSettle();

        if (find.byType(ListTile).evaluate().isEmpty) return;
        expect(find.textContaining(' — '), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('panel is wrapped in CtPanel', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtPanel), findsOneWidget);
    });

    testWidgets('AC: Tapping a row emits LocateMapTileEvent', (
      WidgetTester tester,
    ) async {
      LocateMapTileEvent? locateEvent;
      final bus = AppEventBus.create();
      bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits, bus: bus),
      );
      await tester.pumpAndSettle();

      final locateButtons = find.byIcon(Icons.my_location);
      if (locateButtons.evaluate().isEmpty) return;
      await tester.tap(locateButtons.first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(locateEvent, isNotNull);
      expect(
        locateEvent!.regionId == 'oldWorld' ||
            locateEvent!.regionId == 'newWorld',
        isTrue,
      );
    });

    testWidgets('builds without locate callback', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isNotEmpty) {
        await tester.tap(listTiles.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Train button emits train-military dialog open event', (
      WidgetTester tester,
    ) async {
      OpenDialogEvent? openDialogEvent;
      final bus = AppEventBus.create();
      bus.on<OpenDialogEvent>().listen((e) => openDialogEvent = e);

      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits, bus: bus),
      );
      await tester.pumpAndSettle();

      final trainButton = find.text('Train');
      expect(trainButton, findsOneWidget);
      await tester.tap(trainButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(openDialogEvent, isNotNull);
      expect(openDialogEvent!.dialogId, trainMilitaryDialogId);
    });

    testWidgets(
      'AC: Tapping locate emits ClosePanelEvent before LocateMapTileEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final sequence = <Type>[];
        bus.stream.listen((e) => sequence.add(e.runtimeType));

        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final locateButtons = find.byIcon(Icons.my_location);
        if (locateButtons.evaluate().isEmpty) return;
        await tester.tap(locateButtons.first);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          sequence.indexOf(ClosePanelEvent),
          lessThan(sequence.indexOf(LocateMapTileEvent)),
        );
      },
    );

    testWidgets('panel is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
