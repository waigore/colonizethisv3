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

  group('Army management (bus events)', () {
    testWidgets('Home Army expansion does not show Move action', (
      WidgetTester tester,
    ) async {
      const playerId = 'gp_home_no_move';
      const cap = 'oldWorld|cap';
      final game = Game(
        id: 'ghm',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: playerId,
                townTileKey: 'tk',
              ),
            ],
            units: [
              Unit(
                id: 'u_home',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: cap,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'home_army',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const ['u_home'],
              isHomeArmy: true,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              cap: ['tk'],
            },
          },
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'Home',
            isHuman: true,
            capitalProvinceId: cap,
          ),
        ],
      );

      await tester.pumpWidget(buildPanel(game: game, humanPlayerId: playerId));
      await tester.pumpAndSettle();

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
        const p = 'oldWorld|p2';
        final game = Game(
          id: 'gc',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: p,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  townTileKey: 'tk',
                ),
              ],
              units: [
                Unit(
                  id: 'uu1',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: p,
                ),
                Unit(
                  id: 'uu2',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: p,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: 'ax',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: p,
                regimentUnitIds: const ['uu1'],
                isHomeArmy: false,
              ),
              Army(
                id: 'ay',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: p,
                regimentUnitIds: const ['uu2'],
                isHomeArmy: false,
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                p: ['tk'],
              },
            },
          ),
          players: [
            Player(
              id: playerId,
              displayName: 'C',
              isHuman: true,
              capitalProvinceId: 'oldWorld|cap',
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: playerId, bus: bus),
        );
        await tester.pumpAndSettle();

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
      const p = 'oldWorld|p2';
      const p3 = 'oldWorld|p3';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|p3',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'oldWorld|p2', id2: 'oldWorld|p3')],
      );
      final game = Game(
        id: 'gm',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: p,
                regionId: 'oldWorld',
                ownerId: playerId,
                townTileKey: 'tk',
              ),
              Province(id: p3, regionId: 'oldWorld', ownerId: playerId),
            ],
            units: [
              Unit(
                id: 'um1',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: p,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'amove',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: p,
              regimentUnitIds: const ['um1'],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              p: ['oldWorld|p2|0|0'],
              p3: ['oldWorld|p3|0|0'],
            },
          },
          playerVisibilityByTile: {
            playerId: {
              'oldWorld|p2|0|0': 'fullyVisible',
              'oldWorld|p3|0|0': 'fullyVisible',
            },
          },
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'M',
            isHuman: true,
            capitalProvinceId: p,
          ),
        ],
      );

      await tester.pumpWidget(
        buildPanel(
          game: game,
          humanPlayerId: playerId,
          bus: bus,
          topology: topology,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Army amove'));
      await tester.pumpAndSettle();
      final armyTile = find.widgetWithText(ExpansionTile, 'Army amove');
      expect(armyTile, findsOneWidget);
      final moveButton = find.descendant(
        of: armyTile,
        matching: find.widgetWithText(CtNinePatchButton, 'Move'),
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
      'Move dialog groups by owning faction and cross-region owned move',
      (WidgetTester tester) async {
        ArmyMoveRequestedEvent? captured;
        final bus = AppEventBus.create();
        bus.on<ArmyMoveRequestedEvent>().listen((e) => captured = e);

        const playerId = 'gp_move_grouped';
        const from = 'oldWorld|p2';
        const oldDest = 'oldWorld|p3';
        const newDest = 'newWorld|n2';

        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|p3',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'oldWorld|p2', id2: 'oldWorld|p3')],
        );

        final game = Game(
          id: 'g_move_grouped',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: from,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'From',
                  townTileKey: 'tk_from',
                ),
                Province(
                  id: oldDest,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Old Port',
                ),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: from,
                ),
              ],
            ),
            newWorld: RegionData(
              provinces: [
                Province(
                  id: newDest,
                  regionId: 'newWorld',
                  ownerId: playerId,
                  displayName: 'New Port',
                ),
              ],
            ),
            armies: [
              Army(
                id: 'amove',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: from,
                regimentUnitIds: const ['u1'],
                isHomeArmy: false,
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                from: ['oldWorld|p2|0|0'],
                oldDest: ['oldWorld|p3|0|0'],
              },
              'newWorld': {
                newDest: ['newWorld|n2|0|0'],
              },
            },
            playerVisibilityByTile: {
              playerId: {
                'oldWorld|p2|0|0': 'fullyVisible',
                'oldWorld|p3|0|0': 'fullyVisible',
                'newWorld|n2|0|0': 'fullyVisible',
              },
            },
          ),
          players: [
            Player(
              id: playerId,
              displayName: 'Grouped',
              isHuman: true,
              capitalProvinceId: from,
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: playerId,
            bus: bus,
            topology: topology,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Army amove'));
        await tester.pumpAndSettle();
        final armyTile = find.widgetWithText(ExpansionTile, 'Army amove');
        expect(armyTile, findsOneWidget);
        final moveButton = find.descendant(
          of: armyTile,
          matching: find.widgetWithText(CtNinePatchButton, 'Move'),
        );
        await tester.tap(moveButton.first);
        await tester.pumpAndSettle();

        expect(find.byType(MoveArmyDialog), findsOneWidget);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        expect(find.text('Your provinces'), findsWidgets);

        await tester.tap(find.text('New Port').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
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
      const p = 'oldWorld|p2';
      const dest = 'oldWorld|p3';
      final game = Game(
        id: 'g_draft',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: p,
                regionId: 'oldWorld',
                ownerId: playerId,
                displayName: 'Here',
              ),
              Province(
                id: dest,
                regionId: 'oldWorld',
                ownerId: playerId,
                displayName: 'There',
              ),
            ],
            units: [
              Unit(
                id: 'ux',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: p,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'amove',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: p,
              regimentUnitIds: const ['ux'],
              isHomeArmy: false,
            ),
          ],
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'D',
            isHuman: true,
            capitalProvinceId: p,
          ),
        ],
      );
      final draft = Orders(
        armyMoveOrdersByPlayerId: {
          playerId: [
            ArmyMoveOrder(armyId: 'amove', destinationProvinceId: dest),
          ],
        },
      );
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: playerId, draftOrders: draft),
      );
      await tester.pumpAndSettle();

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
      const loc1 = 'oldWorld|p2';
      const loc2 = 'oldWorld|p3';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|p3',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'oldWorld|p2', id2: 'oldWorld|p3')],
      );
      final game = Game(
        id: 'g_inv',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: loc1, regionId: 'oldWorld', ownerId: playerId),
              Province(
                id: loc2,
                regionId: 'oldWorld',
                ownerId: enemyId,
                displayName: 'Hostile',
              ),
            ],
            units: [
              Unit(
                id: 'ui1',
                type: 'musketeers',
                ownerId: playerId,
                locationProvinceId: loc1,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'ainv',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: loc1,
              regimentUnitIds: const ['ui1'],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              loc1: ['oldWorld|p2|0|0'],
              loc2: ['oldWorld|p3|0|0'],
            },
          },
          playerVisibilityByTile: {
            playerId: {
              'oldWorld|p2|0|0': 'fullyVisible',
              'oldWorld|p3|0|0': 'fullyVisible',
            },
          },
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'Inv',
            isHuman: true,
            capitalProvinceId: loc1,
          ),
          Player(
            id: enemyId,
            displayName: 'Enemy',
            isHuman: true,
            capitalProvinceId: loc2,
          ),
        ],
        diplomacyRelations: const [],
      );

      await tester.pumpWidget(
        buildPanel(
          game: game,
          humanPlayerId: playerId,
          bus: bus,
          topology: topology,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Army ainv'));
      await tester.pumpAndSettle();
      final armyTile = find.widgetWithText(ExpansionTile, 'Army ainv');
      expect(armyTile, findsOneWidget);
      final moveButton = find.descendant(
        of: armyTile,
        matching: find.widgetWithText(CtNinePatchButton, 'Move'),
      );
      await tester.tap(moveButton.first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hostile').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Declare war and move'), findsOneWidget);
      await tester.tap(find.text('Declare war and move'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.declareWarTargetFactionId, enemyId);
      expect(captured!.moveOrder.destinationProvinceId, loc2);
    });

    testWidgets(
      'split home army (all regiments): panel shows new army with regiment rows',
      (WidgetTester tester) async {
        const playerId = 'gp_split_ui_full';
        const cap = 'oldWorld|cap';
        final initial = Game(
          id: 'g_split_full',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: cap,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Capital',
                  townTileKey: 'tk_cap',
                ),
              ],
              units: [
                Unit(
                  id: 'r1',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
                Unit(
                  id: 'r2',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: 'home_army',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: cap,
                regimentUnitIds: const ['r1', 'r2'],
                isHomeArmy: true,
              ),
            ],
            nextArmySeq: 1,
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                cap: ['tk_cap'],
              },
            },
          ),
          players: [
            Player(
              id: playerId,
              displayName: 'Splitter',
              isHuman: true,
              capitalProvinceId: cap,
            ),
          ],
        );

        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 900,
                width: 480,
                child: _ArmySplitTestHarness(
                  initialGame: initial,
                  humanPlayerId: playerId,
                  bus: bus,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Army').first;
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        final splitBtn = find.descendant(
          of: homeTile,
          matching: find.widgetWithText(CtNinePatchButton, 'Split'),
        ).first;
        await tester.ensureVisible(splitBtn);
        await tester.tap(splitBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveAll('musketeers')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm Split'));
        // Broadcast bus delivers listeners asynchronously; flush like split_army_dialog_test.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('0 regiments · Capital'), findsOneWidget);
        expect(find.text('2 regiments · Capital'), findsOneWidget);

        await tester.tap(find.text('Army army_1'));
        await tester.pumpAndSettle();
        expect(find.text('Musketeers: 2'), findsOneWidget);
      },
    );

    testWidgets(
      'split home army (partial): panel shows correct counts on both armies',
      (WidgetTester tester) async {
        const playerId = 'gp_split_ui_partial';
        const cap = 'oldWorld|cap';
        final initial = Game(
          id: 'g_split_partial',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: cap,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Capital',
                  townTileKey: 'tk_cap',
                ),
              ],
              units: [
                Unit(
                  id: 'r1',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
                Unit(
                  id: 'r2',
                  type: 'musketeers',
                  ownerId: playerId,
                  locationProvinceId: cap,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [
              Army(
                id: 'home_army',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: cap,
                regimentUnitIds: const ['r1', 'r2'],
                isHomeArmy: true,
              ),
            ],
            nextArmySeq: 7,
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                cap: ['tk_cap'],
              },
            },
          ),
          players: [
            Player(
              id: playerId,
              displayName: 'Splitter',
              isHuman: true,
              capitalProvinceId: cap,
            ),
          ],
        );

        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 900,
                width: 480,
                child: _ArmySplitTestHarness(
                  initialGame: initial,
                  humanPlayerId: playerId,
                  bus: bus,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final homeTile = find.widgetWithText(ExpansionTile, 'Home Army').first;
        await tester.tap(homeTile);
        await tester.pumpAndSettle();

        final splitBtn = find.descendant(
          of: homeTile,
          matching: find.widgetWithText(CtNinePatchButton, 'Split'),
        ).first;
        await tester.ensureVisible(splitBtn);
        await tester.tap(splitBtn);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveOne('musketeers')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm Split'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('1 regiments · Capital'), findsNWidgets(2));

        await tester.tap(find.text('Home Army'));
        await tester.pumpAndSettle();
        expect(find.text('Musketeers: 1'), findsOneWidget);

        await tester.tap(find.text('Army army_7'));
        await tester.pumpAndSettle();
        expect(find.text('Musketeers: 1'), findsNWidgets(2));
      },
    );
  });
}
