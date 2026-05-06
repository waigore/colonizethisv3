// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        applyNavalSplitFleet,
        applyNavalTransferShipsBetweenFleets,
        homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

/// Mirrors shell handling of [NavalSplitFleetRequestedEvent] for widget tests.
StreamSubscription<NavalSplitFleetRequestedEvent> wireNavalSplitForWidgetTest({
  required AppEventBus bus,
  required Game Function() gameSnapshot,
}) {
  return bus.on<NavalSplitFleetRequestedEvent>().listen((e) {
    final next = applyNavalSplitFleet(
      game: gameSnapshot(),
      humanPlayerId: e.humanPlayerId,
      originalFleetId: e.originalFleetId,
      shipInstanceIdsToNewFleet: e.shipInstanceIdsToNewFleet,
    );
    bus.emit(NavalFleetsUpdatedEvent(game: next));
  });
}

/// Mirrors shell handling of [NavalTransferShipsRequestedEvent] for widget tests.
StreamSubscription<NavalTransferShipsRequestedEvent>
wireNavalTransferForWidgetTest({
  required AppEventBus bus,
  required Game Function() gameSnapshot,
}) {
  return bus.on<NavalTransferShipsRequestedEvent>().listen((e) {
    final next = applyNavalTransferShipsBetweenFleets(
      game: gameSnapshot(),
      humanPlayerId: e.humanPlayerId,
      sourceFleetId: e.sourceFleetId,
      targetFleetId: e.targetFleetId,
      shipInstanceIdsToTransfer: e.shipInstanceIdsToTransfer,
    );
    bus.emit(NavalFleetsUpdatedEvent(game: next));
  });
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Game game;
  late String humanPlayerIdWithFleets;
  const String humanPlayerIdWithNoFleets = 'no-such-player';

  // Fallback 1x1 transparent PNG if the real asset cannot be read.
  final ninePatchFallbackPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII=',
  );
  Uint8List ninePatchBytes = ninePatchFallbackPng;

  setUpAll(() async {
    final assetCandidates = <String>[
      'app/assets/images/ui_button_nine_patch.png',
      'assets/images/ui_button_nine_patch.png',
    ];
    for (final candidate in assetCandidates) {
      final file = File(candidate);
      if (await file.exists()) {
        ninePatchBytes = await file.readAsBytes();
        break;
      }
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = const StringCodec().decodeMessage(message);
          if (key == 'assets/images/ui_button_nine_patch.png') {
            return ByteData.view(ninePatchBytes.buffer);
          }
          return null;
        });

    // Preload panel nine-patch image into Flame cache so widget tests are
    // stable regardless of invocation directory.
    try {
      final bytes = await rootBundle.load(
        'assets/images/ui_button_nine_patch.png',
      );
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      Flame.images.add('ui_button_nine_patch.png', frame.image);
      Flame.images.add('assets/images/ui_button_nine_patch.png', frame.image);
    } catch (_) {
      // Keep tests resilient when asset prewarm fails; individual tests can
      // still validate behavior where possible.
    }

    game = getDebugInitGameResult().game;
    humanPlayerIdWithFleets = game.players.isNotEmpty
        ? game.players.first.id
        : 'gp1';
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  Widget buildPanel({
    required Game game,
    required String humanPlayerId,
    AppEventBus? bus,
    MapTopology topology = const MapTopology(),
    Orders draftOrders = const Orders(),
    String? locationScopeKey,
  }) {
    final resolvedBus = bus ?? AppEventBus.create();
    return MaterialApp(
      home: Scaffold(
        body: NavalUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          bus: resolvedBus,
          topology: topology,
          draftOrders: draftOrders,
          locationScopeKey: locationScopeKey,
        ),
      ),
    );
  }

  group('NavalUnitsPanel', () {
    testWidgets('AC: Beachhead mission appears in status line', (
      WidgetTester tester,
    ) async {
      const playerId = 'p_beach';
      final gameBeach = Game(
        id: 'beach_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(units: []),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'bf1',
              ownerId: playerId,
              regionId: 'oldWorld',
              seaZoneId: 'atlantic',
              shipTypeIds: const ['carrack'],
              mission: FleetMission.beachhead,
            ),
          ],
          portsByProvinceSeaboard: {
            'oldWorld|lisbon|atlantic': 'oldWorld|lisbon|0|0',
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: const [Player(id: playerId, displayName: 'P', isHuman: true)],
      );

      await tester.pumpWidget(
        buildPanel(game: gameBeach, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Beachhead'), findsWidgets);
    });

    testWidgets('AC: No fleets and no capital shows empty naval message', (
      WidgetTester tester,
    ) async {
      const playerId = 'p_empty';
      final emptyGame = Game(
        id: 'empty_naval',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [
          const Player(
            id: playerId,
            displayName: 'Solo',
            isHuman: true,
            treasury: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        buildPanel(game: emptyGame, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.text('No naval units'), findsOneWidget);
    });

    testWidgets(
      'AC: Marker-scoped capital port view shows Home Fleet and not empty state',
      (WidgetTester tester) async {
        const humanId = 'gp_marker_scope';
        const capitalPrefixedId = 'oldWorld|p1';
        final homeId = homeFleetIdFor(humanId);
        final markerScope = 'port:oldWorld|p1';

        final markerScopeGame = Game(
          id: 'g_marker_scope',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: capitalPrefixedId,
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: homeId,
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capitalPrefixedId,
                ships: const [
                  ShipInstance(id: 'home_ship_1', typeId: 'carrack'),
                ],
              ),
            ],
            tileKeysByRegionAndProvince: const {
              'oldWorld': {
                capitalPrefixedId: ['oldWorld|p1|0|0'],
              },
            },
          ),
          players: const [
            Player(
              id: humanId,
              displayName: 'Scope Test',
              isHuman: true,
              capitalProvinceId: capitalPrefixedId,
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: capitalPrefixedId,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(
            game: markerScopeGame,
            humanPlayerId: humanId,
            locationScopeKey: markerScope,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(ExpansionTile, 'Home Fleet'),
          findsOneWidget,
        );
        expect(find.text('No naval units'), findsNothing);
      },
    );

    testWidgets(
      'AC: Cross-region projected marker scope shows destination region rows',
      (WidgetTester tester) async {
        const humanId = 'gp_cross_region_scope';
        final scopedGame = Game(
          id: 'g_cross_region_scope',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 's1',
                ships: const [ShipInstance(id: 'ship_1', typeId: 'frigate')],
              ),
            ],
          ),
          players: const [
            Player(id: humanId, displayName: 'Cross Scope', isHuman: true),
          ],
        );
        const draftOrders = Orders(
          navalMoveOrdersByPlayerId: {
            humanId: [
              NavalMoveOrder(
                fleetId: 'f1',
                destinationSeaZoneId: 'newWorld|s2',
              ),
            ],
          },
        );
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|s1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'newWorld|s2',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'oldWorld|s1', id2: 'newWorld|s2')],
        );

        await tester.pumpWidget(
          buildPanel(
            game: scopedGame,
            humanPlayerId: humanId,
            topology: topology,
            draftOrders: draftOrders,
            locationScopeKey: 'sea:newWorld|s2',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('New World'), findsOneWidget);
        expect(find.text('Old World'), findsNothing);
        expect(find.textContaining('Fleet f1'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: Scoped panel auto-closes after confirmed move empties scope',
      (WidgetTester tester) async {
        const humanId = 'gp_scope_autoclose_yes';
        final bus = AppEventBus.create();
        final closeEvents = <ClosePanelEvent>[];
        final closeSub = bus.on<ClosePanelEvent>().listen(closeEvents.add);
        addTearDown(closeSub.cancel);

        final scopedGame = Game(
          id: 'g_scope_autoclose_yes',
          worldState: WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(),
            newWorld: RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 's1',
                ships: [ShipInstance(id: 'ship_1', typeId: 'frigate')],
              ),
            ],
          ),
          players: const [
            Player(id: humanId, displayName: 'Scoped AutoClose', isHuman: true),
          ],
        );
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|s1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'oldWorld|s2',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'oldWorld|s1', id2: 'oldWorld|s2')],
        );

        await tester.pumpWidget(
          _ScopedNavalPanelHarness(
            game: scopedGame,
            humanPlayerId: humanId,
            bus: bus,
            topology: topology,
            locationScopeKey: 'sea:oldWorld|s1',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Fleet f1'), findsOneWidget);

        bus.emit(
          NavalMoveFleetRequestedEvent(
            humanPlayerId: humanId,
            moveOrder: NavalMoveOrder(
              fleetId: 'f1',
              destinationSeaZoneId: 'oldWorld|s2',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(closeEvents.length, 1);
      },
    );

    testWidgets(
      'AC: Full-list mode move confirm does not emit scoped auto-close event',
      (WidgetTester tester) async {
        const humanId = 'gp_scope_autoclose_no_full';
        final bus = AppEventBus.create();
        final closeEvents = <ClosePanelEvent>[];
        final closeSub = bus.on<ClosePanelEvent>().listen(closeEvents.add);
        addTearDown(closeSub.cancel);

        final gameFull = Game(
          id: 'g_scope_autoclose_no_full',
          worldState: WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(),
            newWorld: RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 's1',
                ships: [ShipInstance(id: 'ship_1', typeId: 'frigate')],
              ),
            ],
          ),
          players: const [
            Player(id: humanId, displayName: 'Full List', isHuman: true),
          ],
        );
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|s1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'oldWorld|s2',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'oldWorld|s1', id2: 'oldWorld|s2')],
        );

        await tester.pumpWidget(
          _ScopedNavalPanelHarness(
            game: gameFull,
            humanPlayerId: humanId,
            bus: bus,
            topology: topology,
            locationScopeKey: null,
          ),
        );
        await tester.pumpAndSettle();

        bus.emit(
          NavalMoveFleetRequestedEvent(
            humanPlayerId: humanId,
            moveOrder: NavalMoveOrder(
              fleetId: 'f1',
              destinationSeaZoneId: 'oldWorld|s2',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(closeEvents, isEmpty);
      },
    );

    testWidgets(
      'AC: Scoped empty state without move confirm does not auto-close',
      (WidgetTester tester) async {
        const humanId = 'gp_scope_autoclose_no_external';
        final bus = AppEventBus.create();
        final closeEvents = <ClosePanelEvent>[];
        final closeSub = bus.on<ClosePanelEvent>().listen(closeEvents.add);
        addTearDown(closeSub.cancel);

        final gameScoped = Game(
          id: 'g_scope_autoclose_no_external',
          worldState: WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(),
            newWorld: RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 's1',
                ships: [ShipInstance(id: 'ship_1', typeId: 'frigate')],
              ),
            ],
          ),
          players: const [
            Player(id: humanId, displayName: 'Scoped External', isHuman: true),
          ],
        );

        await tester.pumpWidget(
          _ScopedNavalPanelHarness(
            game: gameScoped,
            humanPlayerId: humanId,
            bus: bus,
            topology: const MapTopology(),
            locationScopeKey: 'sea:oldWorld|s1',
            removeFleetOnNextFrame: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(closeEvents, isEmpty);
      },
    );

    testWidgets('AC: Home Fleet collapsed row does not show Move action', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_move_home';
      const capProvince = 'oldWorld|cap1';
      final homeId = homeFleetIdFor(humanId);

      final moveHomeGame = Game(
        id: 'g_move_home',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'cap1',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Capital',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: homeId,
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: capProvince,
              ships: const [ShipInstance(id: 'home_ship', typeId: 'carrack')],
            ),
          ],
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              capProvince: ['oldWorld|cap1|0|0'],
            },
          },
        ),
        players: const [
          Player(
            id: humanId,
            displayName: 'Move Home Test',
            isHuman: true,
            capitalProvinceId: capProvince,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: capProvince,
              x: 0,
              y: 0,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        buildPanel(game: moveHomeGame, humanPlayerId: humanId),
      );
      await tester.pumpAndSettle();

      final homeTile = find.widgetWithText(ExpansionTile, 'Home Fleet');
      expect(homeTile, findsOneWidget);

      expect(
        find.descendant(of: homeTile, matching: find.byTooltip('Move')),
        findsNothing,
      );
    });

    testWidgets(
      'AC: Non-home collapsed Move action opens MoveFleetDialog without expansion',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        final nonHomeFleets = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanId &&
                  f.shipTypeIds.isNotEmpty &&
                  f.id != homeFleetIdFor(humanId),
            )
            .toList();
        if (nonHomeFleets.isEmpty) return;
        final targetFleet = nonHomeFleets.first;

        await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
        await tester.pumpAndSettle();

        final fleetTile = find.widgetWithText(
          ExpansionTile,
          'Fleet ${targetFleet.id}',
        );
        expect(fleetTile, findsOneWidget);
        await tester.ensureVisible(fleetTile);

        final moveButton = find.descendant(
          of: fleetTile,
          matching: find.byTooltip('Move'),
        );
        expect(moveButton, findsOneWidget);
        await tester.ensureVisible(moveButton);
        await tester.tap(moveButton);
        await tester.pumpAndSettle();

        expect(find.byType(MoveFleetDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('AC: Narrow row switches inline actions to icon-only mode', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 800));

      final humanId = humanPlayerIdWithFleets;
      final nonHomeFleets = game.worldState.fleets
          .where(
            (f) =>
                f.ownerId == humanId &&
                f.shipTypeIds.isNotEmpty &&
                f.id != homeFleetIdFor(humanId),
          )
          .toList();
      if (nonHomeFleets.isEmpty) return;
      final targetFleet = nonHomeFleets.first;

      await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
      await tester.pumpAndSettle();

      final fleetTile = find.widgetWithText(
        ExpansionTile,
        'Fleet ${targetFleet.id}',
      );
      expect(fleetTile, findsOneWidget);

      expect(
        find.descendant(of: fleetTile, matching: find.byIcon(Icons.route)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: fleetTile, matching: find.byIcon(Icons.call_split)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: fleetTile, matching: find.text('Move')),
        findsNothing,
      );
    });

    testWidgets(
      'AC: Home Fleet is never deleted even when empty after combine',
      (WidgetTester tester) async {
        const humanId = 'gp_home_never_deleted';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);

        final homeNeverDeleteGame = Game(
          id: 'g_home_never_deleted',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: homeId,
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capProvince,
                ships: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
              ),
              Fleet(
                id: 'donor',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capProvince,
                ships: const [ShipInstance(id: 'ship_d', typeId: 'fluyte')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Home never deleted tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        final subTransferNeverDelete = wireNavalTransferForWidgetTest(
          bus: bus,
          gameSnapshot: () => homeNeverDeleteGame,
        );
        addTearDown(sub.cancel);
        addTearDown(subTransferNeverDelete.cancel);

        await tester.pumpWidget(
          buildPanel(
            game: homeNeverDeleteGame,
            humanPlayerId: humanId,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final homeFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        final donorFinder = find.widgetWithText(ExpansionTile, 'Fleet donor');
        expect(homeFinder, findsOneWidget);
        expect(donorFinder, findsOneWidget);

        await tester.tap(
          find.descendant(of: homeFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: donorFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(CtNinePatchButton, 'Combine'));
        await tester.pumpAndSettle();
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
        await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('fluyte')));
        await tester.pumpAndSettle();
        final confirmTransfer = find.widgetWithText(
          CtNinePatchButton,
          'Confirm Transfer',
        );
        expect(confirmTransfer, findsOneWidget);
        expect(
          tester.widget<CtNinePatchButton>(confirmTransfer).enabled,
          isTrue,
        );
        final confirmTransferButton = tester.widget<CtNinePatchButton>(
          confirmTransfer,
        );
        expect(confirmTransferButton.onPressed, isNotNull);
        confirmTransferButton.onPressed!.call();
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        final homeFleet = fleetsAfter.where((f) => f.id == homeId);
        expect(homeFleet, isNotEmpty);
        final shipIds = homeFleet.first.ships.map((s) => s.id).toList()..sort();
        expect(shipIds, ['ship_d', 'ship_h']);
        expect(fleetsAfter.any((f) => f.id == 'donor'), isFalse);
      },
    );

    testWidgets(
      'AC: Non-Home fleet split cannot empty original (Confirm Split disabled)',
      (WidgetTester tester) async {
        const humanId = 'gp_nonhome_removed';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);

        final nonHomeSplitGame = Game(
          id: 'g_nonhome_removed',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'cap1',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Capital',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: homeId,
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capProvince,
                ships: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
              ),
              Fleet(
                id: 'split_me',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: capProvince,
                ships: const [ShipInstance(id: 'ship_s1', typeId: 'fluyte')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Non-home removed tester',
              isHuman: true,
              capitalProvinceId: capProvince,
              capitalTile: const CapitalTile(
                regionId: 'oldWorld',
                provinceId: capProvince,
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final bus = AppEventBus.create();
        NavalFleetsUpdatedEvent? updated;
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          updated = e;
        });
        final subSplit = wireNavalSplitForWidgetTest(
          bus: bus,
          gameSnapshot: () => nonHomeSplitGame,
        );
        addTearDown(sub.cancel);
        addTearDown(subSplit.cancel);

        await tester.pumpWidget(
          buildPanel(game: nonHomeSplitGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final fleetFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet split_me',
        );
        expect(fleetFinder, findsOneWidget);

        await tester.ensureVisible(fleetFinder);
        await tester.tap(fleetFinder);
        await tester.pumpAndSettle();

        final splitButton = find.descendant(
          of: fleetFinder,
          matching: find.byTooltip('Split'),
        );
        expect(splitButton, findsOneWidget);
        await tester.ensureVisible(splitButton);
        await tester.pumpAndSettle();
        await tester.tap(splitButton);
        await tester.pumpAndSettle();

        final fleet = nonHomeSplitGame.worldState.fleets.firstWhere(
          (f) => f.id == 'split_me',
        );
        expect(fleet.ships.length, 1);

        await tester.tap(
          find.byKey(CtTransferListKeys.leftMoveOne(fleet.ships.first.typeId)),
        );
        await tester.pumpAndSettle();

        final confirmBtn = tester.widget<CtNinePatchButton>(
          find.widgetWithText(CtNinePatchButton, 'Confirm Split'),
        );
        expect(confirmBtn.enabled, isFalse);
        expect(updated, isNull);
      },
    );
  });
}

