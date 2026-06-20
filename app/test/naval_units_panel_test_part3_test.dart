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
import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
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
    testWidgets(
      'AC: Home Fleet transfer moves selected ships and keeps source when ships remain',
      (WidgetTester tester) async {
        const humanId = 'gp_home_transfer_apply';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);

        var gameState = Game(
          id: 'g_home_transfer_apply',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
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
                ships: const [ShipInstance(id: 'home_1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'sea_source',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_alpha',
                ships: const [
                  ShipInstance(id: 'src_1', typeId: 'fluyte'),
                  ShipInstance(id: 'src_2', typeId: 'carrack'),
                ],
              ),
            ],
          ),
          players: const [
            Player(
              id: humanId,
              displayName: 'Home transfer tester',
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
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|cap1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'zone_alpha',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'oldWorld|cap1', id2: 'zone_alpha')],
        );
        final bus = AppEventBus.create();
        final subTransfer = wireNavalTransferForWidgetTest(
          bus: bus,
          gameSnapshot: () => gameState,
        );
        final subUpdated = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          gameState = e.game;
        });
        addTearDown(subTransfer.cancel);
        addTearDown(subUpdated.cancel);

        await tester.pumpWidget(
          buildPanel(
            game: gameState,
            humanPlayerId: humanId,
            topology: topology,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final homeFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        final sourceFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet sea_source',
        );
        await tester.tap(
          find.descendant(of: homeFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: sourceFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();

        final moveOneFluyte = find.byKey(
          CtTransferListKeys.leftMoveOne('fluyte'),
        );
        expect(moveOneFluyte, findsOneWidget);
        await tester.tap(moveOneFluyte);
        await tester.pumpAndSettle();

        final confirmTransfer = find.widgetWithText(
          CtNinePatchButton,
          'Transfer',
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

        final homeFleet = gameState.worldState.fleets.firstWhere(
          (f) => f.id == homeId,
        );
        final sourceFleet = gameState.worldState.fleets.firstWhere(
          (f) => f.id == 'sea_source',
        );
        final homeShipIds = homeFleet.ships.map((s) => s.id).toSet();
        final sourceShipIds = sourceFleet.ships.map((s) => s.id).toSet();
        expect(homeShipIds.contains('src_1'), isTrue);
        expect(sourceShipIds.contains('src_1'), isFalse);
        expect(sourceShipIds.contains('src_2'), isTrue);
      },
    );

    testWidgets(
      'AC: Home Fleet and non-adjacent sea source keep Combine disabled',
      (WidgetTester tester) async {
        const humanId = 'gp_home_non_adjacent';
        const capProvince = 'oldWorld|cap1';
        final homeId = homeFleetIdFor(humanId);

        final gameNonAdjacent = Game(
          id: 'g_home_non_adjacent_transfer',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
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
                ships: const [ShipInstance(id: 'home_1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'sea_far',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_far',
                ships: const [ShipInstance(id: 'src_1', typeId: 'fluyte')],
              ),
            ],
          ),
          players: const [
            Player(
              id: humanId,
              displayName: 'Home non-adjacent tester',
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
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|cap1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'zone_far',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [],
        );

        await tester.pumpWidget(
          buildPanel(
            game: gameNonAdjacent,
            humanPlayerId: humanId,
            topology: topology,
          ),
        );
        await tester.pumpAndSettle();

        final homeFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        final sourceFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet sea_far',
        );
        await tester.tap(
          find.descendant(of: homeFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: sourceFinder, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isFalse);
      },
    );

    testWidgets(
      'AC: Two fleets in the same sea zone combine; mission becomes none',
      (WidgetTester tester) async {
        const humanId = 'gp_same_sea_combine';
        const capProvince = 'oldWorld|cap1';

        final sameSeaGame = Game(
          id: 'g_same_sea_combine',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'coast',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Coast',
                ),
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
                id: 'sea_1',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_alpha',
                inPortAtProvinceId: null,
                ships: const [ShipInstance(id: 'ss1', typeId: 'carrack')],
                mission: FleetMission.patrol,
              ),
              Fleet(
                id: 'sea_2',
                ownerId: humanId,
                regionId: 'oldWorld',
                seaZoneId: 'zone_alpha',
                inPortAtProvinceId: null,
                ships: const [ShipInstance(id: 'ss2', typeId: 'fluyte')],
              ),
            ],
            portsByProvinceSeaboard: {
              'oldWorld|coast|zone_alpha': 'oldWorld|coast|0|0',
            },
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
                'oldWorld|coast': ['oldWorld|coast|0|0'],
              },
            },
            nextShipInstanceSeq: 3,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Same-sea combine',
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
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(game: sameSeaGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final finder1 = find.widgetWithText(ExpansionTile, 'Fleet sea_1');
        final finder2 = find.widgetWithText(ExpansionTile, 'Fleet sea_2');
        expect(finder1, findsOneWidget);
        expect(finder2, findsOneWidget);

        await tester.tap(
          find.descendant(of: finder1, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: finder2, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isTrue);

        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.length, 1);
        final survivor = fleetsAfter.single;
        expect(survivor.id, 'sea_1');
        final shipIds = survivor.ships.map((s) => s.id).toList()..sort();
        expect(shipIds, ['ss1', 'ss2']);
        expect(survivor.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Combining two non-home fleets clears non-none missions on survivor',
      (WidgetTester tester) async {
        const humanId = 'gp_mission_clear';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final missionGame = Game(
          id: 'g_mission_clear',
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
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'm1',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ms1', typeId: 'carrack')],
                mission: FleetMission.patrol,
              ),
              Fleet(
                id: 'm2',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ms2', typeId: 'fluyte')],
                mission: FleetMission.blockade,
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
              displayName: 'Mission clear tester',
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
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(game: missionGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final t1 = find.widgetWithText(ExpansionTile, 'Fleet m1');
        final t2 = find.widgetWithText(ExpansionTile, 'Fleet m2');
        await tester.tap(
          find.descendant(of: t1, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: t2, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final merged = updated!.game.worldState.fleets.firstWhere(
          (f) => f.id == 'm1',
        );
        expect(merged.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Partial row selection shows indeterminate header; header tap selects all',
      (WidgetTester tester) async {
        const humanId = 'gp_partial_header';
        const mergePort = 'oldWorld|mergeport';

        // No capital => no synthetic Home Fleet row; select-all stays one locality.
        final partialGame = Game(
          id: 'g_partial_header',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'p1',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ps1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'p2',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ps2', typeId: 'fluyte')],
              ),
              Fleet(
                id: 'p3',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'ps3', typeId: 'carrack')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                mergePort: ['oldWorld|mergeport|0|0'],
              },
            },
            nextShipInstanceSeq: 4,
          ),
          players: const [
            Player(
              id: humanId,
              displayName: 'Partial header tester',
              isHuman: true,
              treasury: 0,
            ),
          ],
        );

        await tester.pumpWidget(
          buildPanel(game: partialGame, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final headerCheckboxFinder = find.descendant(
          of: find.byType(NavalUnitsPanel),
          matching: find.byWidgetPredicate(
            (w) => w is Checkbox && w.tristate == true,
          ),
        );

        final tile1 = find.widgetWithText(ExpansionTile, 'Fleet p1');
        await tester.tap(
          find.descendant(of: tile1, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        expect(tester.widget<Checkbox>(headerCheckboxFinder).value, isNull);

        await tester.tap(headerCheckboxFinder);
        await tester.pumpAndSettle();

        expect(tester.widget<Checkbox>(headerCheckboxFinder).value, isTrue);
        for (final label in ['Fleet p1', 'Fleet p2', 'Fleet p3']) {
          final tile = find.widgetWithText(ExpansionTile, label);
          expect(tile, findsOneWidget);
          final cb = find.descendant(of: tile, matching: find.byType(Checkbox));
          await tester.ensureVisible(cb);
          expect(tester.widget<Checkbox>(cb).value, isTrue);
        }

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isTrue);
      },
    );

    testWidgets(
      'AC: Three-fleet combine survivor is first in panel order regardless of check order',
      (WidgetTester tester) async {
        const humanId = 'gp_reverse_check';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final revGame = Game(
          id: 'g_reverse_check',
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
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'r1',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'rs1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'r2',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'rs2', typeId: 'fluyte')],
              ),
              Fleet(
                id: 'r3',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'rs3', typeId: 'carrack')],
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                capProvince: ['oldWorld|cap1|0|0'],
              },
            },
            nextShipInstanceSeq: 4,
          ),
          players: [
            Player(
              id: humanId,
              displayName: 'Reverse check tester',
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
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(game: revGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        for (final label in ['Fleet r3', 'Fleet r2', 'Fleet r1']) {
          final titleFinder = find.text(label);
          await tester.scrollUntilVisible(titleFinder, 120);
          await tester.pumpAndSettle();
          final tile = find.ancestor(
            of: titleFinder,
            matching: find.byType(ExpansionTile),
          );
          final cb = find.descendant(of: tile, matching: find.byType(Checkbox));
          await tester.scrollUntilVisible(cb, 120);
          await tester.pumpAndSettle();
          await tester.ensureVisible(cb);
          await tester.tap(cb);
          await tester.pumpAndSettle();
        }

        final combineFinder = find.widgetWithText(
          CtActionTextButton,
          'Combine',
        );
        await tester.scrollUntilVisible(combineFinder, 120);
        await tester.pumpAndSettle();
        await tester.tap(combineFinder);
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.length, 1);
        final survivor = fleetsAfter.single;
        expect(survivor.id, 'r1');
        expect(survivor.ships.map((s) => s.id).toList(), ['rs1', 'rs2', 'rs3']);
      },
    );

    testWidgets(
      'AC: Updating game prunes combine selection to fleets that still exist',
      (WidgetTester tester) async {
        const humanId = 'gp_prune_sel';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        WorldState stateWithTwo(String keep, String drop) => WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'cap1',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Capital',
              ),
              Province(
                id: 'mergeport',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Merge Port',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: keep,
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ks1', typeId: 'carrack')],
            ),
            Fleet(
              id: drop,
              ownerId: humanId,
              regionId: 'oldWorld',
              inPortAtProvinceId: mergePort,
              ships: const [ShipInstance(id: 'ks2', typeId: 'fluyte')],
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              capProvince: ['oldWorld|cap1|0|0'],
            },
          },
          nextShipInstanceSeq: 3,
        );

        final gameTwo = Game(
          id: 'g_prune_two',
          worldState: stateWithTwo('stays', 'removed'),
          players: [
            Player(
              id: humanId,
              displayName: 'Prune tester',
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

        final gameOne = Game(
          id: 'g_prune_one',
          worldState: gameTwo.worldState.copyWith(
            fleets: [
              gameTwo.worldState.fleets.firstWhere((f) => f.id == 'stays'),
            ],
          ),
          players: gameTwo.players,
        );

        await tester.pumpWidget(
          buildPanel(game: gameTwo, humanPlayerId: humanId),
        );
        await tester.pumpAndSettle();

        final tileStays = find.widgetWithText(ExpansionTile, 'Fleet stays');
        final tileRemoved = find.widgetWithText(ExpansionTile, 'Fleet removed');
        await tester.tap(
          find.descendant(of: tileStays, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: tileRemoved, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          buildPanel(game: gameOne, humanPlayerId: humanId),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final staysCb = find.descendant(
          of: tileStays,
          matching: find.byType(Checkbox),
        );
        final removedFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet removed',
        );
        expect(removedFinder, findsNothing);
        expect(tester.widget<Checkbox>(staysCb).value, isTrue);

        final combineBtn = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        );
        expect(combineBtn.enabled, isFalse);
      },
    );

    testWidgets(
      'AC: Collapsed rows keep inline Split action while checkbox selection works',
      (WidgetTester tester) async {
        const humanId = 'gp_collapsed_cb';
        const capProvince = 'oldWorld|cap1';
        const mergePort = 'oldWorld|mergeport';

        final collapsedGame = Game(
          id: 'g_collapsed_cb',
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
                Province(
                  id: 'mergeport',
                  regionId: 'oldWorld',
                  ownerId: humanId,
                  displayName: 'Merge Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'col_a',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'cs1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'col_b',
                ownerId: humanId,
                regionId: 'oldWorld',
                inPortAtProvinceId: mergePort,
                ships: const [ShipInstance(id: 'cs2', typeId: 'fluyte')],
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
              displayName: 'Collapsed cb tester',
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
        addTearDown(sub.cancel);

        await tester.pumpWidget(
          buildPanel(game: collapsedGame, humanPlayerId: humanId, bus: bus),
        );
        await tester.pumpAndSettle();

        final tileA = find.widgetWithText(ExpansionTile, 'Fleet col_a');
        final tileB = find.widgetWithText(ExpansionTile, 'Fleet col_b');

        expect(
          find.descendant(of: tileA, matching: find.byTooltip('Split')),
          findsOne,
        );
        expect(
          find.descendant(of: tileB, matching: find.byTooltip('Split')),
          findsOne,
        );

        await tester.tap(
          find.descendant(of: tileA, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: tileB, matching: find.byType(Checkbox)),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(of: tileA, matching: find.byTooltip('Split')),
          findsOne,
        );

        await tester.tap(find.widgetWithText(CtActionTextButton, 'Combine'));
        await tester.pumpAndSettle();

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        final merged = fleetsAfter.firstWhere((f) => f.id == 'col_a');
        final mergedIds = merged.ships.map((s) => s.id).toList()..sort();
        expect(mergedIds, ['cs1', 'cs2']);
      },
    );
  });
}