class _ScopedNavalPanelHarness extends StatefulWidget {
  const _ScopedNavalPanelHarness({
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    required this.locationScopeKey,
    this.removeFleetOnNextFrame = false,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final MapTopology topology;
  final String? locationScopeKey;
  final bool removeFleetOnNextFrame;

  @override
  State<_ScopedNavalPanelHarness> createState() =>
      _ScopedNavalPanelHarnessState();
}

class _ScopedNavalPanelHarnessState extends State<_ScopedNavalPanelHarness> {
  late Orders _draftOrders;
  late Game _game;
  StreamSubscription<NavalMoveFleetRequestedEvent>? _moveSub;

  @override
  void initState() {
    super.initState();
    _draftOrders = const Orders();
    _game = widget.game;
    _moveSub = widget.bus.on<NavalMoveFleetRequestedEvent>().listen((event) {
      if (!mounted) return;
      setState(() {
        _draftOrders = Orders(
          navalMoveOrdersByPlayerId: {
            event.humanPlayerId: [
              NavalMoveOrder(
                fleetId: event.moveOrder.fleetId,
                destinationSeaZoneId: event.moveOrder.destinationSeaZoneId,
                destinationPortProvinceId:
                    event.moveOrder.destinationPortProvinceId,
              ),
            ],
          },
        );
      });
    });
    if (widget.removeFleetOnNextFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _game = _game.copyWith(
            worldState: _game.worldState.copyWith(fleets: const []),
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _moveSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: NavalUnitsPanel(
          game: _game,
          humanPlayerId: widget.humanPlayerId,
          bus: widget.bus,
          topology: widget.topology,
          draftOrders: _draftOrders,
          locationScopeKey: widget.locationScopeKey,
        ),
      ),
    );
  }
}
